import XCTest

final class WallaMarvelUITests: XCTestCase {

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_USE_MOCK"] = "1"
        app.launch()
        return app
    }

    private func row(named name: String, in app: XCUIApplication) -> XCUIElement {
        let byButtonLabel = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
        if byButtonLabel.exists { return byButtonLabel }
        let byAnyLabel = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name)).firstMatch
        return byAnyLabel
    }

    private func scrollTo(element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 10) {
        let list = app.tables.firstMatch
        var tries = 0
        while !element.exists && tries < maxSwipes {
            if list.exists {
                list.swipeUp()
            } else {
                app.swipeUp()
            }
            tries += 1
        }
    }

    // MARK: - Tests

    func testInitialListShowsFirstItems() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["List of Heroes"].waitForExistence(timeout: 4))
        XCTAssertTrue(row(named: "Hero 1", in: app).waitForExistence(timeout: 4))
    }

    func testSearchFiltersResults() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["List of Heroes"].waitForExistence(timeout: 4))

        let searchField = app.searchFields["Search heroes"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 4))
        searchField.tap()
        searchField.typeText("Hero 2\n") // triggers debounce + search

        XCTAssertTrue(row(named: "Hero 2", in: app).waitForExistence(timeout: 4))
    }

    func testPaginationLoadsMoreWhenScrolling() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["List of Heroes"].waitForExistence(timeout: 4))

        let target = row(named: "Hero 25", in: app)
        scrollTo(element: target, in: app, maxSwipes: 12)
        XCTAssertTrue(target.exists, "Expected to find a later hero after pagination")
    }

    func testTapRowShowsDetailsScreen() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["List of Heroes"].waitForExistence(timeout: 4))

        let targetRow = row(named: "Hero 7", in: app)
        scrollTo(element: targetRow, in: app, maxSwipes: 12)
        XCTAssertTrue(targetRow.waitForExistence(timeout: 2.5))
        targetRow.tap()

        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Hero 7"].waitForExistence(timeout: 4))
    }
}
