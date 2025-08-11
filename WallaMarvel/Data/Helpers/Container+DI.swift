import Foundation
import FactoryKit

/// Dependency injection container using FactoryKit for clean architecture
extension Container {
    // MARK: - Core Services
    
    /// App information provider for logging context  
    var appInfoProvider: Factory<AppInfoProviderProtocol> {
        self { DefaultAppInfoProvider() }.singleton
    }
    
    /// Logging service provider (console-based for now)
    var loggingServiceProvider: Factory<LoggingServiceProvider> {
        self { PrintLoggingServiceProvider() }.singleton
    }
    
    /// Main logger with app context
    var logger: Factory<LoggerProtocol> {
        self { DefaultLogger(service: self.loggingServiceProvider(),
                             appInfo: self.appInfoProvider()) }.singleton
    }

    // MARK: - API Configuration
    
    /// Marvel API configuration from Info.plist
    var apiConfiguration: Factory<APIConfiguration> {
        self { InfoPlistAPIConfiguration() }.singleton
    }
    
    /// URL session for networking
    var urlSession: Factory<URLSession> {
        self { URLSession.shared }.singleton
    }
    
    /// Timestamp provider for API authentication
    var timestampProvider: Factory<TimestampProvider> {
        self { DefaultTimestampProvider() }.singleton
    }

    // MARK: - Data Layer
    
    /// Internal API client factory
    private var apiClientImpl: Factory<APIClient> {
        self {
            APIClient(
                cfg: self.apiConfiguration(),
                session: self.urlSession(),
                tsProvider: self.timestampProvider(),
                logger: self.logger()
            )
        }
        .singleton
    }

    /// API client interface
    var apiClient: Factory<APIClientProtocol> {
        self { self.apiClientImpl() }
    }

    // MARK: - Domain Layer
    
    /// Heroes use case - delegates to API client
    var getHeroesUseCase: Factory<GetHeroesUseCaseProtocol> {
        self { self.apiClientImpl() }
    }

    // MARK: - Presentation Layer
    
    /// List heroes presenter with dependencies
    var listHeroesPresenter: Factory<ListHeroesPresenterProtocol> {
        self { ListHeroesPresenter(useCase: self.getHeroesUseCase(), logger: self.logger()) }
    }
}

// MARK: - Testing Support

#if DEBUG
extension Container {
    /// Override dependencies with mocks for testing
    func useMocks(
        getHeroesUseCase: GetHeroesUseCaseProtocol? = nil,
        apiClient: APIClientProtocol? = nil,
        logger: LoggerProtocol? = nil,
        urlSession: URLSession? = nil,
        tsProvider: TimestampProvider? = nil,
        cfg: APIConfiguration? = nil
    ) {
        if let getHeroesUseCase {
            self.getHeroesUseCase.register { getHeroesUseCase }
        }
        if let apiClient { self.apiClient.register { apiClient } }
        if let useCase = getHeroesUseCase { self.getHeroesUseCase.register { useCase } }
        if let logger { self.logger.register { logger } }
        if let urlSession { self.urlSession.register { urlSession } }
        if let tsProvider { self.timestampProvider.register { tsProvider } }
        if let cfg { self.apiConfiguration.register { cfg } }
    }

    /// Reset all mocked dependencies
    func resetMocks() { self.reset() }
}
#endif