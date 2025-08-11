import Foundation

@testable import WallaMarvel

@MainActor
final class TestUISpy: ListHeroesUI {
    private(set) var loadingStates: [Bool] = []
    private(set) var paginatingStates: [Bool] = []
    private(set) var shownItems: [[HeroModel]] = []
    private(set) var hasMoreFlags: [Bool] = []
    private(set) var lastError: String?
    private(set) var shownDetails: [CharacterDataModel] = []

    var onShowItems: (() -> Void)?
    var onShowDetails: (() -> Void)?
    var onError: (() -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    func setLoading(_ isLoading: Bool) { loadingStates.append(isLoading); onLoadingChanged?(isLoading) }
    func setPaginating(_ isPaginating: Bool) { paginatingStates.append(isPaginating) }
    func show(heroes: [HeroModel], isRefresh: Bool, hasMore: Bool) { shownItems.append(heroes); hasMoreFlags.append(hasMore); onShowItems?() }
    func showError(_ message: String) { lastError = message; onError?() }
    func showHeroDetails(_ hero: CharacterDataModel) { shownDetails.append(hero); onShowDetails?() }
}
