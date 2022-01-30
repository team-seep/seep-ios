import UIKit

import RxSwift
import RxCocoa

final class TextInputView: BaseView {
    var isEditable: Bool = true {
        didSet {
            if self.isEditable {
                if self.textView.text == "detail_memo_empty".localized {
                    self.textView.text = "wrtie_placeholder_memo".localized
                }
                self.textView.textColor = .gray5
                self.textView.snp.updateConstraints { make in
                    make.height.equalTo(82)
                }
            } else {
                if self.textView.text == "wrtie_placeholder_memo".localized {
                    self.textView.text = "detail_memo_empty".localized
                    self.textView.snp.updateConstraints { make in
                        make.height.equalTo(24)
                    }
                }
                self.textView.textColor = .gray3
            }
        }
    }
    
    override var inputAccessoryView: UIView? {
        set {
            self.textView.inputAccessoryView = newValue
        }
        get {
            return self.textView.inputAccessoryView
        }
    }
    
    private let containerView = UIView().then {
        $0.backgroundColor = .gray2
        $0.layer.cornerRadius = 6
    }
    
    fileprivate let textView = UITextView().then {
        $0.font = .appleRegular(size: 16)
        $0.backgroundColor = .clear
        $0.text = "wrtie_placeholder_memo".localized
        $0.textColor = .gray3
        $0.textContainerInset = .zero
    }
    
    fileprivate let errorLabel = UILabel().then {
        $0.textColor = .optionRed
        $0.font = .appleRegular(size: 12)
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.containerView,
            self.textView
        ])
        self.textView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(self.textView).offset(16)
        }
        
        self.textView.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(10)
            make.right.equalTo(self.containerView).offset(-10)
            make.top.equalTo(self.containerView).offset(16)
            make.height.equalTo(82)
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(self.containerView).priority(.high)
            make.bottom.equalTo(self.containerView).priority(.high)
        }
    }
    
    func showError(message: String?) {
        if let message = message {
            self.addSubViews([self.errorLabel])
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
    
    fileprivate func setText(text: String?) {
        if text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            if self.isEditable {
                if !self.textView.isFirstResponder {
                    self.textView.text = "wrtie_placeholder_memo".localized
                }
            } else {
                self.textView.text = "detail_memo_empty".localized
            }
            self.textView.textColor = .gray3
        } else {
            self.textView.text = text
            self.textView.textColor = .gray5
        }
    }
}

extension Reactive where Base: TextInputView {
    var text: ControlProperty<String?> {
        return base.textView.rx.text
    }
    
    var setText: Binder<String?> {
        return Binder(self.base) { view, text in
            view.setText(text: text)
        }
    }
    
    var errorMessage: Binder<String?> {
        return Binder(self.base) { view, message in
            view.showError(message: message)
        }
    }
    
    var didBeginEditing: ControlEvent<()> {
        return base.textView.rx.didBeginEditing
    }
}

extension TextInputView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            if textView.text == "wrtie_placeholder_memo".localized
                || textView.text == "detail_memo_empty".localized {
                textView.text = ""
            }
            textView.textColor = .gray5
            
            self?.containerView.backgroundColor = .white
            self?.containerView.layer.borderColor = UIColor.seepBlue.cgColor
            self?.containerView.layer.borderWidth = 1
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) { [weak self] in
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textView.text = "wrtie_placeholder_memo".localized
                textView.textColor = .gray3
            }
            
            self?.containerView.layer.borderWidth = 0
            self?.containerView.backgroundColor = .gray2
        }
    }
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard let str = textView.text else { return true }
        let newLength = str.count + text.count - range.length
        
        if newLength >= 300 {
            self.rx.errorMessage.onNext("write_error_max_length_memo".localized)
        } else {
            self.rx.errorMessage.onNext(nil)
        }
        
        return newLength <= 300
    }
}
