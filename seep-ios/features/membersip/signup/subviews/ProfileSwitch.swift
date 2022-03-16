import UIKit

final class ProfileSwitch: BaseView {
    private let backgroundView = UIView().then {
        $0.layer.cornerRadius = 24
        $0.backgroundColor = UIColor(r: 232, g: 246, b: 255)
    }
    
    private let indicatorView = UIView().then {
        $0.backgroundColor = .seepBlue
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.blue.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowOpacity = 0.15
    }
    
    private let firstButton = UIButton().then {
        $0.setTitle("signup_nickname_first".localized, for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .appleExtraBold(size: 14)
    }
    
    private let secondButton = UIButton().then {
        $0.setTitle("signup_nickname_second".localized, for: .normal)
        $0.setTitleColor(.gray4, for: .normal)
        $0.titleLabel?.font = .appleRegular(size: 14)
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.backgroundView,
            self.indicatorView,
            self.firstButton,
            self.secondButton
        ])
    }
    
    override func bindConstraints() {
        self.backgroundView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.height.equalTo(48)
        }
        
        self.firstButton.snp.makeConstraints { make in
            make.left.equalTo(self.backgroundView).offset(8)
            make.top.equalTo(self.backgroundView).offset(8)
            make.right.equalTo(self.snp.centerX).offset(-4)
            make.bottom.equalTo(self.backgroundView).offset(-8)
        }
        
        self.secondButton.snp.makeConstraints { make in
            make.left.equalTo(self.snp.centerX).offset(4)
            make.top.equalTo(self.backgroundView).offset(8)
            make.right.equalTo(self.backgroundView).offset(-8)
            make.bottom.equalTo(self.backgroundView).offset(-8)
        }
        
        self.indicatorView.snp.makeConstraints { make in
            make.edges.equalTo(self.firstButton)
        }
        
        self.snp.makeConstraints { make in
            make.edges.equalTo(self.backgroundView).priority(.high)
        }
    }
}
