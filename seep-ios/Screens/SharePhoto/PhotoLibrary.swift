import Foundation
import CoreGraphics
import ImageIO
import Photos
import UniformTypeIdentifiers

/// 앨범 접근 권한. `.limited`(일부 사진만 허용)도 고른 사진은 쓸 수 있어 허용으로 본다
enum PhotoLibraryAuthorization: Equatable {
    case authorized
    case notDetermined
    case denied
}

enum PhotoLibraryError: Error, Equatable {
    case saveFailed
}

/// 사진 공유 화면이 쓰는 앨범 기능. ViewModel 은 사진을 id 로만 다루고, 이미지는 View 가 이 protocol 로 읽는다
protocol PhotoLibraryProviding {
    func authorizationStatus() -> PhotoLibraryAuthorization
    func requestAuthorization() async -> PhotoLibraryAuthorization
    /// 최근 사진부터 사진(이미지) id 목록
    func fetchPhotoIds() -> [String]
    /// 긴 변이 `maxPixelSize`를 넘지 않게 줄인 이미지
    func image(for photoId: String, maxPixelSize: CGFloat) async -> CGImage?
    func savePNG(_ data: Data) async throws
}

/// Photos 프레임워크 구현. UIImage 를 쓰지 않으려고 원본 데이터를 받아 ImageIO 로 줄인다
final class PhotoLibrary: PhotoLibraryProviding {
    func authorizationStatus() -> PhotoLibraryAuthorization {
        Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAuthorization() async -> PhotoLibraryAuthorization {
        Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    func fetchPhotoIds() -> [String] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var ids: [String] = []
        ids.reserveCapacity(assets.count)
        assets.enumerateObjects { asset, _, _ in
            ids.append(asset.localIdentifier)
        }
        return ids
    }

    func image(for photoId: String, maxPixelSize: CGFloat) async -> CGImage? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil).firstObject else {
            return nil
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current

        let data: Data? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
        guard let data else { return nil }
        return Self.thumbnail(from: data, maxPixelSize: maxPixelSize)
    }

    func savePNG(_ data: Data) async throws {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
        } catch {
            throw PhotoLibraryError.saveFailed
        }
    }

    /// EXIF 방향을 반영해 줄인 이미지를 만든다
    static func thumbnail(from data: Data, maxPixelSize: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelSize.rounded(.up)))
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoLibraryAuthorization {
        switch status {
        case .authorized, .limited:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}

/// 공유 카드 이미지를 앨범에 넣을 PNG 로 바꾼다
enum ShareImageEncoder {
    static func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
