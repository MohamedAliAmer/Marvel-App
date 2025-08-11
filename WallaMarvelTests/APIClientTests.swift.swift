import XCTest
import CryptoKit
@testable import WallaMarvel

final class APIClientTests: XCTestCase {

    // MARK: - URLProtocol Stub

    final class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (Int, Data))?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = MockURLProtocol.requestHandler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            do {
                let (status, data) = try handler(request)
                let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    // MARK: - Stubs

    struct TestAPIConfiguration: APIConfiguration {
        let publicKey: String = "pub"
        let privateKey: String = "priv"
    }

    struct TestTimestampProvider: TimestampProvider {
        let fixed: String
        func now() -> String { fixed }
    }

    final class NoopLogger: LoggerProtocol {
        func debug(_ message: String, metadata: [String : String]?) {}
        func info(_ message: String, metadata: [String : String]?) {}
        func warning(_ message: String, metadata: [String : String]?) {}
        func error(_ message: String, error: Error?, metadata: [String : String]?) {}
    }

    // MARK: - Helpers

    func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func sampleListJSON(ids: [Int], offset: Int, limit: Int, total: Int) -> Data {
        let results: [[String: Any]] = ids.map { id in
            [
                "id": id,
                "name": "Hero \(id)",
                "description": "",
                "thumbnail": ["path": "https://example.com/img\(id)", "extension": "jpg"],
                "comics": ["available": 0, "items": []],
                "series": ["available": 0, "items": []],
                "stories": ["available": 0, "items": []],
                "events": ["available": 0, "items": []]
            ]
        }
        let payload: [String: Any] = [
            "data": [
                "count": results.count,
                "limit": limit,
                "offset": offset,
                "total": total,
                "results": results
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: payload, options: [])
    }

    func md5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Tests

    func testGetHeroesBuildsAuthAndPagingQuery() async throws {
        let ts = "123"
        let expectedHash = md5("\(ts)privpub")
        let session = makeSession()
        let client = APIClient(cfg: TestAPIConfiguration(),
                               session: session,
                               tsProvider: TestTimestampProvider(fixed: ts),
                               logger: NoopLogger())

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                XCTFail("Bad URL"); throw URLError(.badURL)
            }
            let qi = components.queryItems ?? []
            let map = Dictionary(uniqueKeysWithValues: qi.map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(map["apikey"], "pub")
            XCTAssertEqual(map["ts"], ts)
            XCTAssertEqual(map["hash"], expectedHash)
            XCTAssertEqual(map["offset"], "0")
            XCTAssertEqual(map["limit"], "20")
            XCTAssertNil(map["nameStartsWith"]) // not provided
            return (200, self.sampleListJSON(ids: [1,2], offset: 0, limit: 20, total: 2))
        }

        _ = try await client.getHeroes(offset: 0, limit: 20, nameStartsWith: nil)
    }

    func testGetHeroesIncludesNameStartsWithWhenProvided() async throws {
        let ts = "999"
        let session = makeSession()
        let client = APIClient(cfg: TestAPIConfiguration(),
                               session: session,
                               tsProvider: TestTimestampProvider(fixed: ts),
                               logger: NoopLogger())

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                XCTFail("Bad URL"); throw URLError(.badURL)
            }
            let qi = components.queryItems ?? []
            let map = Dictionary(uniqueKeysWithValues: qi.map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(map["nameStartsWith"], "spi")
            return (200, self.sampleListJSON(ids: [1], offset: 0, limit: 1, total: 1))
        }

        _ = try await client.getHeroes(offset: 0, limit: 1, nameStartsWith: "spi")
    }

    func testGetHeroDetailsRawDecodes() async throws {
        let ts = "111"
        let session = makeSession()
        let client = APIClient(cfg: TestAPIConfiguration(),
                               session: session,
                               tsProvider: TestTimestampProvider(fixed: ts),
                               logger: NoopLogger())

        MockURLProtocol.requestHandler = { request in
            // Return a single hero in the container
            return (200, self.sampleListJSON(ids: [42], offset: 0, limit: 1, total: 1))
        }

        let container = try await client.getHeroDetailsRaw(heroId: 42)
        XCTAssertEqual(container.data.results.first?.id, 42)
    }
}
