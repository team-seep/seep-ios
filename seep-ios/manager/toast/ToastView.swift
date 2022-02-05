import UIKit

final class ToastView: BaseView {
    let messageLabel = UILabel().then {
        $0.font = .appleBold(size: 15)
        $0.textColor = .white
    }
    
    let actionButton = UIButton().then {
        $0.titleLabel?.font = .appleMedium(size: 12)
        $0.setTitleColor(.white, for: .normal)
    }
    
    override func setup() {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.backgroundColor = .gray5
        self.addSubViews([
            self.messageLabel,
            self.actionButton
        ])
    }
    
    override func bindConstraints() {
        self.messageLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.right.equalTo(self.actionButton.snp.left).offset(-20)
            make.centerY.equalToSuperview()
        }
        
        self.actionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
}
