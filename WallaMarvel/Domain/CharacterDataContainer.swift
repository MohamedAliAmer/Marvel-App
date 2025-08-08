import Foundation

struct CharacterDataContainer: Decodable { let data: CharacterDataWrapper }

struct CharacterDataWrapper: Decodable {
    let count: Int
    let limit: Int
    let offset: Int
    let total: Int
    let results: [CharacterDataModel]
}
