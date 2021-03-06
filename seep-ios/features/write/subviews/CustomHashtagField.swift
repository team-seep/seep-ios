import UIKit

import RxSwift
import RxCocoa

final class CustomHashtagField: BaseView {
    private let maxLength = 7
    
    let containerView = UIView().then {
        $0.layer.cornerRadius = 6
        $0.backgroundColor = .gray2
    }
    
    let textField = UITextField().then {
        $0.textAlignment = .left
        $0.returnKeyType = .done
        $0.font = .appleExtraBold(size: 14)
        $0.textColor = .gray5
        $0.attributedPlaceholder = NSAttributedString(
            string: "write_placeholder_hashtag".localized,
            attributes: [
                .foregroundColor: UIColor.gray3,
                .font: UIFont.appleExtraBold(size: 14) as Any
            ]
        )
    }
    
    let errorLabel = UILabel().then {
        $0.textColor = .optionRed
        $0.font = .appleRegular(size: 12)
    }
    
    
    override func setup() {
        self.addSubViews([
            self.containerView,
            self.textField,
            self.errorLabel
        ])
        self.backgroundColor = .clear
        self.textField.delegate = self
        self.setupBorder()
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalTo(self.textField).offset(8)
            make.bottom.equalTo(self.textField).offset(8)
        }
        
        self.textField.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(8)
            make.top.equalTo(self.containerView).offset(6)
        }
        
        self.errorLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView)
            make.top.equalTo(self.containerView.snp.bottom).offset(8)
        }
        
        self.snp.makeConstraints { make in
            make.left.top.right.equalTo(self.containerView).priority(.high)
            make.bottom.equalTo(self.errorLabel).offset(10).priority(.high)
        }
    }
    
    func setContentsLayout() {
        self.containerView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalTo(self.textField).offset(8)
            make.bottom.equalTo(self.textField).offset(6)
        }
        
        self.textField.snp.remakeConstraints { make in
            make.left.equalTo(self.containerView).offset(8)
            make.top.equalTo(self.containerView).offset(6)
        }
        
        self.errorLabel.snp.remakeConstraints { make in
            make.left.equalTo(self.containerView)
            make.top.equalTo(self.containerView.snp.bottom).offset(8)
        }
    }
    
    func deselect() {
        guard self.textField.text != "" else { return }
        
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            guard let self = self else { return }
            
            self.containerView.layer.borderWidth = 0
            self.containerView.backgroundColor = .gray2
            self.textField.textColor = .gray5
        }
    }
    
    func setText(text: String) {
        self.textField.text = text
        self.containerView.backgroundColor = .seepBlue
        self.textField.textColor = .gray1
        self.textField.attributedPlaceholder = nil
    }
    
    private func setupBorder() {
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
                    
                    self.textField.textColor = .gray5
                    self.containerView.backgroundColor = .gray1
                    self.containerView.layer.borderColor = UIColor.seepBlue.cgColor
                    self.containerView.layer.borderWidth = 1
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
                    
                    self.containerView.layer.borderWidth = 0
                    if self.textField.text == "" {
                        self.containerView.backgroundColor = .gray2
                    } else {
                        self.containerView.backgroundColor = .seepBlue
                        self.textField.textColor = .gray1
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        self.textField.rx.text.orEmpty
            .asDriver()
            .drive(onNext: { [weak self] text in
                guard let self = self else { return }
                
                self.setupPlaceholder(isEnable: text.isEmpty)
                self.setContentsLayout()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupPlaceholder(isEnable: Bool) {
        if isEnable {
            self.textField.attributedPlaceholder = NSAttributedString(
                string: "write_placeholder_hashtag".localized,
                attributes: [
                    .foregroundColor: UIColor.gray3,
                    .font: UIFont.appleExtraBold(size: 14) as Any
                ]
            )
        } else {
            self.textField.attributedPlaceholder = nil
        }
        
    }
}

extension CustomHashtagField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.trimmingCharacters(in: .newlines).count - range.length
        
        if newLength > self.maxLength {
            self.errorLabel.text = "write_error_max_length_hashtag".localized
        } else {
            self.errorLabel.text = nil
        }
        
        return newLength <= self.maxLength
    }
}

extension Reactive where Base: CustomHashtagField {
    var text: ControlProperty<String?> {
        return base.textField.rx.text
    }
    
    var setText: Binder<String> {
        return Binder(self.base) { view, text in
            base.textField.text = text
            base.setupPlaceholder(isEnable: text.isEmpty)
        }
    }
    
    func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<()> {
        return base.textField.rx.controlEvent(controlEvents)
    }
}

