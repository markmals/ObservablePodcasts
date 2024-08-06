import UIKit
import UIKitNavigation

extension UISearchBar {
    convenience init(frame: CGRect = .zero, text: UIBinding<String>) {
        self.init(frame: frame)
        self.bind(to: text)
    }
    
    public func bind(to text: UIBinding<String>) {
        self.searchTextField.bind(to: text)
    }
}

extension UISearchController {
    convenience init(text: UIBinding<String>) {
        self.init()
        self.bind(to: text)
    }
    
    public func bind(to text: UIBinding<String>) {
        self.searchBar.bind(to: text)
    }
}
