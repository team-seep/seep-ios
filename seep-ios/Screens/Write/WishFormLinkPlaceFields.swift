import SwiftUI
import ImageIO
import MapKit

// 작성·수정 폼의 링크(GH-29)·장소(GH-31) 칸

/// 링크 칸 + 붙여넣기 + 미리보기 (GH-29 R-1 ~ R-3, R-6). 갖고 싶어요에서만
struct WishFormLinkField: View {
    let text: String
    let error: String?
    let preview: WishFormLinkPreview
    let focus: FocusState<WishFormField?>.Binding
    let onChange: (String) -> Void
    let onPaste: (String) -> Void

    var body: some View {
        let isFocused = focus.wrappedValue == .link
        VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(
                icon: Image(systemName: "link"),
                title: Strings.Write.Link.title,
                optional: Strings.Write.Link.optional,
                isFocused: isFocused
            )
            WishFormFieldBox(isFocused: isFocused) {
                HStack(spacing: 8) {
                    TextField(Strings.Write.Link.placeholder, text: Binding(get: { text }, set: onChange))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.appleRegular(size: 16))
                        .foregroundStyle(Color.gray5)
                        .focused(focus, equals: .link)
                        .accessibilityLabel(Text(Strings.Write.Link.title))
                    // 앱이 en 로컬라이즈만 있어 라벨은 영어로 그려진다. 한글 화면에 섞이지 않게 아이콘만 쓴다 (레거시와 같음)
                    PasteButton(payloadType: String.self) { strings in
                        guard let pasted = strings.first else { return }
                        Task { @MainActor in onPaste(pasted) }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.capsule)
                    .tint(Color.seepBlue)
                }
            }
            if let error {
                Text(verbatim: error)
                    .font(.appleMedium(size: 12))
                    .foregroundStyle(Color.optionRed)
            }
            WishFormLinkPreviewCard(preview: preview)
        }
    }
}

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

/// 장소 (GH-31 R-2, R-4). 작성의 가고 싶어요에서만. 플레이스홀더 또는 지도 미리보기 카드
struct WishFormPlaceField: View {
    let place: WishPlace?
    let emoji: String
    let onTapPlace: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WishFormHeader(icon: Image(systemName: "mappin.and.ellipse"), title: Strings.Detail.Place.title) {
                if place != nil {
                    Button(action: onTapPlace) {
                        Text(Strings.Detail.Place.change)
                            .font(.appleMedium(size: 14))
                            .foregroundStyle(Color.seepBlue)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 20)
            if let place {
                card(place)
            } else {
                Button(action: onTapPlace) {
                    WishFormFieldBox(minHeight: 50) {
                        Text(Strings.Detail.Place.placeholder)
                            .font(.appleRegular(size: 16))
                            .foregroundStyle(Color.gray3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func card(_ place: WishPlace) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        return VStack(alignment: .leading, spacing: 0) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1_200,
                longitudinalMeters: 1_200
            )), interactionModes: []) {
                Annotation("", coordinate: coordinate, anchor: .bottom) {
                    Text(verbatim: emoji.isEmpty ? "📍" : emoji)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(Color.gray1, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 140)
            .id("\(place.latitude),\(place.longitude)")
            .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: place.name)
                    .font(.appleBold(size: 16))
                    .foregroundStyle(Color.gray5)
                    .lineLimit(2)
                if !place.address.isEmpty {
                    Text(verbatim: place.address)
                        .font(.appleRegular(size: 14))
                        .foregroundStyle(Color.gray4)
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .background(Color.gray2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(Strings.WishForm.placeDelete, systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
