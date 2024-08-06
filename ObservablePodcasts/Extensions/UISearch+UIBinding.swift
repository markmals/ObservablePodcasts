import UIKit
import UIKitNavigation

extension UISearchBar {
    convenience init(frame: CGRect = .zero, text: UIBinding<String>) {
        self.init(frame: frame)
        self.searchTextField.bind(text: text)
    }
    
    public func bind(text: UIBinding<String>) {
        self.searchTextField.bind(text: text)
    }
}

extension UISearchController {
    convenience init(text: UIBinding<String>) {
        self.init()
        self.searchBar.bind(text: text)
    }
}
