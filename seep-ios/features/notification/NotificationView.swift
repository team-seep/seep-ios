import UIKit

final class NotificationView: BaseView {
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
    }
    
    private let scrollView = UIScrollView()
    
    private let containerView = UIView()
    
    private let dateLabel = UILabel().then {
        $0.text = "notification_date".localized
        $0.textColor = .gray4
        $0.font = .appleRegular(size: 14)
    }
    
    private let notificationGroupView = NotificationButtonGropView()
    
    private let dividorView = UIView().then {
        $0.backgroundColor = .gray2
    }
    
    private let timeLabel = UILabel().then {
        $0.text = "notification_time".localized
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray4
    }
    
    override func setup() {
        self.backgroundColor = .white
        self.scrollView.addSubViews(self.containerView)
        self.containerView.addSubViews([
            self.dateLabel,
            self.notificationGroupView,
            self.dividorView,
            self.timeLabel
        ])
        self.addSubViews([
            self.backButton,
            self.titleLabel,
            self.deleteButton,
            self.scrollView
        ])
    }
    
    override func bindConstraints() {
        self.backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.height.equalTo(24)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.backButton)
        }
        
        self.deleteButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.backButton)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.backButton.snp.bottom).offset(13)
            make.bottom.equalToSuperview()
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
            make.top.equalTo(self.dateLabel).offset(-8).priority(.high)
            make.bottom.equalTo(self.timeLabel).priority(.high)
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
    }
}
