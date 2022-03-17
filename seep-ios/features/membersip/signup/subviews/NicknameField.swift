import UIKit

final class NicknameField: BaseView {
    private let nicknameBackground = UIView().then {
        $0.layer.cornerRadius = 6
        $0.backgroundColor = .gray2
    }
    
    private let nicknameField = UITextField().then {
        $0.font = .appleRegular(size: 16)
        $0.textColor = .gray5
        
        let placeholder = NSMutableAttributedString(
            string: "signup_nickname_placeholder".localized,
            attributes: [.foregroundColor: UIColor.gray3 as Any]
        )
        $0.attributedPlaceholder = placeholder
    }
    
    private let hintLabel = UILabel().then {
        $0.textColor = .gray4
        $0.font = .appleRegular(size: 14)
        $0.text = "signup_nickname_hint".localized
    }
    
    override func setup() {
        self.addSubViews([
            self.nicknameBackground,
            self.nicknameField,
            self.hintLabel
        ])
        self.nicknameField.delegate = self
    }
    
    override func bindConstraints() {
        self.nicknameBackground.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(56)
        }
        
        self.nicknameField.snp.makeConstraints { make in
            make.left.equalTo(self.nicknameBackground).offset(16)
            make.right.equalTo(self.nicknameBackground).offset(-16)
            make.centerY.equalTo(self.nicknameBackground)
        }
        
        self.hintLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.nicknameBackground.snp.bottom).offset(8)
        }
        
        self.snp.makeConstraints { make in
            make.left.equalTo(self.nicknameBackground).priority(.high)
            make.top.equalTo(self.nicknameBackground).priority(.high)
            make.right.equalTo(self.nicknameBackground).priority(.high)
            make.bottom.equalTo(self.hintLabel).priority(.high)
        }
    }
}

extension NicknameField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        
        self.hintLabel.isHidden = newLength != 0
        if newLength >= 8 {
            self.hintLabel.text = "signup_nickname_error".localized
            self.hintLabel.textColor = .optionRed
            self.hintLabel.isHidden = false
        } else {
            self.hintLabel.text = "signup_nickname_hint".localized
            self.hintLabel.textColor = .gray4
        }
        
        return newLength <= 8
    }
}
