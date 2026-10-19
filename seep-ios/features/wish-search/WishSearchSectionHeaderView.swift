import UIKit

/// 검색 결과 카테고리 섹션 제목 (GH-32 R-4)
final class WishSearchSectionHeaderView: UICollectionReusableView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 14)
        label.textColor = .gray4
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(2)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(category: Category) {
        switch category {
        case .wantToDo:
            titleLabel.text = Strings.categoryWantToDo
        case .wantToGet:
            titleLabel.text = Strings.categoryWantToGet
        case .wantToGo:
            titleLabel.text = Strings.categoryWantToGo
        }
    }
}
