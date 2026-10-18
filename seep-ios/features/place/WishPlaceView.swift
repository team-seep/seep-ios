import UIKit
import Combine
import MapKit

import SnapKit

/// 위시 상세·작성의 "장소" 섹션 (GH-31 R-2, R-4). 헤더(아이콘·라벨·바꾸기) + 플레이스홀더 또는 장소 카드(지도 미리보기·이름·주소).
/// 접히면 높이 0 이 되도록 위쪽 간격(26)까지 이 뷰가 갖는다.
final class WishPlaceView: BaseView {
    private enum Layout {
        static let topSpacing: CGFloat = 26
        static let placeholderHeight: CGFloat = 50
        static let mapHeight: CGFloat = 140
        static let cardInset: CGFloat = 16
        /// 미리보기 지도 반경(m)
        static let previewDistance: CLLocationDistance = 1_200
    }

    /// 플레이스홀더·"바꾸기" 탭
    let tapPlacePublisher = PassthroughSubject<Void, Never>()
    /// 카드 길게 누르기 → "장소 지우기"
    let deletePlacePublisher = PassthroughSubject<Void, Never>()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let spacerView = UIView()

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.and.ellipse")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        label.text = Strings.Detail.Place.title
        return label
    }()

    private let changeButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Place.change, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        return button
    }()

    private let placeholderButton: UIButton = {
        let button = UIButton()
        button.contentHorizontalAlignment = .leading
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        // 날짜·제목 입력칸(TextInputField)과 같은 모양
        configuration.background.backgroundColor = .gray2
        configuration.background.cornerRadius = 6
        configuration.cornerStyle = .fixed
        button.configuration = configuration
        button.configuration?.attributedTitle = AttributedString(
            Strings.Detail.Place.placeholder,
            attributes: .init([.font: UIFont.appleRegular(size: 16) as Any, .foregroundColor: UIColor.gray3])
        )
        return button
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityTraits = .staticText
        return view
    }()

    private let mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .gray2_5
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 16)
        label.textColor = .gray5
        label.numberOfLines = 2
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        label.numberOfLines = 2
        return label
    }()

    private var place: WishPlace?
    private var isCollapsed = false
    private var emoji: String = WishPlaceViewModel.fallbackEmoji
    private var snapshotter: MKMapSnapshotter?
    private var snapshotKey: String?

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel, changeButton])
        cardView.addSubViews([mapImageView, nameLabel, addressLabel])
        [spacerView, headerView, placeholderButton, cardView].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        addSubview(stackView)

        placeholderButton.addTarget(self, action: #selector(didTapPlace), for: .touchUpInside)
        changeButton.addTarget(self, action: #selector(didTapPlace), for: .touchUpInside)
        cardView.addInteraction(UIContextMenuInteraction(delegate: self))
        bind(place: nil)
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        spacerView.snp.makeConstraints {
            $0.height.equalTo(Layout.topSpacing)
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }

        changeButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.height.equalTo(44)
        }

        placeholderButton.snp.makeConstraints {
            $0.height.equalTo(Layout.placeholderHeight)
        }

        mapImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.mapHeight)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(mapImageView.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(Layout.cardInset)
            $0.bottom.equalToSuperview().inset(14)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 미리보기 크기는 화면이 아니라 실제 카드 폭을 따른다 (폴더블·넓은 화면)
        updateSnapshotIfNeeded()
    }

    /// 가고 싶어요가 아니면 접는다 (R-1)
    func setCollapsed(_ isCollapsed: Bool) {
        self.isCollapsed = isCollapsed
        spacerView.isHidden = isCollapsed
        headerView.isHidden = isCollapsed
        placeholderButton.isHidden = isCollapsed || place != nil
        cardView.isHidden = isCollapsed || place == nil
    }

    func bind(place: WishPlace?) {
        self.place = place
        changeButton.isHidden = place == nil
        nameLabel.text = place?.name
        addressLabel.text = place?.address
        cardView.accessibilityLabel = [place?.name, place?.address].compactMap { $0 }.joined(separator: ", ")
        setCollapsed(isCollapsed)
        snapshotKey = nil
        mapImageView.image = nil
        setNeedsLayout()
    }

    func bind(emoji: String) {
        guard self.emoji != emoji else { return }
        self.emoji = emoji
        snapshotKey = nil
        setNeedsLayout()
    }

    private func updateSnapshotIfNeeded() {
        guard let place, !cardView.isHidden else { return }
        let size = mapImageView.bounds.size
        guard size.width > 0, size.height > 0 else { return }

        let key = "\(place.latitude),\(place.longitude),\(emoji),\(size.width)x\(size.height)"
        guard key != snapshotKey else { return }
        snapshotKey = key

        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: Layout.previewDistance,
            longitudinalMeters: Layout.previewDistance
        )
        options.size = size
        options.traitCollection = traitCollection

        snapshotter?.cancel()
        let snapshotter = MKMapSnapshotter(options: options)
        self.snapshotter = snapshotter
        let pinImage = EmojiPinImage.make(emoji: emoji, isSelected: true)
        snapshotter.start(with: .main) { [weak self] snapshot, _ in
            guard let self, let snapshot, self.snapshotKey == key else { return }
            self.mapImageView.image = Self.draw(pin: pinImage, at: snapshot.point(for: coordinate), on: snapshot.image)
        }
    }

    private static func draw(pin: UIImage, at point: CGPoint, on image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            // 핀 꼬리 끝이 좌표에 오도록 아래쪽 가운데를 맞춘다
            pin.draw(at: CGPoint(x: point.x - pin.size.width / 2, y: point.y - pin.size.height))
        }
    }

    @objc private func didTapPlace() {
        tapPlacePublisher.send(())
    }
}

extension WishPlaceView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard place != nil else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let deleteAction = UIAction(
                title: Strings.Detail.Place.delete,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.deletePlacePublisher.send(())
            }
            return UIMenu(children: [deleteAction])
        }
    }
}
