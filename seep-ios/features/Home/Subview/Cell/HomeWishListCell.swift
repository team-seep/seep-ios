import UIKit

import CombineCocoa

final class HomeWishListCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = 70
    }
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36)
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray5
        label.font = .appleSemiBold(size: 16)
        return label
    }()
    
    private let pinImageView = HomeWishPinMenu.makePinImageView()
    
    /// 제목 + 핀. 핀이 숨으면 스택에서 빠져 제목이 그 자리까지 쓴다 (GH-33 R-7)
    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, pinImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        return stackView
    }()
    
    private let ddayLabel = DdayLabel()
    
    private let tagLabel = TagLabel()
    
    private let stepProgressBar = StepProgressBar(width: 32)
    
    private let stepProgressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleBold(size: 11)
        return label
    }()
    
    private let finishNoteLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray4
        label.font = .appleMedium(size: 12)
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()
    
    private let finishButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icCheckOff.image, for: .normal)
        button.setImage(Assets.Icons.icCheckOn.image, for: .selected)
        return button
    }()
    
    private var viewModel: HomeWishCellViewModel?
    
    override func setup() {
        setupUI()
        contentView.addInteraction(UIContextMenuInteraction(delegate: self))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.attributedText = nil
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(containerView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleStackView)
        contentView.addSubview(ddayLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(stepProgressBar)
        contentView.addSubview(stepProgressLabel)
        contentView.addSubview(finishNoteLabel)
        contentView.addSubview(finishButton)
        
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.height)
        }
        
        emojiLabel.snp.makeConstraints {
            $0.leading.equalTo(containerView).offset(14)
            $0.centerY.equalToSuperview()
        }
        
        titleStackView.snp.makeConstraints {
            $0.top.equalTo(emojiLabel).offset(3)
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(14)
            $0.trailing.lessThanOrEqualTo(finishButton.snp.leading).offset(-12)
        }
        // 제목이 길면 제목이 말줄임되고 핀은 남는다 (GH-33 R-7)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        ddayLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
        
        tagLabel.snp.makeConstraints {
            $0.leading.equalTo(ddayLabel.snp.trailing).offset(7)
            $0.centerY.height.equalTo(ddayLabel)
        }
        
        finishButton.snp.makeConstraints {
            $0.centerY.equalTo(containerView)
            $0.trailing.equalTo(containerView).offset(-16)
        }
        
        stepProgressBar.snp.makeConstraints {
            $0.leading.equalTo(tagLabel.snp.trailing).offset(9)
            $0.centerY.equalTo(ddayLabel)
        }
        
        stepProgressLabel.snp.makeConstraints {
            $0.leading.equalTo(stepProgressBar.snp.trailing).offset(4)
            $0.centerY.equalTo(ddayLabel)
        }
        
        // 뱃지 줄 자리에 한 줄로 둔다. 체크 버튼 앞에서 말줄임해 셀 높이 70을 유지한다 (GH-25 R-5)
        finishNoteLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(finishButton.snp.leading).offset(-12)
            $0.centerY.equalTo(ddayLabel)
        }
        // 긴 소감이 이모지를 밀어내지 않고 스스로 말줄임되도록 가로 압축 저항을 낮춘다
        finishNoteLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    func bind(viewModel: HomeWishCellViewModel) {
        self.viewModel = viewModel
        pinImageView.isHidden = !viewModel.output.isPinned
        setupWish(viewModel.output.wish)
        setupStepProgress(viewModel.output.stepProgress, isTagHidden: viewModel.output.wish.hashtag.isEmpty)
        setupFinishNote(viewModel.output.finishNote)
        
        finishButton.tapPublisher
            .subscribe(viewModel.input.didTapFinish)
            .store(in: &cancellables)
    }
  
    private func setupWish(_ wish: Wish) {
        emojiLabel.text = wish.emoji
        titleLabel.text = wish.title
        ddayLabel.bind(dday: wish.endDate)
        tagLabel.text = HashtagType(rawValue: wish.hashtag)?.description ?? wish.hashtag
        tagLabel.isHidden = wish.hashtag.isEmpty
        finishButton.isSelected = wish.isSuccess
        
        if wish.isSuccess {
            emojiLabel.alpha = 0.5
            titleLabel.alpha = 0.5
            
            let attributedString = NSMutableAttributedString(string: wish.title)
            attributedString.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.gray4.copy()
            ], range: NSRange(location: 0, length: wish.title.count))
            titleLabel.attributedText = attributedString
            
            ddayLabel.alpha = 0.5
            tagLabel.alpha = 0.5
        } else {
            emojiLabel.alpha = 1
            titleLabel.alpha = 1
            ddayLabel.alpha = 1
            tagLabel.alpha = 1
        }
    }
    
    private func setupStepProgress(_ progress: WishStepProgress?, isTagHidden: Bool) {
        stepProgressBar.isHidden = progress == nil
        stepProgressLabel.isHidden = progress == nil
        guard let progress else { return }
        
        stepProgressBar.bind(progress: progress)
        stepProgressLabel.text = Strings.Home.stepProgressFormat(progress.doneCount, progress.totalCount)
        stepProgressBar.snp.remakeConstraints {
            $0.leading.equalTo(isTagHidden ? ddayLabel.snp.trailing : tagLabel.snp.trailing).offset(9)
            $0.centerY.equalTo(ddayLabel)
        }
    }
    
    /// 소감이 있으면 뱃지 줄(D-day·해시태그·단계 진행도)을 숨기고 소감 한 줄을 보여준다
    private func setupFinishNote(_ finishNote: String?) {
        let hasNote = finishNote != nil
        finishNoteLabel.isHidden = !hasNote
        finishNoteLabel.text = finishNote.map { Strings.Home.FinishNote.cellFormat($0) }
        // 셀 재사용 때 다시 보이도록 D-day 는 매번 정한다. 해시태그·진행도는 앞 단계에서 이미 정했다
        ddayLabel.isHidden = hasNote
        guard hasNote else { return }
        
        tagLabel.isHidden = true
        stepProgressBar.isHidden = true
        stepProgressLabel.isHidden = true
    }
}

// MARK: Pin (GH-33)
extension HomeWishListCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return HomeWishPinMenu.configuration(viewModel: viewModel)
    }
    
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return HomeWishPinMenu.preview(view: contentView)
    }
}

/// 홈 위시 셀(리스트·그리드)이 같이 쓰는 고정 메뉴와 핀 아이콘 (GH-33 R-2, R-7)
enum HomeWishPinMenu {
    static func makePinImageView() -> UIImageView {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14)
        let imageView = UIImageView(image: UIImage(systemName: "pin.fill", withConfiguration: configuration))
        imageView.tintColor = .gray4
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }
    
    static func configuration(viewModel: HomeWishCellViewModel?) -> UIContextMenuConfiguration? {
        guard let viewModel, viewModel.output.canShowPinMenu else { return nil }
        
        let isPinned = viewModel.output.isPinned
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak viewModel] _ in
            let action = UIAction(
                title: isPinned ? Strings.Home.Pin.unpin : Strings.Home.Pin.pin,
                image: UIImage(systemName: isPinned ? "pin.slash" : "pin")
            ) { _ in
                viewModel?.input.didTapPinMenu.send(())
            }
            return UIMenu(children: [action])
        }
    }
    
    /// 셀 카드 모양(모서리 12) 그대로 띄운다
    static func preview(view: UIView) -> UITargetedPreview {
        let parameters = UIPreviewParameters()
        parameters.visiblePath = UIBezierPath(roundedRect: view.bounds, cornerRadius: 12)
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: view, parameters: parameters)
    }
}
