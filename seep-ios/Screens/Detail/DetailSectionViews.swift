import SwiftUI

/// 단계 체크 행 목록 (GH-5, GH-59 R-6). 체크 24pt + 제목 Regular 16, 완료면 `gray4` 취소선. 행 사이 구분선 없음
struct DetailStepsBody: View {
    let steps: [WishStep]
    let onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                Button {
                    onTap(index)
                } label: {
                    HStack(spacing: 10) {
                        (step.isDone ? Assets.Icons.icCheckOn : Assets.Icons.icCheckOff).swiftUIImage
                            .resizable()
                            .foregroundStyle(Color.gray3)
                            .frame(width: 24, height: 24)
                        Text(verbatim: step.title)
                            .font(.appleRegular(size: 16))
                            .foregroundStyle(step.isDone ? Color.gray4 : Color.gray5)
                            .strikethrough(step.isDone, color: .gray4)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(step.isDone ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

/// 모은 돈 본문 (GH-16, GH-59 R-6): 큰 금액 ExtraBold 22 + "/ 목표" · 진행 바 · 남은 금액 문구 · 기록 목록
struct DetailSavingsBody: View {
    let progress: WishSavingProgress
    let savings: [WishSaving]
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text(Strings.Common.wonFormat(AmountFormatter.string(from: progress.savedAmount)))
                .font(.appleExtraBold(size: 22))
                .foregroundStyle(Color.gray5)
             + Text(verbatim: " " + Strings.Detail.Saving.targetFormat(AmountFormatter.string(from: progress.targetAmount)))
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4))
            ThinProgressBar(ratio: progress.ratio)
                .padding(.top, 10)
            message
                .padding(.top, 8)
            if !savings.isEmpty {
                VStack(spacing: 0) {
                    ForEach(savings, id: \.id) { saving in
                        recordRow(saving)
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private var message: some View {
        if progress.isCompleted {
            Text(Strings.Detail.Saving.completed)
                .font(.appleBold(size: 14))
                .foregroundStyle(Color.seepBlue)
        } else {
            let remainingText = Strings.Common.wonFormat(AmountFormatter.string(from: progress.remainingAmount))
            let message = Strings.Detail.Saving.remainingFormat(AmountFormatter.string(from: progress.remainingAmount))
            if let range = message.range(of: remainingText) {
                (Text(verbatim: String(message[..<range.lowerBound])).foregroundStyle(Color.gray5)
                 + Text(verbatim: remainingText).font(.appleBold(size: 14)).foregroundStyle(Color.seepBlue)
                 + Text(verbatim: String(message[range.upperBound...])).foregroundStyle(Color.gray5))
                    .font(.appleRegular(size: 14))
            } else {
                Text(verbatim: message)
                    .font(.appleRegular(size: 14))
                    .foregroundStyle(Color.gray5)
            }
        }
    }

    private func recordRow(_ saving: WishSaving) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: DisplayDate.fixed(saving.createdAt, pattern: "MM.dd"))
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray4)
                .frame(width: 56, alignment: .leading)
            Text(Strings.Detail.Saving.recordFormat(AmountFormatter.string(from: saving.amount)))
                .font(.appleRegular(size: 14))
                .foregroundStyle(Color.gray5)
            Spacer(minLength: 0)
            Button {
                onDelete(saving.id)
            } label: {
                Assets.Icons.icClose.swiftUIImage
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -10)
            .accessibilityLabel(Text(Strings.Detail.Saving.delete))
        }
        .frame(height: 36)
    }
}

/// 상세 링크 줄 (GH-59 R-6): 36pt 썸네일 + 제목 SemiBold 16/24 + 도메인 14/20 `gray4`.
/// 상태 규칙은 GH-29 — 불러오는 중 스켈레톤, 이미지 없음 photo 심볼, 실패 link 심볼 + 안내 문구
struct DetailLinkBody: View {
    let preview: WishLinkPreviewState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                LinkThumbnail(imageData: thumbnailData, placeholderSymbol: placeholderSymbol)
                if isLoading {
                    VStack(alignment: .leading, spacing: 8) {
                        skeletonBar(widthRatio: 0.8)
                        skeletonBar(widthRatio: 0.45)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: titleText)
                            .font(.appleSemiBold(size: 16))
                            .foregroundStyle(Color.gray5)
                            .lineLimit(1)
                            .frame(height: 24)
                        Text(verbatim: subtitleText)
                            .font(.appleRegular(size: 14))
                            .foregroundStyle(Color.gray4)
                            .lineLimit(1)
                            .frame(height: 20)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(Text(Strings.Detail.Link.openAccessibility))
    }

    private var isLoading: Bool {
        if case .loading = preview { return true }
        return false
    }

    private var thumbnailData: Data? {
        if case .loaded(let linkPreview) = preview { return linkPreview.imageData }
        return nil
    }

    private var placeholderSymbol: String? {
        switch preview {
        case .loaded: return "photo"
        case .failed: return "link"
        case .loading, .hidden: return nil
        }
    }

    private var titleText: String {
        switch preview {
        case .loaded(let linkPreview):
            let title = linkPreview.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return title.isEmpty ? linkPreview.domain : title
        case .failed(let domain), .loading(let domain):
            return domain
        case .hidden:
            return ""
        }
    }

    private var subtitleText: String {
        switch preview {
        case .loaded(let linkPreview): return linkPreview.domain
        case .failed: return Strings.Detail.Link.previewFailed
        case .loading, .hidden: return ""
        }
    }

    private func skeletonBar(widthRatio: CGFloat) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray2)
                .frame(width: proxy.size.width * widthRatio, height: 10)
        }
        .frame(height: 10)
    }
}

/// 장소 본문 (GH-31, GH-59 R-6): 장소 이름 SemiBold 16 · 주소 14 `gray4`. 없으면 파란 글자 "＋ 장소 붙이기". 길게 눌러 지우기
struct DetailPlaceBody: View {
    let place: WishPlace?
    let onAdd: () -> Void
    let onDelete: () -> Void

    var body: some View {
        if let place {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: place.name)
                    .font(.appleSemiBold(size: 16))
                    .foregroundStyle(Color.gray5)
                if !place.address.isEmpty {
                    Text(verbatim: place.address)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label {
                        Text(Strings.Detail.Place.delete)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            }
        } else {
            TextActionButton(title: Strings.Detail.Section.placeAdd, action: onAdd)
        }
    }
}

/// 사진 본문 (GH-36, GH-59 R-6): 16:9 사진(라운드 12). 없으면 파란 글자 "＋ 사진 붙이기" 한 줄.
/// 빈 자리는 이룬 싶 탭 상세에만 있다 — 나머지는 작성/수정 문서에서 붙인다 (GH-61 R-9, R-12)
struct DetailPhotoBody: View {
    let photoURL: URL?
    var onAdd: (() -> Void)?

    var body: some View {
        if let image = photoURL.flatMap({ DetailImageDecoder.cgImage(url: $0) }) {
            PhotoFrame(image: image)
        } else if let onAdd {
            // 파일이 없거나 읽지 못하면 빈 상태로 보여준다 (GH-36 R-7)
            TextActionButton(title: Strings.Detail.Photo.add, action: onAdd)
        }
    }
}

/// 16:9로 잘라 보여주는 사진 (상세 사진 섹션·문서 사진 블록)
struct PhotoFrame: View {
    let image: CGImage

    var body: some View {
        Color.gray2
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                // scaledToFill 로 넘친 부분은 clipShape 로 안 보일 뿐 터치는 받는다.
                // 세로로 긴 사진이 위 섹션(일지·링크 등)의 버튼을 덮어 눌리지 않게 막는다 (GH-95)
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement()
            .accessibilityLabel(Text(Strings.Detail.Photo.title))
    }
}
