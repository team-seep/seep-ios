import UIKit

import Gifu

final class SigninView: BaseView {
    private let gifView = GIFImageView().then {
        $0.animate(withGIFNamed: "intro", loopCount: 0)
    }
    
    private let titleLabel = UILabel().then {
        let text = "membership_title".localized
        let attributedString = NSMutableAttributedString(string: text)
        let boldTextRange = (text as NSString).range(of: "하고 싶었던 것들")
        let style = NSMutableParagraphStyle()
        
        style.maximumLineHeight = 34
        style.minimumLineHeight = 34
        
        attributedString.addAttribute(
            .font,
            value: UIFont.appleBold(size: 26) as Any,
            range: boldTextRange
        )
        attributedString.addAttribute(
            .paragraphStyle,
            value: style as Any,
            range: (text as NSString).range(of: text)
        )
        $0.textColor = .gray5
        $0.font = .appleLight(size: 26)
        $0.attributedText = attributedString
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let descriptionLabel = UILabel().then {
        $0.text = "membership_description".localized
        $0.font = .appleRegular(size: 14)
        $0.textColor = .gray4
        $0.numberOfLines = 0
        $0.setLineHeight(lineHeight: 20)
        $0.textAlignment = .center
    }
    let appleButton = SocialButton(socialType: .apple)
    
    let kakaoButton = SocialButton(socialType: .kakao)
    
    let startWithoutSigninButton = UIButton().then {
        $0.setTitle("membership_start_without_signin".localized, for: .normal)
        $0.setTitleColor(.gray4, for: .normal)
        $0.titleLabel?.font = .appleSemiBold(size: 16)
    }
    
    override func setup() {
        self.backgroundColor = UIColor(r: 246, g: 247, b: 249)
        self.addSubViews([
            self.gifView,
            self.titleLabel,
            self.descriptionLabel,
            self.appleButton,
            self.kakaoButton,
            self.startWithoutSigninButton
        ])
    }
    
    override func bindConstraints() {
        self.gifView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.titleLabel.snp.top).offset(-16)
            make.width.equalTo(240)
            make.height.equalTo(240)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.descriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
        
        self.startWithoutSigninButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-23)
        }
        
        self.kakaoButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(50)
            make.bottom.equalTo(self.startWithoutSigninButton.snp.top).offset(-21)
        }
        
        self.appleButton.snp.makeConstraints { make in
            make.left.equalTo(self.kakaoButton)
            make.right.equalTo(self.kakaoButton)
            make.height.equalTo(self.kakaoButton)
            make.bottom.equalTo(self.kakaoButton.snp.top).offset(-8)
        }
    }
}
