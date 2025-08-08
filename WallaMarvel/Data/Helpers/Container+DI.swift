import Foundation
import FactoryKit

extension Container {
    var appInfoProvider: Factory<AppInfoProviderProtocol> {
        self { DefaultAppInfoProvider() }.singleton
    }
    var loggingServiceProvider: Factory<LoggingServiceProvider> {
        self { PrintLoggingServiceProvider() }.singleton
    }
    var logger: Factory<LoggerProtocol> {
        self { DefaultLogger(service: self.loggingServiceProvider(),
                             appInfo: self.appInfoProvider()) }.singleton
    }

    var apiConfiguration: Factory<APIConfiguration> {
        self { InfoPlistAPIConfiguration() }.singleton
    }
    var urlSession: Factory<URLSession> {
        self { URLSession.shared }.singleton
    }
    var timestampProvider: Factory<TimestampProvider> {
        self { DefaultTimestampProvider() }.singleton
    }

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

    var apiClient: Factory<APIClientProtocol> {
        self { self.apiClientImpl() }
    }

    var getHeroesUseCase: Factory<GetHeroesUseCaseProtocol> {
        self { self.apiClientImpl() }
    }

    var listHeroesPresenter: Factory<ListHeroesPresenterProtocol> {
        self { ListHeroesPresenter(useCase: self.getHeroesUseCase(), logger: self.logger()) }
    }
}

#if DEBUG
extension Container {
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

    func resetMocks() { self.reset() }
}
#endif
