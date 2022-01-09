import UIKit

final class WriteView: BaseView {
    let tapBackground = UITapGestureRecognizer()
    
    let accessoryView = InputAccessoryView(frame: CGRect(
        x: 0,
        y: 0,
        width: UIScreen.main.bounds.width,
        height: 45
    ))
    
    let scrollView = UIScrollView().then {
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
    }
    
    private let containerView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    let closeButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_close"), for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        let text = "write_title".localized
        let attributedString = NSMutableAttributedString(string: text)
        let boldTextRange = (text as NSString).range(of: "차근차근 적어봐요!")
        
        attributedString.addAttribute(
            .font,
            value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22) as Any,
            range: boldTextRange
        )
        attributedString.addAttribute(
            .kern,
            value: -0.6,
            range: .init(location: 0, length: text.count)
        )
        $0.font = UIFont(name: "AppleSDGothicNeo-Light", size: 22)
        $0.textColor = UIColor(r: 51, g: 51, b: 51)
        $0.numberOfLines = 0
        $0.attributedText = attributedString
    }
    
    let emojiInputView = EmojiInputView()
    
    let categoryView = CategoryView().then {
        $0.containerView.backgroundColor = UIColor(r: 232, g: 246, b: 255)
    }
    
    let titleField = TextInputField(
        iconImage: UIImage(named: "ic_title"),
        title: "write_header_title".localized,
        placeholder: nil
    )
    
    let dateField = TextInputField(
        iconImage: UIImage(named: "ic_calendar"),
        title: "write_header_date".localized,
        placeholder: "write_placeholder_date".localized
    )
    
    private let dateSwitchLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_date_switch_title".localized
    }
    
    let dateSwitch = UISwitch().then {
        $0.onTintColor = .gray3
        $0.onTintColor = .tennisGreen
        $0.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
    }
    
    private let notificationIcon = UIImageView().then {
        $0.image = UIImage(named: "ic_notification_normal")
    }
    
    private let notificationLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_header_notification".localized
    }
    
    private let notificationSwitchLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_notification_switch_title".localized
    }
    
    let notificationSwitch = UISwitch().then {
        $0.onTintColor = .gray3
        $0.onTintColor = .tennisGreen
        $0.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
    }
    
    let notificationTableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.tableFooterView = UIView()
        $0.estimatedRowHeight = UITableView.automaticDimension
        $0.separatorStyle = .none
        $0.register(
            WriteNotificationTableViewCell.self,
            forCellReuseIdentifier: WriteNotificationTableViewCell.registerId
        )
    }
    
    let addNotificationButton = UIButton().then {
        $0.setTitle("write_add_notification".localized, for: .normal)
        $0.setTitleColor(.seepBlue, for: .normal)
        $0.setImage(UIImage(named: "ic_small_plus"), for: .normal)
        $0.titleLabel?.font = .appleExtraBold(size: 14)
        $0.semanticContentAttribute = .forceLeftToRight
    }
    
    private let memoIcon = UIImageView().then {
        $0.image = UIImage(named: "ic_memo")
    }
    
    private let memoLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_header_memo".localized
    }
    
    let memoField = TextInputView()
    
    private let hashtagIcon = UIImageView().then {
        $0.image = UIImage(named: "ic_hashtag")
    }
    
    private let hashtagLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_header_hashtag".localized
    }
    
    let hashtagField = WriteHashtagField()
    
    let gradientView = UIView().then {
        let gradientLayer = CAGradientLayer()
        let topColor = UIColor(r: 246, g: 247, b: 249, a: 0.0).cgColor
        let bottomColor = UIColor(r: 246, g: 247, b: 249, a: 1.0).cgColor
        
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 150)
        $0.layer.addSublayer(gradientLayer)
        $0.isUserInteractionEnabled = false
    }
    
    let writeButton = WriteButton()
    
    override func setup() {
        self.backgroundColor = .white
        self.addGestureRecognizer(self.tapBackground)
        self.scrollView.delegate = self
        
        self.emojiInputView.inputAccessoryView = self.accessoryView
        self.titleField.inputAccessoryView = self.accessoryView
        self.dateField.inputAccessoryView = self.accessoryView
        self.memoField.textView.inputAccessoryView = self.accessoryView
        self.hashtagField.textField.inputAccessoryView = self.accessoryView
        
        self.containerView.addSubViews([
            self.titleLabel,
            self.emojiInputView,
            self.categoryView,
            self.titleField,
            self.dateField,
            self.dateSwitchLabel,
            self.dateSwitch,
            self.notificationIcon,
            self.notificationLabel,
            self.notificationSwitchLabel,
            self.notificationSwitch,
            self.notificationTableView,
            self.addNotificationButton,
            self.memoIcon,
            self.memoLabel,
            self.memoField,
            self.hashtagIcon,
            self.hashtagLabel,
            self.hashtagField
        ])
        self.scrollView.addSubview(containerView)
        self.addSubViews([
            self.closeButton,
            self.scrollView,
            self.gradientView,
            self.writeButton
        ])
    }
    
    override func bindConstraints() {
        self.closeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.height.equalTo(24)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.closeButton.snp.bottom)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalTo(0)
            make.width.equalToSuperview()
            make.top.equalTo(self.closeButton).priority(.high)
            make.bottom.equalTo(self.hashtagField).offset(20).priority(.high)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(33)
        }
        
        self.emojiInputView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(16)
        }
        
        self.categoryView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.emojiInputView.snp.bottom).offset(32)
        }
        
        self.titleField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.categoryView.snp.bottom).offset(31)
        }
        
        self.dateField.snp.makeConstraints { make in
            make.left.right.equalTo(self.titleField)
            make.top.equalTo(self.titleField.snp.bottom).offset(24)
        }
        
        self.dateSwitch.snp.makeConstraints { make in
            make.right.equalTo(self.dateField)
            make.top.equalTo(self.dateField).offset(-8)
        }
        
        self.dateSwitchLabel.snp.makeConstraints { make in
            make.right.equalTo(self.dateSwitch.snp.left).offset(-8)
            make.centerY.equalTo(self.dateSwitch)
        }
        
        self.notificationIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.dateField.snp.bottom).offset(26)
            make.width.height.equalTo(16)
        }
        
        self.notificationLabel.snp.makeConstraints { make in
            make.left.equalTo(self.notificationIcon.snp.right).offset(4)
            make.centerY.equalTo(self.notificationIcon)
        }
        
        self.notificationSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.notificationLabel)
        }
        
        self.notificationSwitchLabel.snp.makeConstraints { make in
            make.right.equalTo(self.notificationSwitch.snp.left).offset(-8)
            make.centerY.equalTo(self.notificationSwitch)
        }
        
        self.notificationTableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.notificationIcon.snp.bottom).offset(2)
            make.height.equalTo(56)
        }
        
        self.addNotificationButton.snp.makeConstraints { make in
            make.left.equalTo(self.notificationTableView)
            make.right.equalTo(self.notificationTableView)
            make.top.equalTo(self.notificationTableView.snp.bottom).offset(8)
            make.height.equalTo(32)
        }
        
        self.memoIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.addNotificationButton.snp.bottom).offset(26)
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
        
        self.memoLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.memoIcon)
            make.left.equalTo(self.memoIcon.snp.right).offset(4)
        }
        
        self.memoField.snp.makeConstraints { make in
            make.left.right.equalTo(self.titleField)
            make.top.equalTo(self.memoIcon.snp.bottom).offset(10)
        }
        
        self.hashtagIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.memoField.snp.bottom).offset(26)
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
        
        self.hashtagLabel.snp.makeConstraints { make in
            make.left.equalTo(self.hashtagIcon.snp.right).offset(4)
            make.centerY.equalTo(self.hashtagIcon)
        }
        
        self.hashtagField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.hashtagIcon.snp.bottom).offset(10)
        }
        
        self.gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(150)
        }
        
        self.writeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-23)
            make.height.equalTo(50)
        }
    }
    
    func updateNotificationTableViewHeight(by notifications: [SeepNotification]) {
        self.notificationTableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(notifications.count) * WriteNotificationTableViewCell.height)
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
    
    func setTitlePlaceholder(by category: Category) {
        self.titleField.placeholder = "write_placeholder_title_\(category.rawValue)".localized
    }
}

extension WriteView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hideWriteButton()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.showWriteButton()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.showWriteButton()
    }
}
