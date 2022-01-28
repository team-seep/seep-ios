import UIKit

import RxSwift
import RxCocoa
import ISEmojiView

final class EmojiInputView: BaseView {
    var isEditable: Bool = true {
        didSet {
            self.randomButton.alpha = isEditable ? 1.0 : 0.0
        }
    }
    
    override var inputAccessoryView: UIView? {
        set {
            self.emojiField.inputAccessoryView = newValue
        }
        get {
            return self.emojiField.inputAccessoryView
        }
    }
    
    private let emojiBackground = UIImageView().then {
        $0.image = UIImage(named: "img_emoji_empty")
        $0.layer.cornerRadius = 36
    }
    
    fileprivate let emojiField = UITextField().then {
        $0.tintColor = .clear
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 36)
    }
    
    private let randomButton = UIButton().then {
        $0.setTitle("write_random_button".localized, for: .normal)
        $0.layer.cornerRadius = 10
        $0.backgroundColor = UIColor.seepBlue
        $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 12)
        $0.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
    }
    
    fileprivate let randomTooltipView = PaddingLabel(
        topInset: 6,
        bottomInset: 6,
        leftInset: 8,
        rightInset: 8
    ).then {
        $0.font = .appleBold(size: 11)
        $0.textColor = .gray1
        $0.backgroundColor = .gray5
        $0.layer.cornerRadius = 5
        $0.clipsToBounds = true
        $0.numberOfLines = 0
        $0.text = "detail_random_info".localized
        $0.isHidden = true
    }
    
    override func setup() {
        self.addSubViews([
            self.emojiBackground,
            self.emojiField,
            self.randomButton,
            self.randomTooltipView
        ])
        self.emojiField.delegate = self
        self.emojiField.rx
            .controlEvent(.editingDidBegin)
            .asDriver()
            .drive(onNext: {
                FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .disposed(by: self.disposeBag)
        self.setupEmojiKeyboard()
        self.randomButton.rx.tap
            .asDriver()
            .do(onNext: { _ in
              FeedbackUtils.feedbackInstance.impactOccurred()
            })
            .drive(onNext: { [weak self] in
                let randomEmoji = self?.generateRandomEmoji()
                
                self?.emojiField.text = randomEmoji
                self?.setEmojiBackground(isEmpty: false)
            })
            .disposed(by: self.disposeBag)
        self.emojiField.rx.text.orEmpty
            .asDriver()
            .drive(onNext: { [weak self] emoji in
                self?.setEmojiBackground(isEmpty: emoji.isEmpty)
            })
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.emojiBackground.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(72)
            make.top.bottom.equalToSuperview()
        }
        
        self.emojiField.snp.makeConstraints { make in
            make.width.height.equalTo(72)
            make.center.equalTo(self.emojiBackground)
        }
        
        self.randomButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalTo(self.emojiBackground.snp.right).offset(4)
            make.bottom.equalTo(self.emojiBackground)
        }
        
        self.randomTooltipView.snp.makeConstraints { make in
            make.left.equalTo(self.randomButton.snp.left)
            make.bottom.equalTo(self.randomButton.snp.top).offset(-4)
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(self.emojiBackground).priority(.high)
            make.bottom.equalTo(self.emojiBackground).priority(.high)
        }
    }
    
    func showRandomEmojiTooltip() {
        self.randomTooltipView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            UIView.transition(
                with: self.randomTooltipView,
                duration: 0.3,
                options: .curveEaseInOut
            ) { [weak self] in
                self?.randomTooltipView.alpha = 0
            }
        }
    }
    
    func setEmoji(emoji: String) {
        self.emojiField.text = emoji
    }
    
    private func setEmojiBackground(isEmpty: Bool) {
        if isEmpty {
            self.emojiBackground.image = UIImage(named: "img_emoji_empty")
            self.emojiBackground.backgroundColor = .clear
        } else {
            self.emojiBackground.image = nil
            self.emojiBackground.backgroundColor = UIColor(r: 246, g: 247, b: 249)
        }
    }
    
    private func setupEmojiKeyboard() {
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        
        emojiView.translatesAutoresizingMaskIntoConstraints = false
        emojiView.delegate = self
        self.emojiField.inputView = emojiView
    }
    
    private func generateRandomEmoji() -> String {
        let emojiArray = [
            0x1f600...0x1f64f,
            0x1f680...0x1f6c5,
            0x1f6cb...0x1f6d2,
            0x1f6e0...0x1f6e5,
            0x1f6f3...0x1f6fa,
            0x1f7e0...0x1f7eb,
            0x1f90d...0x1f93a,
            0x1f93c...0x1f945,
            0x1f947...0x1f971,
            0x1f973...0x1f976,
            0x1f97a...0x1f9a2,
            0x1f9a5...0x1f9aa,
            0x1f9ae...0x1f9ca,
            0x1f9cd...0x1f9ff,
            0x1fa70...0x1fa73,
            0x1fa78...0x1fa7a,
            0x1fa80...0x1fa82,
            0x1fa90...0x1fa95,
        ].reduce([], +).map { return UnicodeScalar($0)! }
        guard let scalar = emojiArray.randomElement() else { return "❓" }
        
        return String(scalar)
    }
}

extension Reactive where Base: EmojiInputView {
    var emoji: ControlProperty<String> {
        return base.emojiField.rx.text.orEmpty
    }
    
    func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<()> {
        return base.emojiField.rx.controlEvent(controlEvents)
    }
}

extension EmojiInputView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 1
    }
}

extension EmojiInputView: EmojiViewDelegate {
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        self.emojiField.text = emoji
        if self.emojiField.text?.count == 1 {
            self.emojiField.resignFirstResponder()
        }
    }
    
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
        self.emojiField.inputView = nil
        self.emojiField.keyboardType = .default
        self.emojiField.reloadInputViews()
    }
    
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        self.emojiField.deleteBackward()
    }
    
    func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {
        self.emojiField.resignFirstResponder()
    }
}
