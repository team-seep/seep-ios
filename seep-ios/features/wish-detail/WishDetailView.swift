import UIKit

import ISEmojiView
import RxSwift
import RxCocoa

final class WishDetailView: BaseView {
    let tapBackground = UITapGestureRecognizer()
    
    let accessoryView = InputAccessoryView(frame: CGRect(
        x: 0,
        y: 0,
        width: UIScreen.main.bounds.width,
        height: 45
    ))
    
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    let moreButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_more"), for: .normal)
    }
    
    let cancelButton = UIButton().then {
        $0.setTitle("detail_cancel".localized, for: .normal)
        $0.setTitleColor(.gray3, for: .normal)
        $0.titleLabel?.font = .appleRegular(size: 16)
        $0.alpha = 0.0
    }
    
    let scrollView = UIScrollView().then {
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
    }
    
    let containerView = UIView()
    
    let emojiInputView = EmojiInputView()
    
    let categoryView = CategoryView()
    
    let titleField = TextInputField(
        iconImage: UIImage(named: "ic_title"),
        title: "write_header_title".localized,
        placeholder: nil
    )
    
    let dateField = TextInputField(
        iconImage: UIImage(named: "ic_calendar"),
        title: "write_header_date".localized,
        placeholder: "write_placeholder_date_enable".localized
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
        layout.estimatedItemSize = HashtagCollectionViewCell.estimatedSize
        
        $0.collectionViewLayout = layout
        $0.register(
            HashtagCollectionViewCell.self,
            forCellWithReuseIdentifier: HashtagCollectionViewCell.registerID
        )
        $0.backgroundColor = .clear
    }
    
    let hashtagField = CustomHashtagField()
    
    let editButton = EditButton()
    
    let toast = ToastView(frame: CGRect(x: 20, y: -58, width: UIScreen.main.bounds.width - 40, height: 58)).then {
        $0.actionButton.isHidden = true
        $0.messageLabel.text = "share_photo_success".localized
    }
    
    
    override func setup() {
        self.backgroundColor = .white
        self.addGestureRecognizer(self.tapBackground)
        
        self.emojiInputView.inputAccessoryView = self.accessoryView
        self.titleField.inputAccessoryView = self.accessoryView
        self.dateField.inputAccessoryView = self.accessoryView
        self.memoField.inputAccessoryView = self.accessoryView
        self.hashtagField.textField.inputAccessoryView = self.accessoryView
        
        self.containerView.addSubViews([
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
            self.moreButton,
            self.cancelButton,
            self.scrollView
        ])
    }
    
    override func bindConstraints() {
        self.backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.height.equalTo(24)
        }
        
        self.moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.backButton)
        }
        
        self.cancelButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.backButton)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.backButton.snp.bottom).offset(13)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(self.emojiInputView).priority(.high)
            make.bottom.equalTo(self.editButton).offset(20).priority(.high)
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
    
    func bind(wish: Wish, mode: DetailMode) {
        self.emojiInputView.setEmoji(emoji: wish.emoji)
        self.categoryView.moveActiveButton(category: wish.category)
        self.titleField.setText(text: wish.title)
        self.emojiInputView.isUserInteractionEnabled = (mode == .fromHome)
        self.categoryView.isUserInteractionEnabled = (mode == .fromHome)
        self.titleField.isUserInteractionEnabled = (mode == .fromHome)
        self.dateField.isUserInteractionEnabled = (mode == .fromHome)
        self.memoField.isUserInteractionEnabled = (mode == .fromHome)
        self.hashtagField.isUserInteractionEnabled = (mode == .fromHome)
    }
    
    func setTitlePlaceholder(by category: Category) {
        self.titleField.placeholder = "write_placeholder_title_\(category.rawValue)".localized
    }
    
    func setEditable(isEditable: Bool) {
        self.emojiInputView.isEditable = isEditable
        self.categoryView.isEditable = isEditable
        self.editButton.alpha = isEditable ? 1.0 : 0.0
        self.cancelButton.alpha = isEditable ? 1.0 : 0.0
        self.moreButton.alpha = isEditable ? 0.0 : 1.0
        self.dateSwitchLabel.alpha = isEditable ? 1.0 : 0.0
        self.dateSwitch.alpha = isEditable ? 1.0 : 0.0
        self.notificationSwitchLabel.alpha = isEditable ? 1.0 : 0.0
        self.notificationSwitch.alpha = isEditable ? 1.0 : 0.0
        self.memoField.isEditable = isEditable
    }
    
    func updateNotificationTableViewHeight(by notifications: [(SeepNotification?, Bool)]) {
        self.notificationTableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(notifications.count) * WriteNotificationTableViewCell.height)
        }
        
        if notifications[0].0 == nil {
            self.addNotificationButton.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            self.addNotificationButton.isHidden = true
        } else {
            self.addNotificationButton.snp.updateConstraints { make in
                make.height.equalTo(32)
            }
            self.addNotificationButton.isHidden = false
        }
    }
    
    func selectHashTag(index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        self.hashtagCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
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
    
    func showFinishToast() {
        let window = UIApplication.shared.windows[0]
        
        self.addSubViews(toast)
        
        UIView.transition(with: toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
            self?.toast.transform = .init(translationX: 0, y: 14 + 58)
        } completion: { isComplete in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                UIView.transition(with: self.toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
                    self?.toast.transform = .identity
                } completion: { [weak self] isCompleteRemove in
                    if isCompleteRemove {
                        self?.toast.removeFromSuperview()
                    }
                }
            }
        }
    }
}

extension Reactive where Base: WishDetailView{
    var isEditable: Binder<Bool> {
        return Binder(self.base) { view, isEditable in
            view.setEditable(isEditable: isEditable)
        }
    }
    
    var isNotificationEnable: Binder<Bool> {
        return Binder(self.base) { view, isEnable in
            view.setNotificationEnable(isEnable: isEnable)
            view.notificationSwitch.setOn(isEnable, animated: true)
        }
    }
}
