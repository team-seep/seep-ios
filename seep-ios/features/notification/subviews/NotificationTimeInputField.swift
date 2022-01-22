import UIKit

import RxSwift
import RxCocoa

final class NotificationTimeInputField: BaseView {
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
    
    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 6
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(r: 225, g: 227, b: 231).cgColor
    }
    
    let textField = UITextField().then {
        $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 16)
        $0.textColor = .gray5
        $0.text = "오전 11시 00분"
    }
    
    private let downArrowImage = UIImageView().then {
        $0.image = UIImage(named: "ic_chevron_down")
    }
    
    override func setup() {
        self.addSubViews([
            self.containerView,
            self.textField,
            self.downArrowImage
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
                    
                    self.containerView.layer.borderColor = UIColor.seepBlue.cgColor
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
                    
                    self.containerView.layer.borderColor = UIColor(r: 225, g: 227, b: 231).cgColor
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(self.textField).offset(16)
        }
        
        self.textField.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(16)
            make.top.equalTo(self.containerView).offset(16)
            make.right.equalTo(self.downArrowImage.snp.left).offset(-16)
        }
        
        self.downArrowImage.snp.makeConstraints { make in
            make.centerY.equalTo(self.textField)
            make.right.equalTo(self.containerView).offset(-16)
            make.width.height.equalTo(24)
        }
        
        self.snp.makeConstraints { make in
            make.bottom.equalTo(self.containerView).priority(.high)
        }
    }
}
