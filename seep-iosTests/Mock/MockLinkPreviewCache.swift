@testable import seep_ios_dev

/// LinkPreviewCaching 스파이. 메모리에만 둔다.
final class MockLinkPreviewCache: LinkPreviewCaching {
    var previews: [String: LinkPreview] = [:]
    private(set) var savedWishIds: [String] = []
    private(set) var removedWishIds: [String] = []

    func preview(wishId: String) -> LinkPreview? {
        return previews[wishId]
    }

    func save(_ preview: LinkPreview, wishId: String) {
        savedWishIds.append(wishId)
        previews[wishId] = preview
    }

    func remove(wishId: String) {
        removedWishIds.append(wishId)
        previews[wishId] = nil
    }
}
