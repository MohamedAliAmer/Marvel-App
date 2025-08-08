import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        #if DEBUG
        if ProcessInfo.processInfo.environment["UITEST_USE_MOCK"] == "1" {
            Container.shared.useMocks(getHeroesUseCase: UITestMockUseCase())
        }
        #endif

        self.window = AppRootBuilder.makeWindow(for: windowScene)
    }
}
