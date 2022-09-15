import UIKit

final class SignupView: BaseView {
    private let tapBackground = UITapGestureRecognizer()
    
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    private let scrollView = UIScrollView()
    
    private let containerView = UIView()
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func setup() {
        self.addGestureRecognizer(self.tapBackground)
        self.backgroundColor = .gray1
        self.containerView.addSubViews([
            self.titleLabel,
            self.profileView,
            self.profileLabel,
            self.profileSwitch,
            self.nicknameLabel,
            self.nicknameField,
        ])
        self.scrollView.addSubViews(self.containerView)
        self.addSubViews([
            self.backButton,
            self.scrollView,
            self.signupButton
        ])
        self.setupKeyboardNotification()
        self.tapBackground.rx.event
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.endEditing(false)
            })
            .disposed(by: self.disposeBag)
        self.nicknameField.rx.state
            .asDriver()
            .drive(onNext: { [weak self] state in
                switch state {
                case .normal:
                    self?.nicknameLabel.textColor = .gray5
                    
                case .active:
                    self?.nicknameLabel.textColor = .seepBlue
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(13)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        
        self.scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.backButton.snp.bottom).offset(13)
            make.bottom.equalToSuperview()
        }
        
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(UIScreen.main.bounds.width)
            make.top.equalTo(self.titleLabel).priority(.high)
            make.bottom.equalTo(self.nicknameField).priority(.high)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(29)
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
    
    private func setupKeyboardNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let keyboardFrame
                = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardFrame.cgRectValue
        let keyboardViewEndFrame = self.convert(keyboardScreenEndFrame, from: self.window)
        
        self.scrollView.contentInset.bottom = keyboardViewEndFrame.height
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        self.scrollView.contentInset.bottom = .zero
    }
}
