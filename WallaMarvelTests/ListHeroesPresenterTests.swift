import XCTest
import FactoryKit
@testable import WallaMarvel

func makePage(offset: Int, limit: Int, total: Int, ids: [Int]) -> CharacterDataContainer {
    let results = ids.map { CharacterDataModel.sample(id: $0) }
    return CharacterDataContainer(
        data: CharacterDataWrapper(count: results.count, limit: limit, offset: offset, total: total, results: results)
    )
}

// MARK: - Tests

@MainActor
final class ListHeroesPresenterTests: XCTestCase {

    override func tearDown() {
        Container.shared.resetMocks()
        super.tearDown()
    }

    func testViewDidLoadLoadsFirstPage() {
        let logger = PresenterTestLogger()
        let mock = MockGetHeroesUseCase()
        mock.onExecute = { offset, limit, q in
            XCTAssertEqual(offset, 0); XCTAssertEqual(limit, 20); XCTAssertNil(q)
            return makePage(offset: 0, limit: 20, total: 2, ids: [1,2])
        }
        mock.onDetails = { _ in CharacterDataModel.sample(id: 0) }

        Container.shared.useMocks(getHeroesUseCase: mock, logger: logger)
        let presenter = Container.shared.listHeroesPresenter()
        let ui = TestUISpy()

        let loadingEnded = expectation(description: "loading ended")
        var fulfilled = false
        ui.onLoadingChanged = { isLoading in
            if !isLoading && !fulfilled {
                fulfilled = true
                loadingEnded.fulfill()
            }
        }

        presenter.attach(ui: ui)

        let shown = expectation(description: "items")
        ui.onShowItems = { shown.fulfill() }
        presenter.viewDidLoad()

        wait(for: [shown, loadingEnded], timeout: 2.0)

        XCTAssertEqual(ui.shownItems.last?.count, 2)
        XCTAssertEqual(ui.hasMoreFlags.last, false)
        XCTAssertEqual(ui.loadingStates.last, false)
    }

    func testSearchResetsAndUsesQuery() {
        let logger = PresenterTestLogger()
        let mock = MockGetHeroesUseCase()
        var seenQueries: [String?] = []
        mock.onExecute = { _,_,q in
            seenQueries.append(q)
            return (q == nil)
                ? makePage(offset: 0, limit: 20, total: 1, ids: [1])
                : makePage(offset: 0, limit: 20, total: 1, ids: [42])
        }
        mock.onDetails = { _ in CharacterDataModel.sample(id: 42) }

        Container.shared.useMocks(getHeroesUseCase: mock, logger: logger)
        let presenter = Container.shared.listHeroesPresenter()
        let ui = TestUISpy()

        let loadingEnded = expectation(description: "loading ended (initial)")
        var fulfilled = false
        ui.onLoadingChanged = { isLoading in if !isLoading && !fulfilled { fulfilled = true; loadingEnded.fulfill() } }

        presenter.attach(ui: ui)

        let first = expectation(description: "first shown")
        let second = expectation(description: "second shown")
        var count = 0
        ui.onShowItems = {
            count += 1
            if count == 1 { first.fulfill() }
            else if count == 2 { second.fulfill() }
        }

        presenter.viewDidLoad()
        wait(for: [first, loadingEnded], timeout: 2.0)

        presenter.search(text: "sp")
        wait(for: [second], timeout: 2.0)

        XCTAssertEqual(ui.shownItems.last?.map(\.id), [42])
        XCTAssertEqual(seenQueries.compactMap { $0 }, ["sp"]) // filtered: [nil, "sp"]
    }

    func testLoadMorePaginatesNearEnd() {
        let logger = PresenterTestLogger()
        let mock = MockGetHeroesUseCase()
        mock.onDetails = { _ in CharacterDataModel.sample(id: 1000) }
        var pages = 0
        mock.onExecute = { _,_,_ in
            pages += 1
            return (pages == 1)
            ? makePage(offset: 0, limit: 20, total: 30, ids: Array(1...20))
            : makePage(offset: 20, limit: 20, total: 30, ids: Array(21...30))
        }

        Container.shared.useMocks(getHeroesUseCase: mock, logger: logger)
        let presenter = Container.shared.listHeroesPresenter()
        let ui = TestUISpy()

        let loadingEnded = expectation(description: "loading ended")
        var fulfilled = false
        ui.onLoadingChanged = { isLoading in if !isLoading && !fulfilled { fulfilled = true; loadingEnded.fulfill() } }

        presenter.attach(ui: ui)

        let first = expectation(description: "first shown")
        ui.onShowItems = { first.fulfill() }
        presenter.viewDidLoad()
        wait(for: [first, loadingEnded], timeout: 2.0)

        let second = expectation(description: "second shown")
        ui.onShowItems = { second.fulfill() }
        presenter.loadMoreIfNeeded(currentRow: 18)
        wait(for: [second], timeout: 2.0)

        XCTAssertEqual(ui.shownItems.last?.map(\.id), Array(1...30))
        XCTAssertEqual(ui.hasMoreFlags.last, false)
        XCTAssertTrue(ui.paginatingStates.last == true)
    }

    func testDidSelectHeroShowsImmediateThenUpdatesWithFreshDetails() {
        let logger = PresenterTestLogger()
        let mock = MockGetHeroesUseCase()
        mock.onExecute = { _,_,_ in makePage(offset: 0, limit: 20, total: 2, ids: [7,8]) }
        mock.onDetails = { id in
            if id == 7 { return CharacterDataModel(
                id: 7, name: "Hero 7", description: "Fresh description",
                thumbnail: Thumbnail(path: "https://example.com/img7", extension: "jpg"),
                comics: ItemList(available: 1, items: nil),
                series: ItemList(available: 0, items: nil),
                stories: ItemList(available: 0, items: nil),
                events: ItemList(available: 0, items: nil)
            ) }
            return CharacterDataModel.sample(id: id)
        }

        Container.shared.useMocks(getHeroesUseCase: mock, logger: logger)
        let presenter = Container.shared.listHeroesPresenter()
        let ui = TestUISpy()

        presenter.attach(ui: ui)

        let items = expectation(description: "items")
        ui.onShowItems = { items.fulfill() }
        presenter.viewDidLoad()
        wait(for: [items], timeout: 2.0)

        let detailsTwice = expectation(description: "details twice")
        detailsTwice.expectedFulfillmentCount = 2
        ui.onShowDetails = { detailsTwice.fulfill() }

        presenter.didSelectHero(at: 0)
        wait(for: [detailsTwice], timeout: 2.0)

        XCTAssertEqual(ui.shownDetails.first?.id, 7)
        XCTAssertEqual(ui.shownDetails.last?.description, "Fresh description")
    }

    func testErrorShowsMessageAndClearsSpinner() {
        struct Boom: Error {}
        let logger = PresenterTestLogger()
        let mock = MockGetHeroesUseCase()
        mock.onExecute = { _,_,_ in throw Boom() }
        mock.onDetails = { _ in CharacterDataModel.sample(id: 0) }

        Container.shared.useMocks(getHeroesUseCase: mock, logger: logger)
        let presenter = Container.shared.listHeroesPresenter()
        let ui = TestUISpy()

        presenter.attach(ui: ui)

        let err = expectation(description: "error")
        ui.onError = { err.fulfill() }
        presenter.viewDidLoad()
        wait(for: [err], timeout: 2.0)

        XCTAssertFalse(ui.loadingStates.last ?? true)
        XCTAssertNotNil(logger.entries.first { $0.level == .error })
    }
}
