import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 위시 상세 = 흰 바탕의 한 장 문서 (GH-59 D2).
/// 상단 바(뒤로·수정·⋯) / 제목 블록(이모지·제목·D-day 줄·메타 줄) / 메모 / 단계 · 모은 돈 · 링크 · 장소 · 사진 섹션.
/// 작성용 입력 컴포넌트를 쓰지 않고, 카드·구분선 없이 섹션 사이 40pt 여백으로 나눈다 (R-1).
final class WishDetailView: BaseView {
    private enum Layout {
        static let horizontalInset: CGFloat = 24
        static let sectionSpacing: CGFloat = 40
        static let bodySpacing: CGFloat = 28
    }

    let navigationBar = DetailNavigationBar()

    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.sectionSpacing
        return stackView
    }()

    let titleBlock = DocumentTitleBlock()

    let memoView = DocumentBodyView()

    let stepsView: WishStepsView = {
        let view = WishStepsView()
        view.configure(style: .document)
        return view
    }()

    let stepsSection = DocumentSectionView(title: Strings.Detail.Step.title)

    let savingsView: WishSavingsView = {
        let view = WishSavingsView()
        view.configure(style: .document)
        return view
    }()

    let savingsSection = DocumentSectionView(
        title: Strings.Detail.Section.savings,
        actionTitle: Strings.Detail.Section.savingsAdd
    )

    let linkView = LinkInlineView()

    let linkSection = DocumentSectionView(
        title: Strings.Detail.Link.title,
        actionTitle: Strings.Detail.Section.linkOpen
    )

    let placeView: WishPlaceView = {
        let view = WishPlaceView()
        view.configure(style: .document)
        return view
    }()

    let placeSection = DocumentSectionView(
        title: Strings.Detail.Place.title,
        actionTitle: Strings.Detail.Section.placeChange
    )

    let photoView: WishPhotoView = {
        let view = WishPhotoView()
        view.configure(style: .document)
        return view
    }()

    let photoSection = DocumentSectionView(
        title: Strings.Detail.Photo.title,
        actionTitle: Strings.Detail.Photo.change
    )

    override func setup() {
        backgroundColor = .gray1

        stepsSection.setContent(stepsView)
        savingsSection.setContent(savingsView)
        linkSection.setContent(linkView)
        placeSection.setContent(placeView)
        photoSection.setContent(photoView)

        [titleBlock, memoView, stepsSection, savingsSection, linkSection, placeSection, photoSection]
            .forEach(contentStackView.addArrangedSubview)
        scrollView.addSubview(contentStackView)
        addSubViews([scrollView, navigationBar])

        bindCollapsingTitle()
    }

    override func bindConstraints() {
        // 듀오 바깥 화면은 오른쪽 위에 센서·상태 표시 영역(safe area 오른쪽 inset)이 있어 safe area 기준으로 둔다.
        navigationBar.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-40)
            $0.leading.equalToSuperview().offset(Layout.horizontalInset)
            $0.trailing.equalToSuperview().offset(-Layout.horizontalInset)
            $0.width.equalToSuperview().offset(-Layout.horizontalInset * 2)
        }
    }

    func bind(summary: WishDetailSummary) {
        titleBlock.bind(summary: summary)
        memoView.bind(text: summary.memo)
        navigationBar.setTitle(summary.title, dday: summary.navigationDday)
    }

    /// 섹션 노출·순서 (R-10). 순서는 스택에 넣은 순서가 `DetailSection` 순서와 같다.
    func apply(sections: [DetailSection]) {
        memoView.isHidden = !sections.contains(.memo)
        stepsSection.isHidden = !sections.contains(.steps)
        savingsSection.isHidden = !sections.contains(.savings)
        linkSection.isHidden = !sections.contains(.link)
        placeSection.isHidden = !sections.contains(.place)
        photoSection.isHidden = !sections.contains(.photo)
        // 메모는 메타 줄과 28, 나머지 섹션은 40 (디자인 D2)
        contentStackView.setCustomSpacing(
            sections.contains(.memo) ? Layout.bodySpacing : Layout.sectionSpacing,
            after: titleBlock
        )
    }

    /// 큰 제목이 상단 바 아래로 지나가면 바 가운데에 제목·작은 D-day를 보인다 (R-8)
    private func bindCollapsingTitle() {
        scrollView.contentOffsetPublisher
            .withUnretained(self)
            .sink { (owner: WishDetailView, offset: CGPoint) in
                let titleLabel = owner.titleBlock.titleLabel
                let titleBottom = titleLabel.convert(titleLabel.bounds, to: owner.scrollView).maxY
                owner.navigationBar.setTitleCollapsed(titleBottom > 0 && offset.y >= titleBottom)
            }
            .store(in: &cancellables)
    }
}
