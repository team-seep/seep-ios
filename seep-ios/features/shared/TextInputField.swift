import UIKit

import RxSwift
import RxCocoa

final class TextInputField: BaseView {
    override var inputAccessoryView: UIView? {
        set {
            self.textField.inputAccessoryView = newValue
        }
        get {
            return self.textField.inputAccessoryView
        }
    }
    
    override var inputView: UIView? {
        get {
            return self.textField.inputView
        }
        set {
            self.textField.inputView = newValue
        }
    }
    
    var placeholder: String? {
        get {
            return self.textField.placeholder
        }
        set {
            self.setPlaceholder(placeholder: newValue)
        }
    }
    
    private let containerView = UIView().then {
        $0.backgroundColor = .gray2
        $0.layer.cornerRadius = 6
    }
    
    private let iconImage = UIImageView()
    
    private let titleLabel = UILabel().then {
        $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
        $0.textColor = .gray5
    }
    
    let textField = UITextField().then {
      $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 16)
      $0.textColor = .gray5
    }
    
    private let errorLabel = UILabel().then {
        $0.textColor = .optionRed
        $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 12)
    }
    
    private let normalIcon: UIImage?
    private let focusedIcon: UIImage?
    
    init(
        normalIcon: UIImage?,
        focusedIcon: UIImage?,
        title: String,
        placeholder: String?
    ) {
        self.normalIcon = normalIcon
        self.focusedIcon = focusedIcon
        self.iconImage.image = normalIcon
        self.titleLabel.text = title
        self.textField.placeholder = placeholder
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.containerView,
            self.iconImage,
            self.titleLabel,
            self.textField
        ])
        
        self.textField.rx
            .controlEvent(.editingDidBegin)
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                UIView.transition(
                    with: self,
                    duration: 0.3,
                    options: .transitionCrossDissolve
                ) { [weak self] in
                    guard let self = self else { return }
                    
                    self.iconImage.image = self.focusedIcon
                    self.containerView.backgroundColor = .white
                    self.containerView.layer.borderColor = UIColor.seepBlue.cgColor
                    self.containerView.layer.borderWidth = 1
                    self.titleLabel.textColor = .seepBlue
                }
            })
            .disposed(by: self.disposeBag)
        self.textField.rx
            .controlEvent(.editingDidEnd)
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                UIView.transition(
                    with: self,
                    duration: 0.3,
                    options: .transitionCrossDissolve
                ) { [weak self] in
                    guard let self = self else { return }
                    
                    self.iconImage.image = self.normalIcon
                    self.titleLabel.textColor = .gray5
                    self.containerView.layer.borderWidth = 0
                    self.containerView.backgroundColor = .gray2
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.iconImage.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.iconImage.snp.right).offset(4)
            make.centerY.equalTo(self.iconImage)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.textField).offset(14)
            make.top.equalTo(self.iconImage.snp.bottom).offset(13)
        }
        
        self.textField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(self.containerView).offset(16)
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(self.iconImage).priority(.high)
            make.bottom.equalTo(self.containerView).priority(.high)
        }
    }
    
    fileprivate func showError(message: String?) {
        if let message = message {
            self.addSubViews(self.errorLabel)
            self.errorLabel.text = message
            self.containerView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.textField).offset(16)
                make.top.equalTo(self.titleLabel).offset(8)
            }
            self.errorLabel.snp.makeConstraints { make in
                make.left.bottom.equalToSuperview()
                make.top.equalTo(self.containerView.snp.bottom).offset(8)
            }
        } else {
            self.errorLabel.removeFromSuperview()
            self.containerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.bottom.equalTo(self.textField).offset(14)
                make.top.equalTo(self.iconImage.snp.bottom).offset(13)
            }
        }
    }
    
    private func setPlaceholder(placeholder: String?) {
        guard let placeholder = placeholder else { return }
        self.textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        self.textField.tintColor = .clear
    }
}

extension Reactive where Base: TextInputField {
    var text: ControlProperty<String?> {
        return base.textField.rx.text
    }
    
    var errorMessage: Binder<String?> {
        return Binder(self.base) { view, message in
            view.showError(message: message)
        }
    }
}
