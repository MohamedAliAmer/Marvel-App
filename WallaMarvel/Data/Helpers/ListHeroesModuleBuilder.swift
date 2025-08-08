import FactoryKit

enum ListHeroesModuleBuilder {
    static func buildView() -> ListHeroesScreen {
        let presenter = Container.shared.listHeroesPresenter()
        return ListHeroesScreen(presenter: presenter)
    }
}
