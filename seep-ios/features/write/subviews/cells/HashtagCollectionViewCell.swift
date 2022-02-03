import UIKit

final class HashtagCollectionViewCell: BaseCollectionViewCell {
    static let registerID = "\(HashtagCollectionViewCell.self)"
    static let estimatedSize = CGSize(width: 64, height: 32)
    
    private let containerView = UIView().then {
        $0.layer.cornerRadius = 6
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(r: 192, g: 197, b: 205).cgColor
    }
    
    private let textLabel = UILabel().then {
        $0.font = .appleExtraBold(size: 14)
        $0.textColor = .gray4
    }
    
    override var isSelected: Bool {
        didSet {
            self.containerView.layer.borderWidth = isSelected ? 0 : 1
            self.textLabel.textColor = isSelected ? .gray1 : .gray4
            self.containerView.backgroundColor = isSelected ? .seepBlue : .clear
        }
    }
    
    override func setup() {
        self.addSubViews([
            self.containerView,
            self.textLabel
        ])
        
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalTo(self.textLabel).offset(8)
            make.right.equalToSuperview()
            make.bottom.equalTo(self.textLabel).offset(6)
            make.bottom.equalToSuperview()
        }
        
        self.textLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(8)
            make.top.equalTo(self.containerView).offset(6)
        }
    }
    
    func bind(type: HashtagType) {
        self.textLabel.text = type.description
    }
}
