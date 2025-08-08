import UIKit
import SwiftUI

enum AppRootBuilder {
    struct Configuration {
        var cacheMemoryMB: Int = 50
        var cacheDiskMB: Int = 200
        var cacheDiskPath: String = "urlcache"
    }

    static func makeWindow(for windowScene: UIWindowScene,
                           configuration: Configuration = .init(),
                           presenterOverride: ListHeroesPresenterProtocol? = nil) -> UIWindow {
        configureURLCache(memoryMB: configuration.cacheMemoryMB,
                          diskMB: configuration.cacheDiskMB,
                          diskPath: configuration.cacheDiskPath)

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

    private static func configureURLCache(memoryMB: Int, diskMB: Int, diskPath: String) {
        let cache = URLCache(memoryCapacity: memoryMB * 1024 * 1024,
                             diskCapacity: diskMB * 1024 * 1024,
                             diskPath: diskPath)
        URLCache.shared = cache
    }
}
