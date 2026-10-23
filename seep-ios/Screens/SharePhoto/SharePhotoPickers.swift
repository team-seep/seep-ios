import SwiftUI

/// 이모지 | 사진 전환. 높이 42, 가운데 1pt 구분선, 선택 탭 아래 tennis-green 3pt 막대 (기존 ShareTypeSwitchView)
struct ShareTypeSwitch: View {
    let selected: SharePhotoViewModel.ShareType
    let onSelect: (SharePhotoViewModel.ShareType) -> Void

    var body: some View {
        HStack(spacing: 0) {
            tab(.emoji, title: Strings.sharePhotoEmoji)
            Rectangle()
                .fill(Color.gray2_5)
                .frame(width: 1, height: 30)
            tab(.photo, title: Strings.sharePhotoAlbum)
        }
        .frame(height: SharePhotoLayout.switchHeight)
        .background(Color.gray1)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray2)
                .frame(height: 1)
        }
    }

    private func tab(_ type: SharePhotoViewModel.ShareType, title: String) -> some View {
        Button {
            onSelect(type)
        } label: {
            Text(verbatim: title)
                .font(.appleRegular(size: 16))
                .foregroundStyle(Color.gray5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    if selected == type {
                        Capsule()
                            .fill(Color.tennisGreen)
                            .frame(height: 3)
                            .padding(.horizontal, 12)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected == type ? .isSelected : [])
    }
}

/// 사진 탭 목록. 목록 폭에 따라 3·4·5열, 간격 1. 고른 칸은 검게 덮고 체크를 올린다 (기존 SharePhotoCell)
struct SharePhotoGrid: View {
    let photoIds: [String]
    let selectedPhotoId: String?
    let bottomInset: CGFloat
    let library: PhotoLibraryProviding
    let onSelect: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = SharePhotoLayout.cellSide(containerWidth: proxy.size.width)
            let columns = Array(
                repeating: GridItem(.fixed(side), spacing: SharePhotoLayout.gridSpacing),
                count: SharePhotoLayout.columnCount(containerWidth: proxy.size.width)
            )
            ScrollView {
                LazyVGrid(columns: columns, spacing: SharePhotoLayout.gridSpacing) {
                    ForEach(photoIds, id: \.self) { photoId in
                        Button {
                            onSelect(photoId)
                        } label: {
                            SharePhotoThumbnail(
                                photoId: photoId,
                                side: side,
                                isSelected: photoId == selectedPhotoId,
                                library: library
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, bottomInset)
            }
        }
        .background(Color.gray2)
    }
}

private struct SharePhotoThumbnail: View {
    let photoId: String
    let side: CGFloat
    let isSelected: Bool
    let library: PhotoLibraryProviding

    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?

    var body: some View {
        ZStack {
            Color.gray3
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            }
            if isSelected {
                Color.black.opacity(0.6)
                CheckCircle(isChecked: true)
            }
        }
        .frame(width: side, height: side)
        .clipped()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .task(id: photoId) {
            image = await library.image(for: photoId, maxPixelSize: side * displayScale)
        }
    }
}

/// 이모지 탭 목록. 카테고리 탭 + 8열 그리드. 고른 이모지는 카드에만 쓴다 (기존 ISEmojiView 키보드 대체)
struct ShareEmojiGrid: View {
    let bottomInset: CGFloat
    let onSelect: (String) -> Void

    @State private var sectionId = ShareEmojiCatalog.sections[0].id

    private var section: ShareEmojiCatalog.Section {
        ShareEmojiCatalog.sections.first { $0.id == sectionId } ?? ShareEmojiCatalog.sections[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 6) {
                    ForEach(section.emojis, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                        } label: {
                            Text(verbatim: emoji)
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            HStack(spacing: 0) {
                ForEach(ShareEmojiCatalog.sections) { item in
                    Button {
                        sectionId = item.id
                    } label: {
                        Text(verbatim: item.symbol)
                            .font(.system(size: 20))
                            .opacity(item.id == sectionId ? 1 : 0.4)
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(item.id == sectionId ? .isSelected : [])
                }
            }
            .padding(.bottom, bottomInset)
        }
        .background(Color.gray2)
    }
}
