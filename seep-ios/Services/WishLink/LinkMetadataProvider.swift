import Foundation
import ImageIO
import LinkPresentation
import UniformTypeIdentifiers

/// 링크 미리보기에 쓰는 메타데이터. 썸네일은 축소한 JPEG 로만 들고 다닌다 (GH-29 R-5, R-7)
struct LinkPreview: Equatable, Codable {
    let link: String
    let title: String?
    let imageData: Data?

    var domain: String {
        WishLinkInput.domain(of: link)
    }
}

protocol LinkMetadataProviding {
    /// 페이지를 기기에서 직접 읽어 제목·대표 이미지를 가져온다. 실패·시간 초과면 nil. completion 은 메인 스레드에서 부른다.
    func fetchPreview(link: String, completion: @escaping (LinkPreview?) -> Void)
}

/// `LPMetadataProvider` 로 페이지를 읽는다. 서버·외부 API 없이 기기에서 바로 요청한다 (GH-29 서버리스 근거).
final class LinkMetadataProvider: LinkMetadataProviding {
    static let timeout: TimeInterval = 10
    /// 56pt 썸네일 @3x
    private static let thumbnailPixelSize = CGSize(width: 168, height: 168)

    func fetchPreview(link: String, completion: @escaping (LinkPreview?) -> Void) {
        guard let url = URL(string: link) else {
            Self.complete(nil, completion: completion)
            return
        }

        // LPMetadataProvider 는 요청 하나에 인스턴스 하나만 쓸 수 있다
        let provider = LPMetadataProvider()
        provider.timeout = Self.timeout
        provider.startFetchingMetadata(for: url) { metadata, error in
            withExtendedLifetime(provider) { }
            guard let metadata, error == nil else {
                Self.complete(nil, completion: completion)
                return
            }

            let title = metadata.title
            guard let imageProvider = metadata.imageProvider ?? metadata.iconProvider,
                  imageProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                Self.complete(LinkPreview(link: link, title: title, imageData: nil), completion: completion)
                return
            }

            imageProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                let imageData = data.flatMap(Self.thumbnailData(from:))
                Self.complete(LinkPreview(link: link, title: title, imageData: imageData), completion: completion)
            }
        }
    }

    private static func complete(_ preview: LinkPreview?, completion: @escaping (LinkPreview?) -> Void) {
        DispatchQueue.main.async {
            completion(preview)
        }
    }

    /// 원본 이미지는 크기가 커서 썸네일 크기로 가운데를 채워 자른 JPEG 만 남긴다 (UIKit 없이 ImageIO·CoreGraphics)
    static func thumbnailData(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let targetSize = thumbnailPixelSize
        // 짧은 변이 썸네일을 덮을 만큼만 먼저 줄여 읽는다
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * 4
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              image.width > 0, image.height > 0 else { return nil }

        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let scale = max(targetSize.width / width, targetSize.height / height)
        let drawSize = CGSize(width: width * scale, height: height * scale)
        let origin = CGPoint(x: (targetSize.width - drawSize.width) / 2, y: (targetSize.height - drawSize.height) / 2)

        guard let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: origin, size: drawSize))
        guard let cropped = context.makeImage() else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cropped, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
