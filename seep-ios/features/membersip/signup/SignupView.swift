import UIKit

final class SignupView: BaseView {
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .appleLight(size: 22)
        $0.textColor = .gray5
        $0.text = "signup_title".localized
        $0.setLineHeight(lineHeight: 30)
        $0.numberOfLines = 0
    }
    
    private let profileLabel = UILabel().then {
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray5
        $0.text = "signup_profile_title".localized
    }
    
    let profileView = ProfileView()
    
    let profileSwitch = ProfileSwitch()
    
    private let nicknameLabel = UILabel().then {
        $0.textColor = .gray5
        $0.text = "signup_nickname".localized
        $0.font = .appleRegular(size: 14)
    }
    
    let nicknameField = NicknameField()
    
    let signupButton = WriteButton()
    
    override func setup() {
        self.backgroundColor = .gray1
        self.addSubViews([
            self.backButton,
            self.titleLabel,
            self.profileView,
            self.profileLabel,
            self.profileSwitch,
            self.nicknameLabel,
            self.nicknameField,
            self.signupButton
        ])
    }
    
    override func bindConstraints() {
        self.backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.backButton.snp.bottom).offset(29)
        }
        
        self.profileView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(70)
        }
        
        self.profileLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.profileView.snp.bottom).offset(40)
        }
        
        self.profileSwitch.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.profileLabel.snp.bottom).offset(8)
        }
        
        self.nicknameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.profileSwitch.snp.bottom).offset(24)
        }
        
        self.nicknameField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.nicknameLabel.snp.bottom).offset(8)
        }
        
        self.signupButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }
    }
}
