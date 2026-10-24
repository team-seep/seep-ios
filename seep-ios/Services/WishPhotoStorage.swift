import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum WishPhotoStorageError: LocalizedError {
    case invalidImage
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return Strings.Detail.Photo.Error.invalidImage
        case .writeFailed:
            return Strings.Detail.Photo.Error.writeFailed
        }
    }
}

/// 위시 사진 파일 저장소 (GH-36). 앱 컨테이너 `Application Support/WishPhotos/`에 JPEG로 두고 DB에는 파일 이름만 저장한다.
/// 위젯에는 사진을 보여주지 않아 App Group이 아니라 앱 컨테이너에 둔다.
protocol WishPhotoStorage {
    /// 긴 변 1080px 이하 JPEG(품질 0.8)로 줄여 `{위시id}-{uuid}.jpg`로 저장하고 파일 이름을 돌려준다.
    /// 디코딩·인코딩은 메인 스레드 밖에서 하고, 결과는 메인 스레드로 돌려준다 (R-3).
    func savePhoto(imageData: Data, wishId: String, completion: @escaping (Result<String, WishPhotoStorageError>) -> Void)

    /// 파일이 실제로 있을 때만 URL을 돌려준다. 이름만 남고 파일이 없으면(백업 복원 등) nil (R-7).
    func photoURL(fileName: String) -> URL?

    func deletePhoto(fileName: String)

    /// 위시를 지울 때 그 위시의 사진 파일(`{위시id}-*`)을 모두 지운다 (R-5).
    func deletePhotos(wishId: String)

    /// 셀 크기에 맞춘 썸네일을 백그라운드에서 디코딩해 메인 스레드로 돌려준다. 실패하면 nil (R-8).
    func loadThumbnail(fileName: String, maxPixelSize: Int, completion: @escaping (CGImage?) -> Void)
}

final class WishPhotoStorageImpl: WishPhotoStorage {
    enum Config {
        static let maxPixelSize = 1080
        static let compressionQuality: CGFloat = 0.8
        static let directoryName = "WishPhotos"
    }

    static let shared = WishPhotoStorageImpl()

    private let directory: URL
    private let fileManager: FileManager
    private let workQueue = DispatchQueue(label: "macgongmon.seep.wish-photo-storage", qos: .userInitiated)
    private let callbackQueue: DispatchQueue
    private let thumbnailCache = NSCache<NSString, CGImage>()

    init(
        directory: URL? = nil,
        fileManager: FileManager = .default,
        callbackQueue: DispatchQueue = .main
    ) {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.directory = directory ?? applicationSupport.appendingPathComponent(Config.directoryName, isDirectory: true)
        self.fileManager = fileManager
        self.callbackQueue = callbackQueue
        thumbnailCache.countLimit = 100
    }

    func savePhoto(imageData: Data, wishId: String, completion: @escaping (Result<String, WishPhotoStorageError>) -> Void) {
        workQueue.async { [weak self] in
            guard let self else { return }
            let result = self.writePhoto(imageData: imageData, wishId: wishId)
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    func photoURL(fileName: String) -> URL? {
        guard let url = fileURL(fileName: fileName),
              fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func deletePhoto(fileName: String) {
        guard let url = fileURL(fileName: fileName) else { return }
        try? fileManager.removeItem(at: url)
        // NSCache 는 키 목록을 주지 않고 셀 크기는 화면마다 달라 전체를 비운다(파일을 지울 때만이라 드물다)
        thumbnailCache.removeAllObjects()
    }

    func deletePhotos(wishId: String) {
        guard !wishId.isEmpty,
              let fileNames = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        fileNames
            .filter { $0.hasPrefix(wishId + "-") }
            .forEach(deletePhoto(fileName:))
    }

    func loadThumbnail(fileName: String, maxPixelSize: Int, completion: @escaping (CGImage?) -> Void) {
        let key = cacheKey(fileName: fileName, maxPixelSize: maxPixelSize)
        if let cached = thumbnailCache.object(forKey: key) {
            completion(cached)
            return
        }
        guard let url = photoURL(fileName: fileName) else {
            completion(nil)
            return
        }

        workQueue.async { [weak self] in
            guard let self else { return }
            let image = CGImageSourceCreateWithURL(url as CFURL, nil)
                .flatMap { Self.downsample(source: $0, maxPixelSize: maxPixelSize) }
            if let image {
                self.thumbnailCache.setObject(image, forKey: key)
            }
            self.callbackQueue.async {
                completion(image)
            }
        }
    }

    private func writePhoto(imageData: Data, wishId: String) -> Result<String, WishPhotoStorageError> {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = Self.downsample(source: source, maxPixelSize: Config.maxPixelSize) else {
            return .failure(.invalidImage)
        }

        let fileName = "\(wishId)-\(UUID().uuidString).jpg"
        guard let url = fileURL(fileName: fileName) else { return .failure(.writeFailed) }

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return .failure(.writeFailed)
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            return .failure(.writeFailed)
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: Config.compressionQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            try? fileManager.removeItem(at: url)
            return .failure(.writeFailed)
        }
        return .success(fileName)
    }

    /// 원본 전체를 디코딩하지 않고 긴 변 `maxPixelSize` 이하로 줄인다. EXIF 방향도 반영한다.
    private static func downsample(source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }

    /// 파일 이름에 경로 구분자가 있으면 저장 폴더 밖을 가리킬 수 있어 거른다.
    private func fileURL(fileName: String) -> URL? {
        guard !fileName.isEmpty, !fileName.contains("/") else { return nil }
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    private func cacheKey(fileName: String, maxPixelSize: Int) -> NSString {
        return "\(fileName)@\(maxPixelSize)" as NSString
    }
}
