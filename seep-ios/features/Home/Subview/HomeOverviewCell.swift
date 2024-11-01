import UIKit

import ISEmojiView

final class HomeOverviewCell: BaseCollectionViewCell {
    enum Layout {
        static let height: CGFloat = 132
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleLight(size: 22)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    let emojiView = EmojiImageView()
    
    override func setup() {
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(emojiView)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(22)
            $0.top.equalToSuperview().offset(28)
        }
        
        emojiView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-30)
            $0.size.equalTo(100)
        }
    }
    
    func bind(category: Category, count: Int) {
        emojiView.bind(category: category)
        setupTitle(category: category, count: count)
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
