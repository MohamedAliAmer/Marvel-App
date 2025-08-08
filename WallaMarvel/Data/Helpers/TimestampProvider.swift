import Foundation

protocol TimestampProvider {
    func now() -> String
}

struct DefaultTimestampProvider: TimestampProvider {
    func now() -> String { String(Int(Date().timeIntervalSince1970)) }
}
