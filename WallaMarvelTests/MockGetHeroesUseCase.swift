import Foundation

@testable import WallaMarvel


final class MockGetHeroesUseCase: GetHeroesUseCaseProtocol {
    var onExecute: ((Int, Int, String?) async throws -> CharacterDataContainer)!
    var onDetails: ((Int) async throws -> CharacterDataModel)!
    func execute(offset: Int, limit: Int, nameStartsWith: String?) async throws -> CharacterDataContainer {
        try await onExecute(offset, limit, nameStartsWith)
    }
    func getHeroDetails(heroId: Int) async throws -> CharacterDataModel {
        try await onDetails(heroId)
    }
}
