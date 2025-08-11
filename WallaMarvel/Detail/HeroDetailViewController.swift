import UIKit

/// UIKit-based hero detail view controller for legacy navigation
final class HeroDetailViewController: UIViewController {
    
    private let hero: CharacterDataModel
    
    /// Type-safe access to detail view
    private var detailView: HeroDetailView {
        return view as! HeroDetailView
    }
    
    /// Initialize with hero data
    init(hero: CharacterDataModel) {
        self.hero = hero
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Load custom view programmatically
    override func loadView() {
        view = HeroDetailView()
    }
    
    /// Configure view with hero data and set navigation title
    override func viewDidLoad() {
        super.viewDidLoad()
        title = hero.name
        detailView.configure(with: hero)
    }
}