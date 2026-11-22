import Foundation

import FirebaseStorage

/// 서버 쪽 위시 사진 `wishPhotos/{uid}/{fileName}` (GH-93 3단계, 설계 §7). Storage 접근은 여기서만 한다(R11)
protocol RemotePhotoStore {
    func upload(fileURL: URL, fileName: String, uid: String) async throws
    /// 서버에 없으면 `RemotePhotoError.notFound`
    func download(fileName: String, uid: String) async throws -> Data
}

enum RemotePhotoError: Error, Equatable {
    case notFound
}

final class FirebaseRemotePhotoStore: RemotePhotoStore {
    /// storage.rules 상한과 같다
    private static let maxSize: Int64 = 5 * 1024 * 1024

    private lazy var storage = Storage.storage()

    func upload(fileURL: URL, fileName: String, uid: String) async throws {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await reference(fileName: fileName, uid: uid).putFileAsync(from: fileURL, metadata: metadata)
    }

    func download(fileName: String, uid: String) async throws -> Data {
        do {
            return try await reference(fileName: fileName, uid: uid).data(maxSize: Self.maxSize)
        } catch let error as NSError where error.domain == StorageErrorDomain && error.code == StorageErrorCode.objectNotFound.rawValue {
            throw RemotePhotoError.notFound
        }
    }

    private func reference(fileName: String, uid: String) -> StorageReference {
        storage.reference(withPath: "wishPhotos/\(uid)/\(fileName)")
    }
}
