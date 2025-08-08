import Foundation

#if DEBUG
final class UITestMockUseCase: GetHeroesUseCaseProtocol {
    private let items: [CharacterDataModel]
    private var didErrorFirstPage = false
    private let scenario: String

    init() {
        self.scenario = ProcessInfo.processInfo.environment["UITEST_SCENARIO"] ?? "happy"
        self.items = (1...30).map { id in
            CharacterDataModel(
                id: id,
                name: "Hero \(id)",
                description: "",
                thumbnail: Thumbnail(path: "https://example.com/img\(id)", extension: "jpg"),
                comics: ItemList(available: id % 3, items: nil),
                series: ItemList(available: id % 4, items: nil),
                stories: ItemList(available: id % 5, items: nil),
                events: ItemList(available: id % 2, items: nil)
            )
        }
    }

    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer {
        if scenario == "errorFirstPage", offset == 0, !didErrorFirstPage {
            didErrorFirstPage = true
            throw MarvelError.heroNotFound
        }
        var filtered = items
        if let q = nameStartsWith, !q.isEmpty {
            filtered = items.filter { $0.name.lowercased().hasPrefix(q.lowercased()) }
        }
        let total = filtered.count
        let start = min(max(offset, 0), total)
        let end = min(start + limit, total)
        let page = Array(filtered[start..<end])
        return CharacterDataContainer(
            data: CharacterDataWrapper(count: page.count, limit: limit, offset: start, total: total, results: page)
        )
    }

    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel {
        if let hero = items.first(where: { $0.id == heroId }) {
            return CharacterDataModel(
                id: hero.id,
                name: hero.name,
                description: "UITest details for id \(hero.id)",
                thumbnail: hero.thumbnail,
                comics: hero.comics,
                series: hero.series,
                stories: hero.stories,
                events: hero.events
            )
        }
        throw MarvelError.heroNotFound
    }
}
#endif
