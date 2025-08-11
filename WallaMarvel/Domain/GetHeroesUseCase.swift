import Foundation

/// Domain protocol for hero-related operations
protocol GetHeroesUseCaseProtocol {
    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer
    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel
}

/// APIClient extension that adapts data layer to domain layer
/// This allows APIClient to serve as both data access and use case layer
extension APIClient: GetHeroesUseCaseProtocol {
    /// Executes hero list request - delegates to data layer
    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer {
        try await getHeroes(offset: offset, limit: limit, nameStartsWith: nameStartsWith)
    }

    /// Fetches single hero details with validation
    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel {
        let container = try await getHeroDetailsRaw(heroId: heroId)
        guard let hero = container.data.results.first else { throw MarvelError.heroNotFound }
        return hero
    }
}