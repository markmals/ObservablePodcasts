import UIKit

final class PodcastCell: UIStackView, UIContentView {
    private let nameLabel = UILabel().configure {
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private let creatorLabel = UILabel().configure {
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        $0.lineBreakMode = .byTruncatingTail
    }
    
    private let labelStack = UIStackView().configure {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.distribution = .equalSpacing
        $0.isLayoutMarginsRelativeArrangement = true
        $0.spacing = 5
    }
    
    private let artworkImage = UIImageView().configure {
        $0.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            $0.widthAnchor.constraint(equalToConstant: 88),
            $0.heightAnchor.constraint(equalToConstant: 88)
        ])
    }
    
    init(_ configuration: Podcast) {
        self.configuration = configuration
        super.init()
        
        self.axis = .horizontal
        self.alignment = .center
        self.spacing = 15
        self.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
        }
        
        labelStack.addArrangedSubview(nameLabel)
        labelStack.addArrangedSubview(creatorLabel)
        
        self.addArrangedSubview(artworkImage)
        self.addArrangedSubview(labelStack)
        
        NSLayoutConstraint.activate([
            nameLabel.trailingAnchor.constraint(
                equalTo: labelStack.trailingAnchor,
                constant: -15
            ),
            creatorLabel.trailingAnchor.constraint(
                equalTo: nameLabel.trailingAnchor
            )
        ])
    }
    
    public var configuration: UIContentConfiguration {
        didSet {
            let podcast = configuration as! Podcast
            artworkImage.image = podcast.image
            nameLabel.text = podcast.name
            creatorLabel.text = podcast.creator
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("Unimplemented")
    }
}
