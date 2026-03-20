import Foundation

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let shoffleCount = count
        guard shoffleCount > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: shoffleCount, to: 1, by: -1)) {
            let distance: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let unSuffledIndex = index(firstUnshuffled, offsetBy: distance)
            swapAt(firstUnshuffled, unSuffledIndex)
        }
    }
}
