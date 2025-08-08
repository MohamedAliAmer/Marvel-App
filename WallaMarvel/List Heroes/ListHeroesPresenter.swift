import Foundation

protocol ListHeroesPresenterProtocol: AnyObject {
    func attach(ui: ListHeroesUI)
    func screenTitle() -> String
    func viewDidLoad()
    func refresh()
    func search(text: String)
    func loadMoreIfNeeded(currentRow: Int)
    func didSelectHero(at index: Int)
}

final class ListHeroesPresenter: ListHeroesPresenterProtocol {
    private weak var ui: ListHeroesUI?
    private let useCase: GetHeroesUseCaseProtocol
    private let logger: LoggerProtocol

    private var heroes: [CharacterDataModel] = []
    private let limit = 20
    private var offset = 0
    private var total = Int.max
    private var query = ""
    private var isLoading = false
    private var currentTask: Task<Void, Never>? = nil

    init(useCase: GetHeroesUseCaseProtocol, logger: LoggerProtocol) {
        self.useCase = useCase
        self.logger = logger
    }

    func attach(ui: ListHeroesUI) { self.ui = ui }

    func screenTitle() -> String { "List of Heroes" }

    func viewDidLoad() {
        fetch(reset: true)
    }

    func refresh() {
        fetch(reset: true)
    }

    func search(text: String) {
        query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        fetch(reset: true)
    }

    func loadMoreIfNeeded(currentRow: Int) {
        guard currentRow >= heroes.count - 5, heroes.count < total else { return }
        fetch(reset: false)
    }

    func didSelectHero(at index: Int) {
        guard heroes.indices.contains(index) else { return }
        let initialHero = heroes[index]

        Task { await MainActor.run { self.ui?.showHeroDetails(initialHero) } }

        Task {
            do {
                let fresh = try await useCase.getHeroDetails(heroId: initialHero.id)
                if fresh != initialHero {
                    await MainActor.run { self.ui?.showHeroDetails(fresh) }
                }
            } catch {
                self.logger.error("Fetch hero details failed",
                                  error: error,
                                  metadata: ["hero_id": String(initialHero.id)])
            }
        }
    }

    private func fetch(reset: Bool) {
        guard !isLoading else { return }
        isLoading = true
        if reset {
            offset = 0
            total = Int.max
            heroes.removeAll()
        }

        currentTask?.cancel()

        currentTask = Task {
            await MainActor.run {
                if reset { self.ui?.setLoading(true) }
                else { self.ui?.setPaginating(true) }
            }
            if !reset { await Task.yield() }

            defer {
                self.isLoading = false
                self.currentTask = nil
            }

            if Task.isCancelled {
                await MainActor.run {
                    self.ui?.setLoading(false)
                    self.ui?.setPaginating(false)
                }
                return
            }

            let paginationStart = Date()

            do {
                let container = try await useCase.execute(
                    offset: offset,
                    limit: limit,
                    nameStartsWith: query.isEmpty ? nil : query
                )
                if Task.isCancelled {
                    await MainActor.run {
                        self.ui?.setLoading(false)
                        self.ui?.setPaginating(false)
                    }
                    return
                }

                let page = container.data
                self.total = page.total
                self.offset += page.count
                if reset { self.heroes = page.results }
                else { self.heroes.append(contentsOf: page.results) }

                await MainActor.run { self.ui?.showError("") }

                let models = self.heroes.map {
                    HeroModel(
                        id: $0.id,
                        name: $0.name,
                        imageURL: URL(string: "\($0.thumbnail.path)/portrait_medium.\($0.thumbnail.`extension`)")
                    )
                }

                await MainActor.run {
                    self.ui?.show(heroes: models, isRefresh: reset, hasMore: self.heroes.count < self.total)
                }

                if !reset {
                    let elapsed = Date().timeIntervalSince(paginationStart)
                    let minVisible: Double = 0.20
                    let oneFrame: Double = 0.016
                    let delay = max(minVisible - elapsed, oneFrame)
                    if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
                    await MainActor.run { self.ui?.setPaginating(false) }
                } else {
                    await MainActor.run { self.ui?.setLoading(false) }
                }
            } catch {
                if Task.isCancelled {
                    await MainActor.run {
                        self.ui?.setLoading(false)
                        self.ui?.setPaginating(false)
                    }
                    return
                }
                self.logger.error("Fetch heroes failed",
                                  error: error,
                                  metadata: [
                                    "reset": String(reset),
                                    "query": self.query,
                                    "offset": String(self.offset),
                                    "limit": String(self.limit)
                                  ])
                if !reset {
                    let elapsed = Date().timeIntervalSince(paginationStart)
                    let minVisible: Double = 0.20
                    let oneFrame: Double = 0.016
                    let delay = max(minVisible - elapsed, oneFrame)
                    if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
                    await MainActor.run {
                        self.ui?.showError(error.localizedDescription)
                        self.ui?.setPaginating(false)
                    }
                } else {
                    await MainActor.run {
                        self.ui?.showError(error.localizedDescription)
                        self.ui?.setLoading(false)
                    }
                }
            }
        }
    }
}
