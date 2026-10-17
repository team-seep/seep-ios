import UIKit

final class NotificationView: BaseView {
    let accessoryView = InputAccessoryView(frame: CGRect(
        x: 0,
        y: 0,
        width: 0, // 폭은 시스템이 키보드 폭에 맞춘다 (화면 폭 고정 금지)
        height: 45
    ))
    
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "notification_add_title".localized
        $0.textColor = .black
        $0.font = .appleRegular(size: 16)
    }
    
    let deleteButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_trash"), for: .normal)
        $0.isHidden = true
    }
    
    let scrollView = UIScrollView()
    
    private let containerView = UIView()
    
    private let dateLabel = UILabel().then {
        $0.text = "notification_date".localized
        $0.textColor = .gray4
        $0.font = .appleRegular(size: 14)
    }
    
    let notificationGroupView = NotificationButtonGropView()
    
    private let dividorView = UIView().then {
        $0.backgroundColor = .gray2
    }
    
    private let timeLabel = UILabel().then {
        $0.text = "notification_time".localized
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray4
    }
    
    let timeField = NotificationTimeInputField()
    
    let addButton = UIButton().then {
        $0.titleLabel?.font = .appleExtraBold(size: 16)
        $0.setTitle("notification_add".localized, for: .normal)
        $0.backgroundColor = .tennisGreen
        $0.layer.cornerRadius = 25
        $0.contentEdgeInsets = UIEdgeInsets(top: 13, left: 32, bottom: 13, right: 32)
    }
    
    override func setup() {
        self.backgroundColor = .white
        self.scrollView.addSubViews(self.containerView)
        self.timeField.inputAccessoryView = self.accessoryView
        self.containerView.addSubViews([
            self.dateLabel,
            self.notificationGroupView,
            self.dividorView,
            self.timeLabel,
            self.timeField
        ])
        self.addSubViews([
            self.backButton,
            self.titleLabel,
            self.deleteButton,
            self.scrollView,
            self.addButton
        ])
    }
    
    override func bindConstraints() {
        // 듀오 바깥 화면은 오른쪽 위에 센서·상태 표시 영역(safe area 오른쪽 inset)이 있어 safe area 기준으로 둔다.
        // 아이콘(24pt) 위치는 그대로 두고 터치 영역만 44pt로 넓힌다.
        self.backButton.snp.makeConstraints { make in
            make.leading.equalTo(self.safeAreaLayoutGuide).offset(10)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(3)
            make.width.height.equalTo(44)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.safeAreaLayoutGuide)
            make.centerY.equalTo(self.backButton)
        }
        
        self.deleteButton.snp.makeConstraints { make in
            make.trailing.equalTo(self.safeAreaLayoutGuide).offset(-10)
            make.centerY.equalTo(self.backButton)
            make.width.height.equalTo(44)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.leading.equalTo(self.safeAreaLayoutGuide)
            make.trailing.equalTo(self.safeAreaLayoutGuide)
            make.top.equalTo(self.backButton.snp.bottom).offset(3)
            make.bottom.equalToSuperview()
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
            make.top.equalTo(self.dateLabel).offset(-8).priority(.high)
            make.bottom.equalTo(self.timeField).priority(.high)
        }
        
        self.dateLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }
        
        self.notificationGroupView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.dateLabel.snp.bottom).offset(8)
        }
        
        self.dividorView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(1)
            make.top.equalTo(self.notificationGroupView.snp.bottom).offset(20)
        }
        
        self.timeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.dividorView.snp.bottom).offset(36)
        }
        
        self.timeField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.timeLabel.snp.bottom).offset(8)
        }
        
        self.addButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
        }
    }
    
    func bind(notification: SeepNotification) {
        self.notificationGroupView.selectRadioButton(type: notification.type)
        self.timeField.setTime(date: notification.time)
    }
    
    func showWriteButton() {
      UIView.transition(with: self.addButton, duration: 0.3, options: .curveEaseInOut) {
        self.addButton.alpha = 1.0
        self.addButton.transform = .identity
      }
    }
    
    func hideWriteButton() {
      UIView.transition(with: self.addButton, duration: 0.3, options: .curveEaseInOut) {
        self.addButton.alpha = 0.0
        self.addButton.transform = .init(translationX: 0, y: 100)
      }
    }
}
