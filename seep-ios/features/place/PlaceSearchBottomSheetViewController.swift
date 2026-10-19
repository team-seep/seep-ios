import UIKit
import Combine

import CombineCocoa
import PanModal
import SnapKit

/// "어디로 가고 싶어요?" 장소 검색 바텀시트 (GH-31 R-3).
final class PlaceSearchBottomSheetViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let fieldHeight: CGFloat = 52
    }

    private let viewModel: PlaceSearchViewModel

    private let indicatorView = BottomSheetIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let text = Strings.Detail.Place.Search.title
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (text as NSString).range(of: Strings.Detail.Place.Search.titleBold, options: .backwards)
        )
        label.attributedText = attributedText
        return label
    }()

    private let fieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 12
        return view
    }()

    private let searchIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = .appleRegular(size: 16)
        textField.textColor = .gray5
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing
        textField.attributedPlaceholder = NSAttributedString(
            string: Strings.Detail.Place.Search.placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        textField.accessibilityLabel = Strings.Detail.Place.Search.placeholder
        return textField
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.register(PlaceSearchResultCell.self, forCellReuseIdentifier: PlaceSearchResultCell.registerId)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 15)
        label.textColor = .gray4
        label.textAlignment = .center
        label.text = Strings.Detail.Place.Search.empty
        label.isHidden = true
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 13)
        label.textColor = .gray4
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = Strings.Detail.Place.Search.caption
        return label
    }()

    private var candidates: [PlaceCandidate] = []

    init(viewModel: PlaceSearchViewModel) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    private func setupUI() {
        view.backgroundColor = .white
        fieldView.addSubViews([searchIconImageView, textField])
        view.addSubViews([indicatorView, titleLabel, fieldView, tableView, emptyLabel, captionLabel])
        tableView.dataSource = self
        tableView.delegate = self

        indicatorView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(indicatorView.snp.bottom).offset(16)
        }

        fieldView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.height.equalTo(Layout.fieldHeight)
        }

        searchIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        textField.snp.makeConstraints {
            $0.leading.equalTo(searchIconImageView.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.bottom.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(fieldView.snp.bottom).offset(8)
            $0.bottom.equalTo(captionLabel.snp.top).offset(-12)
        }

        emptyLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(fieldView.snp.bottom).offset(40)
        }

        captionLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-12)
        }
    }

    private func bind() {
        textField.textPublisher
            .map { $0 ?? "" }
            .removeDuplicates()
            .subscribe(viewModel.input.inputQuery)
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidEndOnExit)
            .withUnretained(self)
            .sink { (owner: PlaceSearchBottomSheetViewController, _) in
                owner.view.endEditing(true)
            }
            .store(in: &cancellables)

        viewModel.output.candidates
            .main
            .withUnretained(self)
            .sink { (owner: PlaceSearchBottomSheetViewController, candidates: [PlaceCandidate]) in
                owner.candidates = candidates
                owner.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.output.isEmptyVisible
            .main
            .withUnretained(self)
            .sink { (owner: PlaceSearchBottomSheetViewController, isEmptyVisible: Bool) in
                owner.emptyLabel.isHidden = !isEmptyVisible
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: PlaceSearchBottomSheetViewController, route: PlaceSearchViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension PlaceSearchBottomSheetViewController {
    private func handleRoute(_ route: PlaceSearchViewModel.Route) {
        switch route {
        case .dismiss:
            view.endEditing(true)
            dismiss(animated: true)
        }
    }
}

extension PlaceSearchBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return candidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PlaceSearchResultCell.registerId,
            for: indexPath
        ) as? PlaceSearchResultCell,
              let candidate = candidates[safe: indexPath.row] else {
            return UITableViewCell()
        }

        cell.bind(candidate: candidate)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.input.didTapCandidate.send(indexPath.row)
    }
}

extension PlaceSearchBottomSheetViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return tableView
    }

    var shortFormHeight: PanModalHeight {
        return longFormHeight
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(60)
    }

    var showDragIndicator: Bool {
        return false
    }

    var cornerRadius: CGFloat {
        return 16
    }
}
