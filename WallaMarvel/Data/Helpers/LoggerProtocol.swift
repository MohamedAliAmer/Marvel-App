import Foundation

enum LogLevel: String { case debug, info, warning, error }

protocol LoggingServiceProvider {
    func send(level: LogLevel, message: String, metadata: [String: String]?)
}

protocol LoggerProtocol {
    func debug(_ message: String, metadata: [String: String]?)
    func info(_ message: String, metadata: [String: String]?)
    func warning(_ message: String, metadata: [String: String]?)
    func error(_ message: String, error: Error?, metadata: [String: String]?)
}

protocol AppInfoProviderProtocol {
    var appVersion: String { get }
    var appBuild: String { get }
    var bundleID: String { get }
}

struct DefaultAppInfoProvider: AppInfoProviderProtocol {
    var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    var appBuild: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "" }
    var bundleID: String { Bundle.main.bundleIdentifier ?? "" }
}

/// A generic, injectable logger that forwards to a service provider
final class DefaultLogger: LoggerProtocol {
    private let service: LoggingServiceProvider
    private let appInfo: AppInfoProviderProtocol

    init(service: LoggingServiceProvider, appInfo: AppInfoProviderProtocol = DefaultAppInfoProvider()) {
        self.service = service
        self.appInfo = appInfo
    }

    func debug(_ message: String, metadata: [String : String]? = nil) {
        forward(.debug, message: message, metadata: metadata)
    }

    func info(_ message: String, metadata: [String : String]? = nil) {
        forward(.info, message: message, metadata: metadata)
    }

    func warning(_ message: String, metadata: [String : String]? = nil) {
        forward(.warning, message: message, metadata: metadata)
    }

    func error(_ message: String, error: Error? = nil, metadata: [String : String]? = nil) {
        var md = metadata ?? [:]
        if let error = error { md["error"] = String(describing: error) }
        forward(.error, message: message, metadata: md)
    }

    private func forward(_ level: LogLevel, message: String, metadata: [String: String]?) {
        var md = metadata ?? [:]
        md["app_version"] = appInfo.appVersion
        md["app_build"] = appInfo.appBuild
        md["bundle_id"] = appInfo.bundleID
        service.send(level: level, message: message, metadata: md)
    }
}

/// Default provider that prints to the console (placeholder for a real service like Sentry, Datadog, etc.)
final class PrintLoggingServiceProvider: LoggingServiceProvider {
    func send(level: LogLevel, message: String, metadata: [String : String]?) {
        #if DEBUG
        print("[LOG] \(level.rawValue) — \(message) \(metadata ?? [:])")
        #endif
    }
}
