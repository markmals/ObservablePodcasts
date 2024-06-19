import UIKit

final class PodcastCell: UIStackView, UIContentView {
    private let nameLabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let creatorLabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let labelStack = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        stack.isLayoutMarginsRelativeArrangement = true
        stack.spacing = 5
        return stack
    }()
    
    private let artworkImage = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            image.widthAnchor.constraint(equalToConstant: 88),
            image.heightAnchor.constraint(equalToConstant: 88)
        ])
        
        return image
    }()
    
    init(_ configuration: Podcast) {
        self.configuration = configuration
        super.init(frame: .zero)
        
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
