import UIKit
import Combine

import CombineCocoa

/// 제목·메모·해시태그로 세 카테고리 전체에서 위시를 찾는 화면 (GH-32).
final class WishSearchViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    enum Layout {
        static let searchFieldHeight: CGFloat = 48
        static let sectionHeaderHeight: CGFloat = 44
        static let horizontalInset: CGFloat = 20
        static let debounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    }

    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icChevronBack.image, for: .normal)
        button.tintColor = .gray5
        return button
    }()

    private let searchFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 12
        return view
    }()

    private let searchIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let searchField: UITextField = {
        let textField = UITextField()
        textField.font = .appleMedium(size: 16)
        textField.textColor = .gray5
        textField.tintColor = .seepBlue
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(string: Strings.WishSearch.placeholder, attributes: [
            .foregroundColor: UIColor.gray3,
            .font: UIFont.appleMedium(size: 16) as Any
        ])
        return textField
    }()

    private let clearButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icClose.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray3
        button.isHidden = true
        return button
    }()

    private let resultCountLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .gray4
        label.isHidden = true
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .onDrag
        collectionView.contentInset = .init(top: 0, left: 0, bottom: 24, right: 0)
        collectionView.dataSource = self
        collectionView.register([WishSearchResultCell.self])
        collectionView.registerSectionHeader([WishSearchSectionHeaderView.self])
        return collectionView
    }()

    private let emptyView = WishSearchEmptyView()

    private let viewModel: WishSearchViewModel
    private var sections: [WishSearchSection] = []

    init(viewModel: WishSearchViewModel) {
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

        // 처음 열릴 때만 바로 입력할 수 있게 포커스를 준다 (R-2). 상세에서 돌아올 때는 결과를 보던 중이다
        if isMovingToParent {
            searchField.becomeFirstResponder()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupUI() {
        view.backgroundColor = .gray2

        let contentView = UIView()
        view.addSubview(contentView)
        contentView.addSubview(backButton)
        contentView.addSubview(searchFieldContainer)
        searchFieldContainer.addSubview(searchIconView)
        searchFieldContainer.addSubview(searchField)
        searchFieldContainer.addSubview(clearButton)
        contentView.addSubview(resultCountLabel)
        contentView.addSubview(collectionView)
        contentView.addSubview(emptyView)

        contentView.snp.makeConstraints {
            // 넓은 화면(듀오 안쪽)에서는 홈과 같은 최대 폭 기둥으로 가운데 둔다
            WideScreenLayout.makeColumnConstraints($0)
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalTo(searchFieldContainer)
            $0.size.equalTo(44)
        }

        searchFieldContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalTo(backButton.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().offset(-Layout.horizontalInset)
            $0.height.equalTo(Layout.searchFieldHeight)
        }

        searchIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        clearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-4)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        searchField.snp.makeConstraints {
            $0.leading.equalTo(searchIconView.snp.trailing).offset(8)
            $0.trailing.equalTo(clearButton.snp.leading)
            $0.top.bottom.equalToSuperview()
        }

        resultCountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.horizontalInset + 2)
            $0.trailing.equalToSuperview().offset(-Layout.horizontalInset)
            $0.top.equalTo(searchFieldContainer.snp.bottom).offset(20)
        }

        collectionView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(resultCountLabel.snp.bottom).offset(4)
        }

        emptyView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.horizontalInset)
            $0.trailing.equalToSuperview().offset(-Layout.horizontalInset)
            $0.top.equalTo(searchFieldContainer.snp.bottom).offset(120)
        }
    }

    private func bind() {
        // Input
        backButton.tapPublisher
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, _) in
                owner.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)

        let keyword = searchField.textPublisher
            .map { $0 ?? "" }
            .share()

        keyword
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, text: String) in
                owner.clearButton.isHidden = text.isEmpty
            }
            .store(in: &cancellables)

        // 입력하는 대로 찾되 글자마다 조회하지 않도록 0.3초 멈추면 찾는다 (R-3)
        keyword
            .debounce(for: Layout.debounce, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .subscribe(viewModel.input.inputKeyword)
            .store(in: &cancellables)

        clearButton.tapPublisher
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, _) in
                owner.searchField.text = ""
                owner.searchField.sendActions(for: .editingChanged)
                owner.searchField.becomeFirstResponder()
            }
            .store(in: &cancellables)

        searchField.controlEventPublisher(for: .editingDidEndOnExit)
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, _) in
                owner.searchField.resignFirstResponder()
            }
            .store(in: &cancellables)

        collectionView.didSelectItemPublisher
            .subscribe(viewModel.input.didTapResult)
            .store(in: &cancellables)

        // Output
        viewModel.output.sections
            .main
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, sections: [WishSearchSection]) in
                owner.sections = sections
                owner.collectionView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.output.resultCount
            .main
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, count: Int?) in
                owner.setResultCount(count)
            }
            .store(in: &cancellables)

        viewModel.output.emptyKeyword
            .main
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, keyword: String?) in
                owner.emptyView.isHidden = keyword == nil
                owner.emptyView.bind(keyword: keyword ?? "")
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: WishSearchViewController, route: WishSearchViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func setResultCount(_ count: Int?) {
        guard let count else {
            resultCountLabel.isHidden = true
            return
        }

        let text = Strings.WishSearch.resultCountFormat(count)
        let attributedText = NSMutableAttributedString(string: text)
        let highlight = (text as NSString).range(of: Strings.WishSearch.resultCountHighlightFormat(count))
        if highlight.location != NSNotFound {
            attributedText.addAttributes([
                .foregroundColor: UIColor.seepBlue,
                .font: UIFont.appleBold(size: 14) as Any
            ], range: highlight)
        }
        resultCountLabel.attributedText = attributedText
        resultCountLabel.isHidden = false
    }

    private func createLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(WishSearchResultCell.Layout.height)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(WishSearchResultCell.Layout.height)
        ), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = .init(
            top: 0,
            leading: Layout.horizontalInset,
            bottom: 8,
            trailing: Layout.horizontalInset
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(Layout.sectionHeaderHeight)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension WishSearchViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[safe: section]?.items.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: WishSearchResultCell = collectionView.dequeueReusableCell(indexPath: indexPath)
        if let item = sections[safe: indexPath.section]?.items[safe: indexPath.item] {
            cell.bind(item: item)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header: WishSearchSectionHeaderView = collectionView.dequeueReusableSupplementaryView(
            ofkind: kind,
            indexPath: indexPath
        )
        if let category = sections[safe: indexPath.section]?.category {
            header.bind(category: category)
        }
        return header
    }
}

// MARK: Route
extension WishSearchViewController {
    private func handleRoute(_ route: WishSearchViewModel.Route) {
        switch route {
        case .pushWishDetail(let reactor):
            pushWishDetail(reactor: reactor)
        }
    }

    private func pushWishDetail(reactor: WishDetailReactor) {
        view.endEditing(true)
        let mode: DetailMode = reactor.initialState.wish.isSuccess ? .fromFinish : .fromHome
        let viewController = WishDetailViewController(reactor: reactor, mode: mode)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
