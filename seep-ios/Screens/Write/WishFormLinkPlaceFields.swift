import SwiftUI
import ImageIO

// 작성·수정 문서의 링크 미리보기 (GH-29)

/// 링크 미리보기 카드: 썸네일 + 제목 + 도메인 (GH-29 R-3)
struct WishFormLinkPreviewCard: View {
    let preview: WishFormLinkPreview

    var body: some View {
        switch preview {
        case .hidden:
            EmptyView()
        case .loading(let domain):
            card(thumbnail: nil, title: nil, domain: domain, isLoading: true)
        case .loaded(let linkPreview):
            card(
                thumbnail: linkPreview.imageData.flatMap(Self.image(from:)),
                title: linkPreview.title,
                domain: linkPreview.domain,
                isLoading: false
            )
        case .failed(let domain):
            card(thumbnail: nil, title: Strings.Write.Link.previewFailed, domain: domain, isLoading: false)
        }
    }

    private func card(thumbnail: Image?, title: String?, domain: String, isLoading: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.gray2_5)
                if let thumbnail {
                    thumbnail
                        .resizable()
                        .scaledToFill()
                } else if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "link")
                        .foregroundStyle(Color.gray3)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(verbatim: title)
                        .font(.appleSemiBold(size: 14))
                        .foregroundStyle(Color.gray5)
                        .lineLimit(2)
                }
                Text(verbatim: domain)
                    .font(.appleRegular(size: 12))
                    .foregroundStyle(Color.gray4)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
    }

    /// JPEG 데이터 → 이미지 (UIKit 없이 ImageIO 로 만든다)
    static func image(from data: Data) -> Image? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }
}

