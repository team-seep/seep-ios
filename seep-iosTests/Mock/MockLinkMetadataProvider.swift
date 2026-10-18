@testable import seep_ios_dev

/// LinkMetadataProviding 스파이. 기본은 바로(동기) 응답한다. `isDeferred` 면 `complete(at:with:)`로 나중에 응답한다.
final class MockLinkMetadataProvider: LinkMetadataProviding {
    /// nil 이면 실패/시간 초과
    var fetchPreviewResult: LinkPreview?
    var isDeferred = false
    private(set) var fetchedLinks: [String] = []
    private var pendingCompletions: [(LinkPreview?) -> Void] = []

    func fetchPreview(link: String, completion: @escaping (LinkPreview?) -> Void) {
        fetchedLinks.append(link)
        if isDeferred {
            pendingCompletions.append(completion)
        } else {
            completion(fetchPreviewResult)
        }
    }

    func complete(at index: Int, with preview: LinkPreview?) {
        pendingCompletions[index](preview)
    }
}
