import Foundation

protocol APIClientProtocol {
    func getHeroes(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer
    func getHeroDetailsRaw(heroId: Int) async throws -> CharacterDataContainer
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidKeys
    case decodingError
    case transport(Error)
    case serverStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidKeys: return "Missing or invalid API keys"
        case .decodingError: return "Decoding failed"
        case .transport(let e): return e.localizedDescription
        case .serverStatus(let c): return "Server returned status \(c)"
        }
    }
}

final class APIClient: APIClientProtocol {
    private let baseURL = URL(string: "https://gateway.marvel.com/v1/public")!
    private let cfg: APIConfiguration
    private let session: URLSession
    private let tsProvider: TimestampProvider
    private let logger: LoggerProtocol

    init(cfg: APIConfiguration,
         session: URLSession = .shared,
         tsProvider: TimestampProvider = DefaultTimestampProvider(),
         logger: LoggerProtocol) {
        self.cfg = cfg
        self.session = session
        self.tsProvider = tsProvider
        self.logger = logger
    }

    private func authQueryItems() throws -> [URLQueryItem] {
        guard !cfg.publicKey.isEmpty, !cfg.privateKey.isEmpty else { throw APIError.invalidKeys }
        let ts = tsProvider.now()
        let hash = "\(ts)\(cfg.privateKey)\(cfg.publicKey)".md5
        return [
            URLQueryItem(name: "apikey", value: cfg.publicKey),
            URLQueryItem(name: "ts", value: ts),
            URLQueryItem(name: "hash", value: hash)
        ]
    }

    private func request(path: String, query: [URLQueryItem]) throws -> URLRequest {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        comps?.queryItems = try authQueryItems() + query
        guard let url = comps?.url else { throw APIError.invalidURL }
        return URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        var attempt = 0
        let maxAttempts = 3
        let decoder = JSONDecoder()

        while true {
            do {
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    // Retry on 5xx
                    if (500...599).contains(http.statusCode), attempt < (maxAttempts - 1) {
                        attempt += 1
                        let delay = pow(2.0, Double(attempt)) * 0.3 // 0.6s, 1.2s
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    self.logger.error("HTTP status not OK",
                                      error: nil,
                                      metadata: [
                                        "status": String(http.statusCode),
                                        "url": request.url?.absoluteString ?? "",
                                        "attempt": String(attempt + 1)
                                      ])
                    throw APIError.serverStatus(http.statusCode)
                }
                return try decoder.decode(T.self, from: data)
            } catch let urlError as URLError {
                if urlError.isTransient && attempt < (maxAttempts - 1) {
                    attempt += 1
                    let delay = pow(2.0, Double(attempt)) * 0.3
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                self.logger.error("Transport error",
                                  error: urlError,
                                  metadata: [
                                    "url": request.url?.absoluteString ?? "",
                                    "attempt": String(attempt + 1)
                                  ])
                throw APIError.transport(urlError)
            } catch let decodingError as DecodingError {
                self.logger.error("Decoding error",
                                  error: decodingError,
                                  metadata: [
                                    "url": request.url?.absoluteString ?? "",
                                    "attempt": String(attempt + 1)
                                  ])
                throw APIError.decodingError
            } catch {
                self.logger.error("Unknown transport error",
                                  error: error,
                                  metadata: [
                                    "url": request.url?.absoluteString ?? "",
                                    "attempt": String(attempt + 1)
                                  ])
                throw APIError.transport(error)
            }
        }
    }

    func getHeroes(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let q = nameStartsWith, !q.isEmpty {
            items.append(URLQueryItem(name: "nameStartsWith", value: q))
        }
        let req = try request(path: "characters", query: items)
        return try await execute(req)
    }

    func getHeroDetailsRaw(heroId: Int) async throws -> CharacterDataContainer {
        let req = try request(path: "characters/\(heroId)", query: [])
        return try await execute(req)
    }
}

private extension URLError {
    var isTransient: Bool {
        switch self.code {
        case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
             .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable,
             .requestBodyStreamExhausted, .backgroundSessionWasDisconnected:
            return true
        default:
            return false
        }
    }
}
