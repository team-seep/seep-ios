import Foundation
import LinkPresentation
import UIKit

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
                  imageProvider.canLoadObject(ofClass: UIImage.self) else {
                Self.complete(LinkPreview(link: link, title: title, imageData: nil), completion: completion)
                return
            }

            imageProvider.loadObject(ofClass: UIImage.self) { object, _ in
                let imageData = (object as? UIImage).flatMap(Self.thumbnailData(from:))
                Self.complete(LinkPreview(link: link, title: title, imageData: imageData), completion: completion)
            }
        }
    }

    private static func complete(_ preview: LinkPreview?, completion: @escaping (LinkPreview?) -> Void) {
        DispatchQueue.main.async {
            completion(preview)
        }
    }

    /// 원본 이미지는 크기가 커서 썸네일 크기로 가운데를 채워 자른 JPEG 만 남긴다
    private static func thumbnailData(from image: UIImage) -> Data? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let targetSize = thumbnailPixelSize
        let scale = max(targetSize.width / image.size.width, targetSize.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (targetSize.width - drawSize.width) / 2, y: (targetSize.height - drawSize.height) / 2)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.jpegData(withCompressionQuality: 0.8) { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }
}
