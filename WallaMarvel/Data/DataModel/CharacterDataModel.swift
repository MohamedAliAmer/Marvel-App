import Foundation

struct CharacterDataModel: Decodable {
    let id: Int
    let name: String
    let description: String
    let thumbnail: Thumbnail
    let comics: ItemList?
    let series: ItemList?
    let stories: ItemList?
    let events: ItemList?
}

struct ItemList: Decodable, Equatable {
    let available: Int
    let items: [Item]?
}

struct Item: Decodable, Equatable { let name: String }

extension CharacterDataModel: Identifiable, Hashable, Equatable {
    static func == (lhs: CharacterDataModel, rhs: CharacterDataModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.thumbnail == rhs.thumbnail &&
        lhs.comics?.available == rhs.comics?.available &&
        lhs.series?.available == rhs.series?.available &&
        lhs.stories?.available == rhs.stories?.available &&
        lhs.events?.available == rhs.events?.available
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
