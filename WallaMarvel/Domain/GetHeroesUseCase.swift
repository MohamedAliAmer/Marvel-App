import Foundation

protocol GetHeroesUseCaseProtocol {
    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer
    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel
}

/// APIClient directly satisfies the app-facing use case
extension APIClient: GetHeroesUseCaseProtocol {
    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer {
        try await getHeroes(offset: offset, limit: limit, nameStartsWith: nameStartsWith)
    }

    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel {
        let container = try await getHeroDetailsRaw(heroId: heroId)
        guard let hero = container.data.results.first else { throw MarvelError.heroNotFound }
        return hero
    }
}
