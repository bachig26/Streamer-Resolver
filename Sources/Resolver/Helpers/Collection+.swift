import Foundation

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    subscript(negative i: Int) -> Element {
        if i < 0 {
            return self[index(startIndex, offsetBy: -i)]
        } else {
            return self[index(startIndex, offsetBy: i)]
        }
    }
}
