import UIKit
import Observation
import UIKitNavigation

@Observable
@MainActor
final class PodcastViewModel {
    var searchText = ""
}

final class PodcastListViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Podcast>
    private let cellRegistration = UICollectionView.CellRegistration { cell, indexPath, podcast in
        cell.contentConfiguration = podcast
    }
    private lazy var dataSource = DataSource(collectionView: collectionView) {
        (collectionView, indexPath, itemIdentifier) in
        collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: itemIdentifier
        )
    }
    
    @UIBinding private var viewModel = PodcastViewModel()
    @ViewLoading private var searchController: UISearchController
    private let inidicator = UIActivityIndicatorView()
    
    private let manager = PodcastManager()
    private var updateTask: Task<Void, Never>?
    
    convenience init() {
        self.init(collectionViewLayout:
            UICollectionViewCompositionalLayout.list(
                using: .init(appearance: .insetGrouped)
            )
        )
        
        title = "Podcasts"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        observe { [unowned self] in self.update() }
    }
    
    private func setup() {
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = dataSource

        searchController = UISearchController(text: $viewModel.searchText)
        
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        inidicator.style = .large
        collectionView.addSubview(inidicator)
        inidicator.center.x = collectionView.center.x
        inidicator.center.y = collectionView.center.y / 2
    }
    
    private func update() {
        updateTask?.cancel()
        inidicator.stopAnimating()
        
        let text = viewModel.searchText
        
        updateTask = Task { @MainActor in
            guard !text.isEmpty else {
                await dataSource.apply(.init())
                return
            }

            // debounce
            try! await Task.sleep(for: .milliseconds(3))

            inidicator.startAnimating()
            defer { inidicator.stopAnimating() }
            
            if let podcasts = try? await manager.search(for: text) {
                var snapshot = NSDiffableDataSourceSnapshot<Int, Podcast>()
                snapshot.appendSections([0])
                snapshot.appendItems(podcasts)
                await dataSource.apply(snapshot)
            }
        }
    }
}
