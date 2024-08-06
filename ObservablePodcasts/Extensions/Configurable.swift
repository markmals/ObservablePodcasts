import Foundation

protocol Configurable: AnyObject {}

extension Configurable {
    func configure(closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

extension NSObject: Configurable {}
