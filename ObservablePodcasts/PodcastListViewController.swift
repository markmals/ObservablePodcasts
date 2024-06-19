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
    
    private let manager = PodcastManager()
    private var podcastFetchTask: Task<Void, Never>?
    
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
        
        observe { [weak self] in
            guard let self else { return }
            self.podcastFetchTask?.cancel()
            let text = self.viewModel.searchText
            
            self.podcastFetchTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(3))
                if let podcasts = try? await self.manager.search(for: text) {
                    var snapshot = NSDiffableDataSourceSnapshot<Int, Podcast>()
                    snapshot.appendSections([0])
                    snapshot.appendItems(podcasts)
                    await self.dataSource.apply(snapshot)
                }
            }
        }
    }
}
