import XCTest
import SwiftUI
import SnapshotTesting
import FactoryKit
@testable import WallaMarvel

final class WallaMarvelSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        #if DEBUG
        Container.shared.getHeroesUseCase.register { UITestMockUseCase() }
        Container.shared.logger.register { NoopLogger() }
        #endif
    }

    override func tearDown() {
        #if DEBUG
        Container.shared.getHeroesUseCase.reset()
        Container.shared.logger.reset()
        #endif
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    // MARK: - Helpers

    private func host<V: View>(
        _ view: V,
        style: UIUserInterfaceStyle = .light
    ) -> UIViewController {
        let vc = UIHostingController(rootView: view)
        vc.overrideUserInterfaceStyle = style
        // Trigger view loading and give SwiftUI a beat to run .onAppear work
        _ = vc.view
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 13 portrait
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        return vc
    }

    // MARK: - List screen

    func test_ListHeroes_light() {
        let presenter = Container.shared.listHeroesPresenter()
        let vc = host(ListHeroesScreen(presenter: presenter), style: .light)
        assertSnapshot(of: vc, as: .image(on: .iPhone13))
    }

    func test_ListHeroes_dark() {
        let presenter = Container.shared.listHeroesPresenter()
        let vc = host(ListHeroesScreen(presenter: presenter), style: .dark)
        assertSnapshot(of: vc, as: .image(on: .iPhone13))
    }

    // MARK: - Detail screen

    func test_HeroDetail_light() {
        let hero = CharacterDataModel.sample()
        let vc = host(DetailHarness(hero: hero), style: .light)
        assertSnapshot(of: vc, as: .image(on: .iPhone13))
    }

    func test_HeroDetail_dark() {
        let hero = CharacterDataModel.sample()
        let vc = host(DetailHarness(hero: hero), style: .dark)
        assertSnapshot(of: vc, as: .image(on: .iPhone13))
    }
}

#if DEBUG
// Quiet logger for deterministic tests
private final class NoopLogger: LoggerProtocol {
    func debug(_ message: String, metadata: [String : String]?) {}
    func info(_ message: String, metadata: [String : String]?) {}
    func warning(_ message: String, metadata: [String : String]?) {}
    func error(_ message: String, error: Error?, metadata: [String : String]?) {}
}
#endif

// Harness to supply a Namespace.ID to the detail screen.
private struct DetailHarness: View {
    let hero: CharacterDataModel
    @Namespace private var ns
    var body: some View {
        NavigationStack {
            HeroDetailScreen(hero: hero)
        }
    }
}
