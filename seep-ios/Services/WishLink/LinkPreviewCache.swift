import Foundation

protocol LinkPreviewCaching {
    func preview(wishId: String) -> LinkPreview?
    func save(_ preview: LinkPreview, wishId: String)
    func remove(wishId: String)
}

/// 상세에서 불러온 링크 미리보기를 위시 id 별 파일로 앱 Caches 에 둔다 (GH-29 R-5).
/// DB 에는 링크 문자열만 저장하고(R-7), 시스템이 Caches 를 비워도 다시 불러오면 되므로 캐시로 충분하다.
final class LinkPreviewCache: LinkPreviewCaching {
    static let shared = LinkPreviewCache()

    private let directory: URL?
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("wish-link-preview", isDirectory: true)
    }

    func preview(wishId: String) -> LinkPreview? {
        guard let fileURL = fileURL(wishId: wishId),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(LinkPreview.self, from: data)
    }

    func save(_ preview: LinkPreview, wishId: String) {
        guard let directory, let fileURL = fileURL(wishId: wishId),
              let data = try? JSONEncoder().encode(preview) else { return }
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    func remove(wishId: String) {
        guard let fileURL = fileURL(wishId: wishId) else { return }
        try? fileManager.removeItem(at: fileURL)
    }

    private func fileURL(wishId: String) -> URL? {
        // 위시 id 는 UUID 지만, 경로 구분자가 섞여도 디렉터리를 벗어나지 않게 한다
        let fileName = wishId.replacingOccurrences(of: "/", with: "_")
        return directory?.appendingPathComponent("\(fileName).json")
    }
}
