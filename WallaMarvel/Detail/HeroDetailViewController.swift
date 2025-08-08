import UIKit

final class HeroDetailViewController: UIViewController {
    
    private let hero: CharacterDataModel
    
    private var detailView: HeroDetailView {
        return view as! HeroDetailView
    }
    
    init(hero: CharacterDataModel) {
        self.hero = hero
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = HeroDetailView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = hero.name
        detailView.configure(with: hero)
    }
}