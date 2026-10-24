import SwiftUI
import ImageIO

extension DdayTone {
    /// 상세 D-day 줄·상단 바의 글자색 (GH-59 R-3). 지난 날 보라 · 0~7일 빨강 · 8~30일 초록 · 그 밖 파랑
    var color: Color {
        switch self {
        case .past:
            return .optionPurple
        case .urgent:
            return .optionRed
        case .soon:
            return .ddayGreenText
        case .later:
            return .ddayBlueText
        }
    }
}

/// 문서 안의 파란 글자 버튼 (GH-59 R-6·R-8). "파란 글자가 있는 곳만 누른다" — 보기 전용 영역에는 쓰지 않는다 (R-7).
/// 글자는 줄 높이에 맞추고 터치 영역만 44pt로 넓힌다
struct TextActionButton: View {
    let title: String
    var font: Font = .appleMedium(size: 14)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(font)
                .foregroundStyle(Color.seepBlue)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 문서 섹션: 얇은 제목(`gray4`) + 선택 숫자(`gray5` Bold) + 선택 액션(파란 글자) + 내용 (GH-59 R-6).
/// 카드·구분선 없이 섹션 사이 40pt 여백으로 나눈다(간격은 상세 본문 스택이 준다)
struct DocumentSection<Content: View>: View {
    let title: String
    var count: String?
    var actionTitle: String?
    var action: () -> Void = {}
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(verbatim: title)
                    .font(.appleMedium(size: 14))
                    .foregroundStyle(Color.gray4)
                if let count {
                    Text(verbatim: count)
                        .font(.appleBold(size: 14))
                        .foregroundStyle(Color.gray5)
                }
                Spacer(minLength: 12)
                if let actionTitle {
                    TextActionButton(title: actionTitle, action: action)
                }
            }
            .frame(height: 22)
            .accessibilityElement(children: .combine)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 진행 바. `gray2-5` 트랙 위 `tennis-green` 채움, 높이 4·양 끝 둥글게 (StepProgressBar 와 같음)
struct ThinProgressBar: View {
    let ratio: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray2_5)
                Capsule()
                    .fill(Color.tennisGreen)
                    .frame(width: proxy.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

/// 파일·데이터의 이미지를 UIKit 없이(ImageIO) 읽어 그린다. 읽지 못하면 nil
enum DetailImageDecoder {
    static func cgImage(data: Data) -> CGImage? {
        cgImage(data: data, maxPixelSize: 400)
    }

    static func cgImage(data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return thumbnail(source: source, maxPixelSize: maxPixelSize)
    }

    static func cgImage(url: URL, maxPixelSize: Int = 1600) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return thumbnail(source: source, maxPixelSize: maxPixelSize)
    }

    private static func thumbnail(source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

/// 링크 미리보기 썸네일 (GH-29 규칙). `gray2` 칸 위에 이미지(aspectFill) 또는 `gray3` 심볼, 불러오는 중은 빈 칸
struct LinkThumbnail: View {
    let imageData: Data?
    let placeholderSymbol: String?
    var size: CGFloat = 36
    var cornerRadius: CGFloat = 8
    var symbolSize: CGFloat = 18

    var body: some View {
        ZStack {
            Color.gray2
            if let image = imageData.flatMap(DetailImageDecoder.cgImage(data:)) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            } else if let placeholderSymbol {
                Image(systemName: placeholderSymbol)
                    .font(.system(size: symbolSize))
                    .foregroundStyle(Color.gray3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }
}
