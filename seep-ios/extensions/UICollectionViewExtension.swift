import UIKit

extension UICollectionView {
    func deselectAllItems(animated: Bool) {
        guard let selectedItems = indexPathsForSelectedItems else { return }
        
        for indexPath in selectedItems {
            deselectItem(at: indexPath, animated: animated)
        }
    }
}
