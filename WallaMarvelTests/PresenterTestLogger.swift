import Foundation
@testable import WallaMarvel

final class PresenterTestLogger: LoggerProtocol {
    struct Entry { let level: LogLevel, message: String, metadata: [String:String]? }
    private(set) var entries: [Entry] = []
    func debug(_ m: String, metadata: [String:String]?) { entries.append(.init(level: .debug, message: m, metadata: metadata)) }
    func info(_ m: String, metadata: [String:String]?)  { entries.append(.init(level: .info,  message: m, metadata: metadata)) }
    func warning(_ m: String, metadata: [String:String]?) { entries.append(.init(level: .warning, message: m, metadata: metadata)) }
    func error(_ m: String, error: Error?, metadata: [String:String]?) {
        var md = metadata ?? [:]; if let e = error { md["error"] = String(describing: e) }
        entries.append(.init(level: .error, message: m, metadata: md))
    }
}
