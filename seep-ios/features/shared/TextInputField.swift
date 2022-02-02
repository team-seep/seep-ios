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
    
    private let iconImage = UIImageView().then {
        $0.tintColor = .gray5
    }
    
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
    
    init(
        iconImage: UIImage?,
        title: String,
        placeholder: String?
    ) {
        self.iconImage.image = iconImage?.withRenderingMode(.alwaysTemplate)
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
                    
                    self.iconImage.tintColor = .seepBlue
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
                    
                    self.iconImage.tintColor = .gray5
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
            make.top.equalTo(self.iconImage.snp.bottom).offset(10)
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
    
    func setText(text: String) {
        self.textField.text = text
    }
    
    func setDate(date: Date?) {
        if let date = date {
            let dateString = DateUtils.toString(format: "yyyy년 MM월 dd일 eeee 까지", date: date)
            
            self.setText(text: dateString)
        } else {
            self.placeholder = "write_placeholder_date_disable".localized
        }
    }
    
    fileprivate func showError(message: String?) {
        if let message = message {
            self.addSubViews(self.errorLabel)
            self.errorLabel.text = message
            self.errorLabel.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalTo(self.containerView.snp.bottom).offset(8)
            }
            
            self.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView).offset(10).priority(.high)
            }
        } else {
            self.errorLabel.removeFromSuperview()
            self.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView).priority(.high)
            }
        }
    }
    
    fileprivate func setDateEnable(isEnable: Bool) {
        self.isUserInteractionEnabled = isEnable
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            if isEnable {
                self?.textField.attributedPlaceholder = NSAttributedString(
                    string: "write_placeholder_date_enable".localized,
                    attributes: [.foregroundColor: UIColor.gray3]
                )
            } else {
                self?.textField.text = nil
                self?.textField.attributedPlaceholder = NSAttributedString(
                    string: "write_placeholder_date_disable".localized,
                    attributes: [.foregroundColor: UIColor.gray5]
                )
            }
            self?.textField.tintColor = .clear
        }
    }
    
    private func setPlaceholder(
        placeholder: String?,
        color: UIColor = .gray3
    ) {
        guard let placeholder = placeholder else { return }
        self.textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: color]
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
    
    var isDateEnable: Binder<Bool> {
        return Binder(self.base) { view, isEnable in
            view.setDateEnable(isEnable: isEnable)
        }
    }
    
    func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<()> {
        return base.textField.rx.controlEvent(controlEvents)
    }
}
