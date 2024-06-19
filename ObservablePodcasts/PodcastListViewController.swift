import UIKit
import Observation
import UIKitNavigation
import AsyncAlgorithms

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
    
    private let manager = PodcastManager()
    private var currentSearch: Task<Void, Never>?
    
    convenience init() {
        self.init(collectionViewLayout:
            UICollectionViewCompositionalLayout.list(
                using: .init(appearance: .insetGrouped)
            )
        )
        
        self.title = "Podcasts"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(text: $viewModel.searchText)
        
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = dataSource
        
        let searchTerms = self.viewModel
            .changes(for: \.searchText, in: self)
            .debounce(for: .milliseconds(300))
        
        Task { @MainActor [unowned self] in
            for await term in searchTerms {
                self.currentSearch?.cancel()
                self.currentSearch = Task {
                    if let podcasts = try? await self.manager.search(for: term) {
                        var snapshot = NSDiffableDataSourceSnapshot<Int, Podcast>()
                        snapshot.appendSections([0])
                        snapshot.appendItems(podcasts)
                        await self.dataSource.apply(snapshot)
                    }
                }
            }
        }
    }
}
