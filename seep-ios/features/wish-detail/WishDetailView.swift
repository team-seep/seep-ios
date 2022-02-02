import UIKit

import ISEmojiView
import RxSwift
import RxCocoa

final class WishDetailView: BaseView {
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    let moreButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_more"), for: .normal)
    }
    
//    let cancelButton = UIButton().then {
//        $0.setTitle("detail_cancel".localized, for: .normal)
//        $0.setTitleColor(.gray3, for: .normal)
//        $0.titleLabel?.font = .appleRegular(size: 16)
//        $0.alpha = 0.0
//    }
    
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
    
    private let notificationIcon = UIImageView().then {
        $0.image = UIImage(named: "ic_notification_normal")
    }
    
    private let notificationLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "write_header_notification".localized
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
    
    override func setup() {
        self.backgroundColor = .white
        self.containerView.addSubViews([
            self.emojiInputView,
            self.categoryView,
            self.titleField,
            self.dateField,
            self.notificationIcon,
            self.notificationLabel,
            self.notificationTableView,
            self.memoIcon,
            self.memoLabel,
            self.memoField,
            self.hashtagIcon,
            self.hashtagLabel,
            self.hashtagCollectionView,
            self.hashtagField
        ])
        self.scrollView.addSubview(containerView)
        
        self.addSubViews([
            self.backButton,
            self.moreButton,
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
        
        self.scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.backButton.snp.bottom).offset(13)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(self.emojiInputView).priority(.high)
            make.bottom.equalTo(self.hashtagField).offset(20).priority(.high)
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
        
        self.notificationIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.dateField.snp.bottom).offset(26)
            make.width.height.equalTo(16)
        }
        
        self.notificationLabel.snp.makeConstraints { make in
            make.left.equalTo(self.notificationIcon.snp.right).offset(4)
            make.centerY.equalTo(self.notificationIcon)
        }
        
        self.notificationTableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.notificationIcon.snp.bottom).offset(2)
            make.height.equalTo(56)
        }
        
        self.memoIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.notificationTableView.snp.bottom).offset(26)
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
    }
    
    fileprivate func bind(wish: Wish) {
        self.emojiInputView.setEmoji(emoji: wish.emoji)
        self.emojiInputView.isEditable = false
        self.categoryView.moveActiveButton(category: wish.category)
        self.titleField.setText(text: wish.title)
        self.dateField.setDate(date: wish.endDate)
        
        let notifications: [SeepNotification?] = wish.notifications.isEmpty ? [nil] : wish.notifications
        
        Observable.just(notifications)
            .do(onNext: { [weak self] notifications in
                self?.updateNotificationTableViewHeight(by: notifications)
            })
            .asDriver(onErrorJustReturn: [nil])
            .drive(self.notificationTableView.rx.items(
                cellIdentifier: WriteNotificationTableViewCell.registerId,
                cellType: WriteNotificationTableViewCell.self
            )) { row, notification, cell in
                cell.bind(notification: notification, isEnable: true)
            }
            .disposed(by: self.disposeBag)
        
        self.memoField.setText(text: wish.memo)
        
        Observable.just(HashtagType.array)
            .asDriver(onErrorJustReturn: [])
            .drive(self.hashtagCollectionView.rx.items(
                    cellIdentifier: HashtagCollectionViewCell.registerID,
                    cellType: HashtagCollectionViewCell.self
            )) { row, hashtagType, cell in
                cell.bind(type: hashtagType)
            }
            .disposed(by: self.disposeBag)
    }
    
    func updateNotificationTableViewHeight(by notifications: [SeepNotification?]) {
        self.notificationTableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(notifications.count) * WriteNotificationTableViewCell.height)
        }
    }
    
    func selectHashTag(index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        self.hashtagCollectionView.selectItem(
            at: indexPath,
            animated: false,
            scrollPosition: .centeredHorizontally
        )
    }
}

extension Reactive where Base: WishDetailView{
    var wish: Binder<Wish> {
        return Binder(self.base) { view, wish in
            view.bind(wish: wish)
        }
    }
}
