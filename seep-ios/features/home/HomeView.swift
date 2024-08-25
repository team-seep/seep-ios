import UIKit

import RxSwift
import RxCocoa

final class HomeView: BaseView {
    let titleLabel = UILabel().then {
        $0.font = .appleLight(size: 22)
        $0.textColor = .black
        $0.numberOfLines = 0
    }
    
    let emojiView = EmojiImageView()
    
    let successCountButton = UIButton().then {
        $0.titleLabel?.font = .appleSemiBold(size: 13)
        $0.setTitleColor(.black, for: .normal)
        $0.setImage(UIImage(named: "ic_right_arrow"), for: .normal)
        $0.semanticContentAttribute = .forceRightToLeft
        $0.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 15
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 1)
        $0.layer.shadowOpacity = 0.05
    }
    
    let categoryView = CategoryView()
    
    let viewTypeButton = UIButton().then {
        $0.setImage(.icGrid, for: .normal)
    }
    
    let containerView = UIView().then {
        $0.isUserInteractionEnabled = true
        $0.backgroundColor = .clear
    }
    
    let writeButton = UIButton().then {
        $0.titleLabel?.font = .appleExtraBold(size: 17)
        $0.backgroundColor = .tennisGreen
        $0.layer.cornerRadius = 25
        $0.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
    }
    
    override func setup() {
        self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
        self.addSubViews([
            self.titleLabel,
            self.emojiView,
            self.successCountButton,
            self.categoryView,
            self.viewTypeButton,
            self.containerView,
            self.writeButton
        ])
    }
    
    override func bindConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22)
            make.top.equalTo(safeAreaLayoutGuide).offset(34 * RatioUtils.height)
        }
        
        self.emojiView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(10)
            make.right.equalToSuperview().offset(-30)
            make.size.equalTo(100)
        }
        
        self.successCountButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20 * RatioUtils.height)
            make.height.equalTo(30)
        }
        
        self.categoryView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalTo(self.successCountButton.snp.bottom).offset(24)
        }
        
        self.viewTypeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-24)
            make.centerY.equalTo(self.categoryView)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.categoryView.snp.bottom).offset(8)
        }
        
        self.writeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-24)
        }
    }
    
    func showWriteButton() {
        UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
            self.writeButton.alpha = 1.0
            self.writeButton.transform = .identity
        }
    }
    
    func hideWriteButton() {
        UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
            self.writeButton.alpha = 0.0
            self.writeButton.transform = .init(translationX: 0, y: 100)
        }
    }
    
    fileprivate func setWishCount(category: Category, count: Int) {
        if count == 0 {
            self.titleLabel.attributedText = self.getEmptyTitle(by: category, count: count)
        } else{
            self.titleLabel.attributedText = self.getCountTitle(by: category, count: count)
        }
    }
    
    func startEmojiAnimation() {
        UIView.transition(
            with: self.emojiView,
            duration: 2,
            options: [.autoreverse,.repeat]
        ) { [weak self] in
            self?.emojiView.transform = .init(translationX: 0, y: 10).rotated(by: CGFloat(10 * CGFloat.pi / 180))
        } completion: { [weak self] _ in
            self?.emojiView.transform = .identity.rotated(by: CGFloat(10 * CGFloat.pi / 180))
        }
    }
    
    fileprivate func setSuccessCount(category: Category, count: Int) {
        let text = count != 0
            ? String(format: "home_finish_count_\(category.rawValue)_format".localized, count)
            : String(format: "home_finish_count_\(category.rawValue)_format_empty".localized, count)
        let attributedString = NSMutableAttributedString(string: text)
        let underlineTextRange
            = (text as NSString).range(of: category == .wantToGo ? "\(count)곳" : "\(count)개")
        
        attributedString.addAttribute(
            .foregroundColor,
            value: UIColor.seepBlue,
            range: underlineTextRange
        )
        self.successCountButton.setAttributedTitle(attributedString, for: .normal)
    }
    
    func changeViewType(to viewType: ViewType) {
        self.viewTypeButton.setImage(UIImage(named: viewType.toggle().imageName), for: .normal)
    }
    
    private func getEmptyTitle(by category: Category, count: Int) -> NSMutableAttributedString {
        let text = "home_write_\(category.rawValue)_count_empty".localized
        let attributedString = NSMutableAttributedString(string: text)
        let boldTextRange = (text as NSString).range(of: "적어봐요!")
        
        attributedString.addAttribute(
            .font,
            value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!,
            range: boldTextRange
        )
        
        return attributedString
    }
    
    private func getCountTitle(by category: Category, count: Int) -> NSMutableAttributedString {
        let text = String(format: "home_write_\(category.rawValue)_count_format".localized, count)
        let attributedString = NSMutableAttributedString(string: text)
        let underlineTextRange = (text as NSString).range(of: String(format: "common_\(category.rawValue)_unit".localized, count))
        let boldTextRange = (text as NSString).range(of: "남았어요!")
        
        attributedString.addAttributes([
            .foregroundColor: UIColor.tennisGreen,
            .font: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!
        ], range: underlineTextRange)
        
        attributedString.addAttribute(
            .font,
            value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!,
            range: boldTextRange
        )
        
        return attributedString
    }
    
    fileprivate func setWriteButtonTitle(by category: Category) {
        let title = "home_write_\(category.rawValue)_button".localized
        
        self.writeButton.setTitle(title, for: .normal)
    }
}

extension Reactive where Base: HomeView {
    var category: Binder<Category> {
        return Binder(self.base) { view, category in
            view.setWriteButtonTitle(by: category)
            view.emojiView.bind(category: category)
        }
    }
    
    var successCount: Binder<(Category, Int)> {
        return Binder(self.base) { view, categoryWithCount in
            view.setSuccessCount(category: categoryWithCount.0, count: categoryWithCount.1)
        }
    }
    
    var wishCount: Binder<(Category, Int)> {
        return Binder(self.base) { view, categoryWithCount in
            view.setWishCount(category: categoryWithCount.0, count: categoryWithCount.1)
        }
    }
    
    var viewType: Binder<ViewType> {
        return Binder(self.base) { view, viewType in
            view.changeViewType(to: viewType)
        }
    }
}
