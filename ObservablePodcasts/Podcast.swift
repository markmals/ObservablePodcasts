import UIKit

struct Podcast: Identifiable, Hashable, UIContentConfiguration {
    let id: UInt
    let image: UIImage?
    let name: String
    let creator: String
    
    func makeContentView() -> any UIView & UIContentView {
        PodcastCell(self)
    }
    
    func updated(for state: any UIConfigurationState) -> Self {
        self
    }
}
