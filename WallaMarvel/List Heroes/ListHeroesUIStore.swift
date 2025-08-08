//
//  ListHeroesUIStore.swift
//  WallaMarvel
//
//  Created by Mohamed Ali on 11/8/25.
//

import Foundation

protocol ListHeroesUI: AnyObject {
    @MainActor func setLoading(_ isLoading: Bool)
    @MainActor func setPaginating(_ isPaginating: Bool)
    @MainActor func show(heroes: [HeroModel], isRefresh: Bool, hasMore: Bool)
    @MainActor func showError(_ message: String)
    @MainActor func showHeroDetails(_ hero: CharacterDataModel)
}

final class ListHeroesUIStore: ObservableObject, ListHeroesUI {
    let presenter: ListHeroesPresenterProtocol
    private var didLoad = false

    @Published var isLoading = false
    @Published var isPaginating = false
    @Published var items: [HeroModel] = []
    @Published var hasMore = false
    @Published var selectedHero: CharacterDataModel?
    @Published var errorMessage: String?
    var screenTitle: String { presenter.screenTitle() }

    init(presenter: ListHeroesPresenterProtocol) {
        self.presenter = presenter
        self.presenter.attach(ui: self)
    }

    @MainActor func setLoading(_ isLoading: Bool) { self.isLoading = isLoading }
    @MainActor func setPaginating(_ isPaginating: Bool) { self.isPaginating = isPaginating }
    @MainActor func show(heroes: [HeroModel], isRefresh: Bool, hasMore: Bool) {
        self.items = heroes
        self.hasMore = hasMore
    }
    @MainActor func showError(_ message: String) { self.errorMessage = message }
    @MainActor func showHeroDetails(_ hero: CharacterDataModel) { self.selectedHero = hero }

    func ensureLoaded() {
        if !didLoad {
            presenter.viewDidLoad()
            didLoad = true
        }
    }

    func search(_ text: String) {
        presenter.search(text: text)
    }

    func loadMoreIfNeeded(for id: Int) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            presenter.loadMoreIfNeeded(currentRow: idx)
        }
    }

    func didSelectRow(with id: Int) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            presenter.didSelectHero(at: idx)
        }
    }

    @MainActor
    func refresh() {
        presenter.refresh()
    }

    func refreshAwaitingCompletion(timeout: TimeInterval = 5.0) async {
        await MainActor.run { presenter.refresh() }
        let start = Date()
        while isLoading && Date().timeIntervalSince(start) < timeout {
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
    }
}
