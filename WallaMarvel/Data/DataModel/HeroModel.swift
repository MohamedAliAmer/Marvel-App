import Foundation

struct HeroModel: Hashable {
    let id: Int
    let name: String
    let imageURL: URL?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: HeroModel, rhs: HeroModel) -> Bool {
        lhs.id == rhs.id
    }
}
