import Foundation
import CoreGraphics

@testable import seep_ios

/// WishPhotoStorage 스파이. 파일을 실제로 쓰지 않고 "있는 파일 이름" 집합으로 흉내 낸다. 완료 콜백은 바로(동기로) 부른다.
final class MockWishPhotoStorage: WishPhotoStorage {
    /// 실제로 있는 것으로 볼 파일 이름
    var existingFileNames: Set<String> = []
    var savePhotoResult: Result<String, WishPhotoStorageError> = .success("wish-1-new.jpg")
    var thumbnailResult: CGImage?
    private(set) var savePhotoCalls: [(imageData: Data, wishId: String)] = []
    private(set) var deletedFileNames: [String] = []
    private(set) var deletePhotosCalledWishIds: [String] = []
    private(set) var loadThumbnailCalls: [(fileName: String, maxPixelSize: Int)] = []

    func savePhoto(imageData: Data, wishId: String, completion: @escaping (Result<String, WishPhotoStorageError>) -> Void) {
        savePhotoCalls.append((imageData, wishId))
        if case .success(let fileName) = savePhotoResult {
            existingFileNames.insert(fileName)
        }
        completion(savePhotoResult)
    }

    func photoURL(fileName: String) -> URL? {
        guard existingFileNames.contains(fileName) else { return nil }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }

    func deletePhoto(fileName: String) {
        deletedFileNames.append(fileName)
        existingFileNames.remove(fileName)
    }

    func deletePhotos(wishId: String) {
        deletePhotosCalledWishIds.append(wishId)
    }

    func loadThumbnail(fileName: String, maxPixelSize: Int, completion: @escaping (CGImage?) -> Void) {
        loadThumbnailCalls.append((fileName, maxPixelSize))
        completion(thumbnailResult)
    }
}
