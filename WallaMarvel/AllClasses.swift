import Foundation
import UIKit
import Kingfisher

// MARK: - Data Models
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

struct ItemList: Decodable {
    let available: Int
    let items: [Item]?
}

struct Item: Decodable {
    let name: String
}

struct CharacterDataContainer: Decodable {
    let data: CharacterDataWrapper
}

struct CharacterDataWrapper: Decodable {
    let count: Int
    let limit: Int
    let offset: Int
    let total: Int
    let results: [CharacterDataModel]
    
    var characters: [CharacterDataModel] {
        return results
    }
}

struct Thumbnail: Decodable {
    let path: String
    let `extension`: String
}

// MARK: - List Heroes Components
final class ListHeroesView: UIView {
    enum Constant {
        static let estimatedRowHeight: CGFloat = 120
    }
    
    let heroesTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ListHeroesTableViewCell.self, forCellReuseIdentifier: "ListHeroesTableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constant.estimatedRowHeight
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubviews()
        addContraints()
    }
    
    private func addSubviews() {
        addSubview(heroesTableView)
        addSubview(activityIndicator)
    }
    
    private func addContraints() {
        NSLayoutConstraint.activate([
            heroesTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroesTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroesTableView.topAnchor.constraint(equalTo: topAnchor),
            heroesTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func showLoading() {
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        activityIndicator.stopAnimating()
    }
}

final class ListHeroesAdapter: NSObject, UITableViewDataSource {
    var heroes: [CharacterDataModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private let tableView: UITableView
    
    init(tableView: UITableView, heroes: [CharacterDataModel] = []) {
        self.tableView = tableView
        self.heroes = heroes
        super.init()
        self.tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        heroes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListHeroesTableViewCell", for: indexPath) as! ListHeroesTableViewCell
        
        let model = heroes[indexPath.row]
        cell.configure(model: model)
        
        return cell
    }
}

protocol ListHeroesPresenterProtocol: AnyObject {
    var ui: ListHeroesUI? { get set }
    func screenTitle() -> String
    func getHeroes(offset: Int, limit: Int, nameStartsWith: String?) async
    func getHeroDetails(heroId: Int) async
}

protocol ListHeroesUI: AnyObject {
    func update(heroes: [CharacterDataModel])
    func showLoading()
    func hideLoading()
    func showError(_ error: String)
    func showHeroDetails(_ hero: CharacterDataModel)
}

final class ListHeroesPresenter: ListHeroesPresenterProtocol {
    var ui: ListHeroesUI?
    private let getHeroesUseCase: GetHeroesUseCaseProtocol
    
    init(getHeroesUseCase: GetHeroesUseCaseProtocol = GetHeroes()) {
        self.getHeroesUseCase = getHeroesUseCase
    }
    
    func screenTitle() -> String {
        "List of Heroes"
    }
    
    // MARK: UseCases
    
    func getHeroes(offset: Int = 0, limit: Int = 20, nameStartsWith: String? = nil) async {
        do {
            if offset == 0 {
                ui?.showLoading()
            }
            let characterDataContainer = try await getHeroesUseCase.execute(offset: offset, limit: limit, nameStartsWith: nameStartsWith)
            ui?.hideLoading()
            ui?.update(heroes: characterDataContainer.data.results)
        } catch {
            ui?.hideLoading()
            ui?.showError(error.localizedDescription)
        }
    }
    
    func getHeroDetails(heroId: Int) async {
        do {
            let hero = try await getHeroesUseCase.getHeroDetails(heroId: heroId)
            ui?.showHeroDetails(hero)
        } catch {
            ui?.showError(error.localizedDescription)
        }
    }
}

final class ListHeroesTableViewCell: UITableViewCell {
    private let heroeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let heroeName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubviews()
        addContraints()
        setupAccessibility()
    }
    
    private func addSubviews() {
        addSubview(heroeImageView)
        addSubview(heroeName)
    }
    
    private func addContraints() {
        NSLayoutConstraint.activate([
            heroeImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            heroeImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            heroeImageView.heightAnchor.constraint(equalToConstant: 80),
            heroeImageView.widthAnchor.constraint(equalToConstant: 80),
            heroeImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            heroeName.leadingAnchor.constraint(equalTo: heroeImageView.trailingAnchor, constant: 12),
            heroeName.topAnchor.constraint(equalTo: heroeImageView.topAnchor, constant: 8),
            heroeName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        heroeImageView.isAccessibilityElement = false
        heroeName.isAccessibilityElement = false
    }
    
    func configure(model: CharacterDataModel) {
        heroeImageView.kf.setImage(with: URL(string: model.thumbnail.path + "/portrait_small." + model.thumbnail.extension))
        heroeName.text = model.name
        
        // Accessibility
        accessibilityLabel = model.name
        accessibilityHint = "Double tap to view hero details"
    }
}

final class ListHeroesViewController: UIViewController {
    var mainView: ListHeroesView { return view as! ListHeroesView }
    
    var presenter: ListHeroesPresenterProtocol?
    var listHeroesProvider: ListHeroesAdapter?
    
    private var allHeroes: [CharacterDataModel] = []
    private var isLoading = false
    private var currentOffset = 0
    private let limit = 20
    private var currentSearchText = ""
    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        return searchController
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func loadView() {
        view = ListHeroesView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchController()
        setupLoadingIndicator()
        
        listHeroesProvider = ListHeroesAdapter(tableView: mainView.heroesTableView)
        mainView.heroesTableView.delegate = self
        
        presenter?.ui = self
        title = presenter?.screenTitle()
        
        Task {
            await presenter?.getHeroes(offset: currentOffset, limit: limit, nameStartsWith: nil)
        }
        
        setupPagination()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search heroes"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupPagination() {
        mainView.heroesTableView.prefetchDataSource = self
    }
}

extension ListHeroesViewController: ListHeroesUI {
    func update(heroes: [CharacterDataModel]) {
        if currentOffset == 0 {
            // Refreshing the list
            allHeroes = heroes
            listHeroesProvider?.heroes = heroes
        } else {
            // Adding more heroes
            allHeroes.append(contentsOf: heroes)
            listHeroesProvider?.heroes = allHeroes
        }
    }
    
    func showLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
        }
    }
    
    func showError(_ error: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func showHeroDetails(_ hero: CharacterDataModel) {
        DispatchQueue.main.async {
            let detailViewController = HeroDetailViewController(hero: hero)
            self.navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
}

extension ListHeroesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let hero = allHeroes[indexPath.row]
        
        Task {
            await presenter?.getHeroDetails(heroId: hero.id)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        // Load more when we're close to the bottom
        if offsetY > contentHeight - frameHeight - 100 {
            loadMoreHeroes()
        }
    }
    
    private func loadMoreHeroes() {
        guard !isLoading && (!currentSearchText.isEmpty || currentSearchText.isEmpty) else { return }
        
        isLoading = true
        currentOffset += limit
        
        Task {
            await presenter?.getHeroes(offset: currentOffset, limit: limit, nameStartsWith: currentSearchText.isEmpty ? nil : currentSearchText)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

extension ListHeroesViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let maxRow = indexPaths.map { $0.row }.max() ?? 0
        if maxRow >= allHeroes.count - 5 {
            loadMoreHeroes()
        }
    }
}

extension ListHeroesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        // Reset offset for new search
        currentOffset = 0
        currentSearchText = searchText
        
        Task {
            await presenter?.getHeroes(offset: currentOffset, limit: limit, nameStartsWith: searchText.isEmpty ? nil : searchText)
        }
    }
}
</parameter>
</function>