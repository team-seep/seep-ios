import UIKit

import ISEmojiView

final class HomeOverviewCell: BaseCollectionViewCell {
    enum Layout {
        /// 헤드라인 2줄 + "배지 n/8 모아보기" 링크 (GH-35 R-4)
        static let height: CGFloat = 160
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleLight(size: 22)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    let emojiView = EmojiImageView()
    
    let badgeLinkButton = BadgeLinkButton()
    
    override func setup() {
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(emojiView)
        contentView.addSubview(badgeLinkButton)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(28)
        }
        
        emojiView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            // 듀오 바깥 화면의 오른쪽 위 센서·상태 표시 영역과 겹치지 않게 safe area 기준
            $0.trailing.equalTo(contentView.safeAreaLayoutGuide).offset(-20)
            $0.size.equalTo(100)
        }
        
        badgeLinkButton.snp.makeConstraints {
            $0.leading.equalToSuperview()
            // 글자는 헤드라인 아래 8pt, 버튼 높이는 탭하기 쉽게 32
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.height.equalTo(32)
        }
    }
    
    func bind(category: Category, count: Int, badgeCount: Int) {
        emojiView.bind(category: category)
        setupTitle(category: category, count: count)
        badgeLinkButton.setTitle(Strings.Home.badgeLinkFormat(badgeCount, BadgeType.allCases.count))
    }
    
    func playEmojiAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            UIView.transition(
                with: emojiView,
                duration: 2,
                options: [.autoreverse,.repeat]
            ) { [weak self] in
                self?.emojiView.transform = .init(translationX: 0, y: 5).rotated(by: CGFloat(10 * CGFloat.pi / 180))
            } completion: { [weak self] _ in
                self?.emojiView.transform = .identity.rotated(by: CGFloat(10 * CGFloat.pi / 180))
            }
        }
    }
    
    func stopEmojiAnimation() {
        emojiView.layer.removeAllAnimations()
    }
    
    private func setupTitle(category: Category, count: Int) {
        if count == 0 {
            titleLabel.attributedText = category.emptyText
        } else {
            titleLabel.attributedText = category.countTitle(count: count)
        }
    }
}


private extension Category {
    var emptyText: NSMutableAttributedString {
        let text: String
        switch self {
        case .wantToDo:
            text = Strings.Home.EmptyTitle.wantToDo
        case .wantToGo:
            text = Strings.Home.EmptyTitle.wantToGo
        case .wantToGet:
            text = Strings.Home.EmptyTitle.wantToGet
        }
        
        let attributedString = NSMutableAttributedString(string: text)
        let boldTextRange = (text as NSString).range(of: "적어봐요!")
        
        attributedString.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: boldTextRange
        )
        
        return attributedString
    }
    
    func countTitle(count: Int) -> NSMutableAttributedString {
        let text: String
        switch self {
        case .wantToDo:
            text = Strings.Home.TitleFormat.wantToDo(count)
        case .wantToGo:
            text = Strings.Home.TitleFormat.wantToGo(count)
        case .wantToGet:
            text = Strings.Home.TitleFormat.wantToGet(count)
        }
        
        let underlineText: String
        switch self {
        case .wantToDo:
            underlineText = Strings.Common.WantToDo.unit(count)
        case .wantToGo:
            underlineText = Strings.Common.WantToGo.unit(count)
        case .wantToGet:
            underlineText = Strings.Common.WantToGet.unit(count)
        }
        
        
        let attributedString = NSMutableAttributedString(string: text)
        let underlineTextRange = (text as NSString).range(of: underlineText)
        let boldTextRange = (text as NSString).range(of: "남았어요!")
        
        attributedString.addAttributes([
            .foregroundColor: UIColor.tennisGreen,
            .font: UIFont.appleBold(size: 22) as Any
        ], range: underlineTextRange)
        
        attributedString.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: boldTextRange
        )
        
        return attributedString
    }
}
