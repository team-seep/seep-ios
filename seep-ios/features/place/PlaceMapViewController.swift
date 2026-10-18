import UIKit
import Combine
import MapKit

import CombineCocoa
import SnapKit

/// "가고 싶은 곳 지도" (GH-31 R-6~R-9). 위치 권한을 쓰지 않는다 — 현재 위치 표시 없음.
final class PlaceMapViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let headerHeight: CGFloat = 50
        static let horizontalInset: CGFloat = 20
        static let cardHeight: CGFloat = 88
        /// 핀이 하나뿐일 때 보여줄 반경(m)
        static let singlePinDistance: CLLocationDistance = 3_000
    }

    private let viewModel: PlaceMapViewModel

    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icChevronBack.image, for: .normal)
        button.accessibilityLabel = Strings.PlaceMap.back
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleBold(size: 17)
        label.textColor = .gray5
        label.textAlignment = .center
        label.text = Strings.PlaceMap.title
        return label
    }()

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.register(EmojiAnnotationView.self, forAnnotationViewWithReuseIdentifier: EmojiAnnotationView.reuseId)
        return mapView
    }()

    private let countLabel: PaddingLabel = {
        let label = PaddingLabel(topInset: 8, bottomInset: 8, leftInset: 14, rightInset: 14)
        label.backgroundColor = .white
        label.layer.cornerRadius = 17
        label.layer.masksToBounds = true
        return label
    }()

    private let emptyLabel: PaddingLabel = {
        let label = PaddingLabel(topInset: 14, bottomInset: 14, leftInset: 20, rightInset: 20)
        label.backgroundColor = .white
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.font = .appleMedium(size: 15)
        label.textColor = .gray5
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = Strings.PlaceMap.empty
        label.isHidden = true
        return label
    }()

    private let cardView: PlaceMapWishCardView = {
        let view = PlaceMapWishCardView()
        view.isHidden = true
        return view
    }()

    init(viewModel: PlaceMapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.viewWillAppear.send(())
    }

    private func setupUI() {
        view.backgroundColor = .white
        mapView.delegate = self
        view.addSubViews([mapView, backButton, titleLabel, countLabel, emptyLabel, cardView])

        backButton.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(3)
            $0.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(backButton)
            $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
        }

        mapView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.headerHeight)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(Layout.horizontalInset)
            $0.top.equalTo(mapView).offset(16)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(mapView)
            $0.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(Layout.horizontalInset)
            $0.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-Layout.horizontalInset)
        }

        cardView.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(Layout.horizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(Layout.cardHeight)
        }
    }

    private func bind() {
        backButton.tapPublisher
            .subscribe(viewModel.input.didTapBack)
            .store(in: &cancellables)

        cardView.controlEventPublisher(for: .touchUpInside)
            .subscribe(viewModel.input.didTapCard)
            .store(in: &cancellables)

        viewModel.output.wishes
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, wishes: [Wish]) in
                owner.updateAnnotations(wishes: wishes)
            }
            .store(in: &cancellables)

        viewModel.output.count
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, count: Int) in
                owner.bindCount(count)
            }
            .store(in: &cancellables)

        viewModel.output.isEmpty
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, isEmpty: Bool) in
                owner.emptyLabel.isHidden = !isEmpty
            }
            .store(in: &cancellables)

        viewModel.output.selectedWish
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, wish: Wish?) in
                owner.bindSelectedWish(wish)
            }
            .store(in: &cancellables)

        viewModel.output.fitAllPins
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, wishes: [Wish]) in
                owner.fitAllPins(wishes: wishes)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: PlaceMapViewController, route: PlaceMapViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func bindCount(_ count: Int) {
        let text = Strings.PlaceMap.countFormat(count)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleMedium(size: 14) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttributes(
            [.font: UIFont.appleBold(size: 14) as Any, .foregroundColor: UIColor.seepBlue],
            range: (text as NSString).range(of: "\(count)", options: .backwards)
        )
        countLabel.attributedText = attributedText
        countLabel.accessibilityLabel = text
        countLabel.isHidden = count == 0
    }

    private func updateAnnotations(wishes: [Wish]) {
        let annotations = mapView.annotations.compactMap { $0 as? WishAnnotation }
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(wishes.compactMap(WishAnnotation.init(wish:)))
    }

    private func bindSelectedWish(_ wish: Wish?) {
        if let wish {
            cardView.bind(wish: wish)
            cardView.isHidden = false
            let annotation = mapView.annotations
                .compactMap { $0 as? WishAnnotation }
                .first { $0.wishId == wish.id }
            if let annotation, !mapView.selectedAnnotations.contains(where: { $0 === annotation }) {
                mapView.selectAnnotation(annotation, animated: false)
            }
        } else {
            cardView.isHidden = true
        }
    }

    private func fitAllPins(wishes: [Wish]) {
        let annotations = mapView.annotations.compactMap { $0 as? WishAnnotation }
        guard let first = annotations.first else { return }

        if annotations.count == 1 {
            mapView.setRegion(MKCoordinateRegion(
                center: first.coordinate,
                latitudinalMeters: Layout.singlePinDistance,
                longitudinalMeters: Layout.singlePinDistance
            ), animated: false)
        } else {
            // 아래 카드와 위 개수 표시에 핀이 가리지 않게 여백을 둔다
            let padding = UIEdgeInsets(top: 80, left: 50, bottom: Layout.cardHeight + 50, right: 50)
            let rect = annotations.reduce(MKMapRect.null) { rect, annotation in
                let point = MKMapPoint(annotation.coordinate)
                return rect.union(MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1))
            }
            mapView.setVisibleMapRect(rect, edgePadding: padding, animated: false)
        }
    }
}

// MARK: Route
extension PlaceMapViewController {
    private func handleRoute(_ route: PlaceMapViewModel.Route) {
        switch route {
        case .pushWishDetail(let reactor):
            let viewController = WishDetailViewController(reactor: reactor, mode: .fromHome)
            navigationController?.pushViewController(viewController, animated: true)
        case .pop:
            navigationController?.popViewController(animated: true)
        }
    }
}

extension PlaceMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? WishAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: EmojiAnnotationView.reuseId, for: annotation)
        (view as? EmojiAnnotationView)?.bind(annotation: annotation)
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? WishAnnotation else { return }
        viewModel.input.didSelectPin.send(annotation.wishId)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // 다른 핀으로 바로 옮겨 가면 didSelect 가 이어서 온다. 빈 곳을 눌러 선택이 풀린 경우만 카드를 닫는다
        DispatchQueue.main.async { [weak self] in
            guard let self, mapView.selectedAnnotations.isEmpty else { return }
            viewModel.input.didDeselectPin.send(())
        }
    }
}

/// 위시 하나를 가리키는 지도 핀
final class WishAnnotation: NSObject, MKAnnotation {
    let wishId: String
    let emoji: String
    let coordinate: CLLocationCoordinate2D
    let title: String?

    init?(wish: Wish) {
        guard let place = wish.place else { return nil }
        self.wishId = wish.id
        self.emoji = wish.emoji
        self.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        self.title = wish.title
        super.init()
    }
}

/// 이모지 핀. 선택되면 커지고 파란 테두리가 된다 (R-7)
final class EmojiAnnotationView: MKAnnotationView {
    static let reuseId = "\(EmojiAnnotationView.self)"

    private var emoji = ""

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        collisionMode = .circle
        displayPriority = .required
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(annotation: WishAnnotation) {
        emoji = annotation.emoji
        accessibilityLabel = annotation.title
        isAccessibilityElement = true
        updatePin()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updatePin()
    }

    private func updatePin() {
        let pinImage = EmojiPinImage.make(emoji: emoji, isSelected: isSelected)
        image = pinImage
        // 핀 꼬리 끝이 좌표에 오도록
        centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        zPriority = isSelected ? .max : .defaultUnselected
    }
}
