import SwiftUI

/// 적기 탭을 누르면 뜨는 카테고리 시트 (R-6 ~ R-9).
/// 헤드라인 "어떤 싶을 / **적어볼까요?**" + 카테고리 3줄(gray2·라운드 12·높이 72), 마지막 카테고리 줄에 seep-blue 테두리
struct WriteCategorySheet: View {
    let highlightedCategory: Category
    let onSelect: (Category) -> Void

    private let categories: [Category] = [.wantToDo, .wantToGet, .wantToGo]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeadlineText(
                text: Strings.WriteCategorySheet.title,
                boldPart: Strings.WriteCategorySheet.titleBold
            )
            .padding(.top, 24)

            VStack(spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        row(category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ category: Category) -> some View {
        HStack(spacing: 14) {
            category.illustration
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: category.title)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                Text(verbatim: category.writeSheetCTA)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray4)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray3)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(Color.gray2, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if category == highlightedCategory {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.seepBlue, lineWidth: 1.5)
            }
        }
        .accessibilityAddTraits(category == highlightedCategory ? .isSelected : [])
    }
}

/// 두 줄 헤드라인. 1행 Light 22, 굵게 할 부분만 Bold 22 (디자인 시스템 Headline)
struct HeadlineText: View {
    let text: String
    let boldPart: String
    var size: CGFloat = 22

    var body: some View {
        styledText
            .lineSpacing(9)
            .foregroundStyle(Color.gray5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var styledText: Text {
        guard let range = text.range(of: boldPart) else {
            return Text(verbatim: text).font(.appleLight(size: size))
        }
        return Text(verbatim: String(text[..<range.lowerBound])).font(.appleLight(size: size))
            + Text(verbatim: boldPart).font(.appleBold(size: size))
            + Text(verbatim: String(text[range.upperBound...])).font(.appleLight(size: size))
    }
}

extension Category {
    var title: String {
        switch self {
        case .wantToDo: return Strings.commonCategoryWantToDo
        case .wantToGet: return Strings.commonCategoryWantToGet
        case .wantToGo: return Strings.commonCategoryWantToGo
        }
    }

    var writeSheetCTA: String {
        switch self {
        case .wantToDo: return Strings.WriteCategorySheet.ctaWantToDo
        case .wantToGet: return Strings.WriteCategorySheet.ctaWantToGet
        case .wantToGo: return Strings.WriteCategorySheet.ctaWantToGo
        }
    }

    /// 카테고리 대표 3D 일러스트
    var illustration: Image {
        switch self {
        case .wantToDo: return Assets.Images.imgCategoryWantToDo.swiftUIImage
        case .wantToGet: return Assets.Images.imgCategoryWantToGet.swiftUIImage
        case .wantToGo: return Assets.Images.imgCategoryWantToGo.swiftUIImage
        }
    }
}
