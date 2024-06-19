import Observation
import Foundation
import UIKitNavigation

extension Observable {
    @MainActor
    func changes<T>(for property: KeyPath<Self, T>) -> AsyncStream<T> {
        AsyncStream { continuation in
            NSObject().observe {
                continuation.yield(self[keyPath: property])
            }
        }
    }
}

// resource
// selector
// mapArray
// indexArray
