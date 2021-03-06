import UIKit

import RxSwift
import RxCocoa

final class WishEditView: BaseView {
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
    
    private let backgroundView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
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
        $0.tintColor = .gray3
        $0.isOn = true
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
        $0.tintColor = .gray3
        $0.isOn = true
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
        $0.setImage(
            UIImage(named: "ic_small_plus")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.tintColor = .seepBlue
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
    
    let hashtagCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = LeftAlignedCollectionViewFlowLayout()
        
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        $0.collectionViewLayout = layout
        $0.register(
            HashtagCollectionViewCell.self,
            forCellWithReuseIdentifier: HashtagCollectionViewCell.registerID
        )
        $0.backgroundColor = .clear
    }
    
    let hashtagField = CustomHashtagField()
    
    let editButton = EditButton()
    
    override func setup() {
        self.backgroundColor = .white
        
        self.backgroundView.addGestureRecognizer(self.tapBackground)
        self.titleField.textField.delegate = self
        
        self.emojiInputView.inputAccessoryView = self.accessoryView
        self.titleField.inputAccessoryView = self.accessoryView
        self.dateField.inputAccessoryView = self.accessoryView
        self.memoField.inputAccessoryView = self.accessoryView
        self.hashtagField.textField.inputAccessoryView = self.accessoryView
        
        self.containerView.addSubViews([
            self.backgroundView,
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
            self.hashtagCollectionView,
            self.hashtagField,
            self.editButton
        ])
        self.scrollView.addSubview(containerView)
        self.addSubViews([
            self.backButton,
            self.scrollView
        ])
    }
    
    override func bindConstraints() {
        self.backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.height.equalTo(24)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.backButton.snp.bottom).offset(13)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalTo(0)
            make.width.equalToSuperview()
            make.top.equalTo(self.emojiInputView).priority(.high)
            make.bottom.equalTo(self.editButton).offset(20).priority(.high)
        }
        
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView)
        }
        
        self.emojiInputView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(16)
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
        
        self.hashtagCollectionView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.hashtagIcon.snp.bottom).offset(10)
            make.height.equalTo(72)
        }
        
        self.hashtagField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.hashtagCollectionView.snp.bottom).offset(8)
        }
        
        self.editButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.hashtagField.snp.bottom).offset(40)
            make.height.equalTo(50)
        }
    }
    
    func updateNotificationTableViewHeight(by notifications: [(SeepNotification, Bool)]) {
        self.notificationTableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(notifications.count) * WriteNotificationTableViewCell.height)
        }
    }
    
    func setTitlePlaceholder(by category: Category) {
        self.titleField.placeholder = "write_placeholder_title_\(category.rawValue)".localized
    }
    
    func selectHashtag(hashtag: HashtagType) {
        guard let selectedIndex = HashtagType.array.firstIndex(of: hashtag) else { return }
        let indexPath = IndexPath(row: selectedIndex, section: 0)
        
        self.hashtagCollectionView.selectItem(
            at: indexPath,
            animated: true,
            scrollPosition: .centeredHorizontally
        )
    }
    
    fileprivate func setNotificationEnable(isEnable: Bool) {
        self.addNotificationButton.isUserInteractionEnabled = isEnable
        self.notificationTableView.isUserInteractionEnabled = isEnable
        
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            if isEnable {
                self?.addNotificationButton.tintColor = .seepBlue
                self?.addNotificationButton.setTitleColor(.seepBlue, for: .normal)
            } else {
                self?.addNotificationButton.tintColor = .gray3
                self?.addNotificationButton.setTitleColor(.gray3, for: .normal)
            }
        }
    }
}

extension WishEditView: UITextFieldDelegate {
  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let text = textField.text else { return true }
    let newLength = text.count + string.count - range.length

    if newLength >= 18 {
      self.titleField.rx.errorMessage.onNext("write_error_max_length_title".localized)
    } else {
      self.titleField.rx.errorMessage.onNext(nil)
    }

    return newLength <= 18
  }
}


extension Reactive where Base: WishEditView {
    var isNotificationEnable: Binder<Bool> {
        return Binder(self.base) { view, isEnable in
            view.setNotificationEnable(isEnable: isEnable)
            view.notificationSwitch.setOn(isEnable, animated: true)
        }
    }
}
