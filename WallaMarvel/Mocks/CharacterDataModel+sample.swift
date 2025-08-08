import Foundation

extension CharacterDataModel {
    static func sample(
        id: Int = 7,
        name: String = "Hero 7",
        description: String = "UITest details for id 7",
        thumbnail: Thumbnail = Thumbnail(path: "https://example.com/img7", extension: "jpg"),
        comics: ItemList = ItemList(available: 3, items: [Item(name: "Comic A"), Item(name: "Comic B")]),
        series: ItemList = ItemList(available: 1, items: [Item(name: "Series X")]),
        stories: ItemList = ItemList(available: 0, items: nil),
        events: ItemList = ItemList(available: 0, items: nil)
    ) -> CharacterDataModel {
        CharacterDataModel(
            id: id,
            name: name,
            description: description,
            thumbnail: thumbnail,
            comics: comics,
            series: series,
            stories: stories,
            events: events
        )
    }
}
