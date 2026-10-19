import UIKit

import CombineCocoa

/// 오래 손대지 않은 위시에 "아직 하고 싶어요?"를 묻는 카드 (GH-30 R-6). 리스트·그리드 모두 전체 폭으로 그린다.
final class HomeSleepingWishCell: BaseCollectionViewCell {
    enum Layout {
        static let buttonHeight: CGFloat = 46
        /// 위 여백 16 + 캡션 17 + 질문 20 + 10 + 이모지 줄 36 + 14 + 구분선 1 + 버튼 46
        static let height: CGFloat = 160

        /// 그리드 보기에서 맨 위 카드(전체 폭) + 그 아래 위시 격자를 한 그룹으로 그린다.
        /// 기본 그리드 그룹은 같은 크기 아이템만 반복하므로 카드가 있을 때만 이 그룹을 쓴다.
        static func gridGroupWithCard(availableWidth: CGFloat, wishCount: Int) -> NSCollectionLayoutGroup {
            let spacing = HomeWishGridCell.Layout.spacing
            let columnCount = HomeWishGridCell.Layout.columnCount(availableWidth: availableWidth)
            let itemSize = HomeWishGridCell.Layout.itemSize(availableWidth: availableWidth)
            let rowCount = (wishCount + columnCount - 1) / columnCount
            let gridHeight = rowCount > 0
                ? CGFloat(rowCount) * itemSize.height + CGFloat(rowCount - 1) * spacing + spacing
                : 0

            return NSCollectionLayoutGroup.custom(layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(height + gridHeight)
            )) { _ in
                var items = [NSCollectionLayoutGroupCustomItem(frame: CGRect(
                    x: 0,
                    y: 0,
                    width: availableWidth,
                    height: height
                ))]
                for index in 0..<wishCount {
                    let row = CGFloat(index / columnCount)
                    let column = CGFloat(index % columnCount)
                    items.append(NSCollectionLayoutGroupCustomItem(frame: CGRect(
                        x: column * (itemSize.width + spacing),
                        y: height + spacing + row * (itemSize.height + spacing),
                        width: itemSize.width,
                        height: itemSize.height
                    )))
                }
                return items
            }
        }
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleMedium(size: 12)
        return label
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray5
        label.font = .appleBold(size: 14)
        return label
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray5
        label.font = .appleSemiBold(size: 16)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    private let releaseButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.gray4, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        return button
    }()

    private let keepButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.seepBlue, for: .normal)
        button.titleLabel?.font = .appleExtraBold(size: 14)
        return button
    }()

    override func setup() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(captionLabel)
        containerView.addSubview(questionLabel)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(dividerView)
        containerView.addSubview(releaseButton)
        containerView.addSubview(keepButton)
    }

    override func bindConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }

        captionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(14)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.height.equalTo(17)
        }

        questionLabel.snp.makeConstraints {
            $0.top.equalTo(captionLabel.snp.bottom)
            $0.leading.equalTo(captionLabel)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.height.equalTo(20)
        }

        emojiLabel.snp.makeConstraints {
            $0.top.equalTo(questionLabel.snp.bottom).offset(10)
            $0.leading.equalTo(captionLabel)
            $0.height.equalTo(36)
        }
        emojiLabel.setContentHuggingPriority(.required, for: .horizontal)
        emojiLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.centerY.equalTo(emojiLabel)
        }

        dividerView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.bottom.equalTo(releaseButton.snp.top)
            $0.height.equalTo(1)
        }

        releaseButton.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(Layout.buttonHeight)
        }

        keepButton.snp.makeConstraints {
            $0.leading.equalTo(releaseButton.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(Layout.buttonHeight)
            $0.width.equalTo(releaseButton)
        }
    }

    func bind(viewModel: HomeSleepingWishCardViewModel) {
        captionLabel.text = viewModel.output.caption
        questionLabel.text = viewModel.output.question
        emojiLabel.text = viewModel.output.wish.emoji
        titleLabel.text = viewModel.output.wish.title
        releaseButton.setTitle(viewModel.output.releaseTitle, for: .normal)
        keepButton.setTitle(viewModel.output.keepTitle, for: .normal)

        releaseButton.tapPublisher
            .subscribe(viewModel.input.didTapRelease)
            .store(in: &cancellables)

        keepButton.tapPublisher
            .subscribe(viewModel.input.didTapKeep)
            .store(in: &cancellables)
    }
}
