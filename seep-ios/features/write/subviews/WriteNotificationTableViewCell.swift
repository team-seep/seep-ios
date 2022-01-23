import UIKit

import RxSwift
import RxCocoa

final class WriteNotificationTableViewCell: BaseTableViewCell {
    static let registerId = "\(WriteNotificationTableViewCell.self)"
    static let height: CGFloat = 64
    
    private let containerView = UIView().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(r: 225, g: 227, b: 231).cgColor
        $0.layer.cornerRadius = 6
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .appleRegular(size: 16)
        $0.textColor = .gray5
    }
    
    private let rightArrowImage = UIImageView().then {
        $0.image = UIImage(named: "ic_arrow_right")?.withRenderingMode(.alwaysTemplate)
    }
    
    fileprivate let buttonArea = UIButton()
    
    override func setup() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.contentView.isUserInteractionEnabled = false
        self.addSubViews([
            self.containerView,
            self.titleLabel,
            self.rightArrowImage,
            self.buttonArea
        ])
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(16)
            make.centerY.equalTo(self.containerView)
            make.right.equalTo(self.rightArrowImage.snp.left).offset(-16)
        }
        
        self.rightArrowImage.snp.makeConstraints { make in
            make.centerY.equalTo(self.containerView)
            make.right.equalTo(self.containerView).offset(-16)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        
        self.buttonArea.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView)
        }
    }
    
    func bind(notification: SeepNotification, isEnable: Bool) {
        self.titleLabel.text = "\(notification.type.toString), \(notification.time.toString(format: "a h시 mm분"))"
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            if isEnable {
                self?.containerView.backgroundColor = .gray1
                self?.titleLabel.textColor = .gray5
                self?.rightArrowImage.tintColor = .gray5
            } else {
                self?.containerView.backgroundColor = .gray2
                self?.titleLabel.textColor = .gray3
                self?.rightArrowImage.tintColor = .gray3
            }
        }
    }
}

extension Reactive where Base: WriteNotificationTableViewCell {
    var tap: ControlEvent<Void> {
        return base.buttonArea.rx.tap
    }
}
