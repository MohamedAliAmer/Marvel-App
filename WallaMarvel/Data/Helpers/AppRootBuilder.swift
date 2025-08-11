import UIKit
import SwiftUI

/// Builder for app root window configuration
enum AppRootBuilder {
    /// Configuration options for app setup
    struct Configuration {
        var cacheMemoryMB: Int = 50
        var cacheDiskMB: Int = 200
        var cacheDiskPath: String = "urlcache"
    }

    /// Creates and configures the main app window with caching and root view
    static func makeWindow(for windowScene: UIWindowScene,
                           configuration: Configuration = .init(),
                           presenterOverride: ListHeroesPresenterProtocol? = nil) -> UIWindow {
        configureURLCache(memoryMB: configuration.cacheMemoryMB,
                          diskMB: configuration.cacheDiskMB,
                          diskPath: configuration.cacheDiskPath
        )

        // Build root view with dependency injection
        let rootView: ListHeroesScreen
        if let presenter = presenterOverride {
            rootView = ListHeroesScreen(presenter: presenter)
        } else {
            rootView = ListHeroesModuleBuilder.buildView()
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
        return window
    }

    /// Configures shared URL cache for image and API response caching
    private static func configureURLCache(memoryMB: Int, diskMB: Int, diskPath: String) {
        let cache = URLCache(memoryCapacity: memoryMB * 1024 * 1024,
                             diskCapacity: diskMB * 1024 * 1024,
                             diskPath: diskPath)
        URLCache.shared = cache
    }
}
