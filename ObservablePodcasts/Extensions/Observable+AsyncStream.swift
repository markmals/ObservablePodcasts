import Observation
import Foundation
import UIKitNavigation

extension Observable {
    @MainActor
    func changes<T>(for property: KeyPath<Self, T>, in object: NSObject = .init()) -> AsyncStream<T> {
        AsyncStream { continuation in
            object.observe {
                continuation.yield(self[keyPath: property])
            }
        }
    }
}

extension Observable where Self: NSObject {
    @MainActor
    func changes<T>(for property: KeyPath<Self, T>) -> AsyncStream<T> {
        changes(for: property, in: self)
    }
}

// resource
// selector
// mapArray
// indexArray
