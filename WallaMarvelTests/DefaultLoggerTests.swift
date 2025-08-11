import XCTest
import FactoryKit
@testable import WallaMarvel

final class DefaultLoggerTests: XCTestCase {

    // MARK: - Doubles

    final class SpyLoggingServiceProvider: LoggingServiceProvider {
        struct Event { let level: LogLevel, message: String, metadata: [String:String]? }
        private(set) var events: [Event] = []
        func send(level: LogLevel, message: String, metadata: [String : String]?) {
            events.append(.init(level: level, message: message, metadata: metadata))
        }
    }

    struct StubAppInfoProvider: AppInfoProviderProtocol {
        var appVersion: String = "1.2.3"
        var appBuild: String = "45"
        var bundleID: String = "com.example.app"
    }

    // MARK: - Tests

    // MARK: - DI Registrations

    override func setUp() {
        super.setUp()
        Container.shared.logger.register {
            DefaultLogger(
                service: SpyLoggingServiceProvider(),
                appInfo: StubAppInfoProvider()
            )
        }
    }

    override func tearDown() {
        Container.shared.logger.reset()
        super.tearDown()
    }

    func testAddsAppInfoAndForwardsMessage() {
        let spy = SpyLoggingServiceProvider()
        let stubInfo = StubAppInfoProvider()
        let logger = DefaultLogger(service: spy, appInfo: stubInfo)

        logger.debug("hello", metadata: ["k":"v"])
        logger.info("world", metadata: nil)
        logger.warning("careful", metadata: [:])

        XCTAssertEqual(spy.events.count, 3)
        XCTAssertEqual(spy.events[0].level, .debug)
        XCTAssertEqual(spy.events[0].message, "hello")
        XCTAssertEqual(spy.events[1].level, .info)
        XCTAssertEqual(spy.events[1].message, "world")
        XCTAssertEqual(spy.events[2].level, .warning)
        XCTAssertEqual(spy.events[2].message, "careful")

        for event in spy.events {
            let md = event.metadata ?? [:]
            XCTAssertEqual(md["app_version"], "1.2.3")
            XCTAssertEqual(md["app_build"], "45")
            XCTAssertEqual(md["bundle_id"], "com.example.app")
        }
        XCTAssertEqual(spy.events[0].metadata?["k"], "v")
    }

    func testErrorAppendsErrorStringAndMetadata() {
        enum Boom: Error { case kaboom }
        let spy = SpyLoggingServiceProvider()
        let stubInfo = StubAppInfoProvider()
        let logger = DefaultLogger(service: spy, appInfo: stubInfo)

        logger.error("failed", error: Boom.kaboom, metadata: ["ctx":"login"])

        XCTAssertEqual(spy.events.count, 1)
        let event = spy.events[0]
        XCTAssertEqual(event.level, .error)
        XCTAssertEqual(event.message, "failed")

        let md = event.metadata ?? [:]
        XCTAssertEqual(md["ctx"], "login")
        XCTAssertNotNil(md["error"])
        XCTAssertEqual(md["app_version"], "1.2.3")
        XCTAssertEqual(md["app_build"], "45")
        XCTAssertEqual(md["bundle_id"], "com.example.app")
    }
}
