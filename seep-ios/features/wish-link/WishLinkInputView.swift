import UIKit
import Combine
import UniformTypeIdentifiers

import CombineCocoa
import SnapKit

/// 작성·수정 화면의 "링크 (선택)" 칸 + 미리보기 카드 (GH-29 R-1~R-3, R-6).
/// 갖고 싶어요가 아니면 접는다. 접히면 높이 0 이 되도록 위쪽 간격(24)까지 이 뷰가 갖는다.
final class WishLinkInputView: BaseView {
    private enum Layout {
        static let topSpacing: CGFloat = 24
        static let fieldHeight: CGFloat = 52
    }

    /// 칸에 입력할 때마다 보낸다
    let textPublisher = PassthroughSubject<String, Never>()
    /// "붙여넣기"로 들어온 값
    let pastePublisher = PassthroughSubject<String, Never>()

    override var inputAccessoryView: UIView? {
        get { textField.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private let spacerView = UIView()

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "link")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(
            string: Strings.Write.Link.title,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.append(NSAttributedString(
            string: Strings.Write.Link.optional,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray4]
        ))
        label.attributedText = attributedText
        return label
    }()

    private let fieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 6
        view.layer.borderColor = UIColor.seepBlue.cgColor
        return view
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.font = .appleRegular(size: 16)
        textField.textColor = .gray5
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.attributedPlaceholder = NSAttributedString(
            string: Strings.Write.Link.placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        textField.accessibilityLabel = Strings.Write.Link.title
        return textField
    }()

    /// 클립보드에 링크가 있을 때만 보인다. 사용자가 직접 눌러 붙여넣으니 권한 알림이 뜨지 않는다 (R-6)
    private lazy var pasteControl: UIPasteControl = {
        let configuration = UIPasteControl.Configuration()
        // 앱이 en 로컬라이즈만 있어 라벨은 시스템이 "Paste"로 그린다. 한글 화면에 영어가 섞이지 않게 아이콘만 쓴다
        configuration.displayMode = .iconOnly
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .seepBlue
        configuration.baseBackgroundColor = .gray1
        let control = UIPasteControl(configuration: configuration)
        control.target = self
        control.isHidden = true
        return control
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .optionRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    let cardView = LinkPreviewCardView()

    private var isCollapsed = false
    private var isFieldFocused = false
    private var hasError = false
    private var canPaste = false
    private var hasCard = false

    override func setup() {
        pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [
            UTType.url.identifier,
            UTType.plainText.identifier
        ])

        headerView.addSubViews([iconImageView, titleLabel])
        fieldView.addSubViews([textField, pasteControl])
        [spacerView, headerView, fieldView, errorLabel, cardView].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        stackView.setCustomSpacing(8, after: fieldView)
        stackView.setCustomSpacing(8, after: errorLabel)
        cardView.isHidden = true
        addSubview(stackView)
        bindTextField()
        observePasteboard()
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        spacerView.snp.makeConstraints {
            $0.height.equalTo(Layout.topSpacing)
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(16)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }

        fieldView.snp.makeConstraints {
            $0.height.equalTo(Layout.fieldHeight)
        }

        pasteControl.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.bottom.equalToSuperview()
        }
    }

    override func paste(itemProviders: [NSItemProvider]) {
        guard let provider = itemProviders.first else { return }

        // 문자열을 먼저 본다. 텍스트로 복사한 링크도 URL 로 읽히는데, 그 경우 URL 로드가 실패할 수 있다
        if provider.canLoadObject(ofClass: String.self) {
            _ = provider.loadObject(ofClass: String.self) { [weak self] text, _ in
                guard let text else { return }
                self?.sendPasted(text: text)
            }
        } else if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                guard let url else { return }
                self?.sendPasted(text: url.absoluteString)
            }
        }
    }

    /// 수정 화면 초기값, 붙여넣기 결과
    func setText(_ text: String) {
        textField.text = text
        updatePasteControl()
    }

    /// 갖고 싶어요가 아니면 접는다 (R-1). 입력값은 지우지 않는다.
    func setCollapsed(_ isCollapsed: Bool) {
        self.isCollapsed = isCollapsed
        [spacerView, headerView, fieldView].forEach { $0.isHidden = isCollapsed }
        errorLabel.isHidden = isCollapsed || !hasError
        cardView.isHidden = isCollapsed || !hasCard
        if isCollapsed {
            textField.resignFirstResponder()
        }
    }

    func bind(errorMessage: String?) {
        hasError = errorMessage != nil
        errorLabel.text = errorMessage
        errorLabel.isHidden = isCollapsed || !hasError
        updateFieldBorder()
    }

    func bind(preview: WishLinkPreviewState) {
        // 접었다 펼 때 카드를 되살린다
        hasCard = preview != .hidden
        cardView.bind(state: preview)
        cardView.isHidden = isCollapsed || preview == .hidden
    }

    private func sendPasted(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.pastePublisher.send(text)
        }
    }

    private func bindTextField() {
        textField.controlEventPublisher(for: .editingChanged)
            .withUnretained(self)
            .sink { (owner: WishLinkInputView, _) in
                owner.textPublisher.send(owner.textField.text ?? "")
                owner.updatePasteControl()
            }
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidBegin)
            .withUnretained(self)
            .sink { (owner: WishLinkInputView, _) in
                owner.setFocused(true)
            }
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidEnd)
            .withUnretained(self)
            .sink { (owner: WishLinkInputView, _) in
                owner.setFocused(false)
            }
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidEndOnExit)
            .withUnretained(self)
            .sink { (owner: WishLinkInputView, _) in
                owner.textField.resignFirstResponder()
            }
            .store(in: &cancellables)
    }

    private func observePasteboard() {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIPasteboard.changedNotification),
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        )
        .map { _ in () }
        .prepend(())
        .withUnretained(self)
        .sink { (owner: WishLinkInputView, _) in
            owner.detectPasteboardLink()
        }
        .store(in: &cancellables)
    }

    /// 값을 읽지 않고 "링크처럼 보이는지"만 확인해 붙여넣기 권한 알림이 뜨지 않는다 (R-6)
    private func detectPasteboardLink() {
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasURLs || pasteboard.hasStrings else {
            setCanPaste(false)
            return
        }
        if pasteboard.hasURLs {
            setCanPaste(true)
            return
        }
        pasteboard.detectPatterns(for: [\UIPasteboard.DetectedValues.probableWebURL]) { [weak self] result in
            let hasLink = (try? result.get())?.contains(\UIPasteboard.DetectedValues.probableWebURL) ?? false
            DispatchQueue.main.async {
                self?.setCanPaste(hasLink)
            }
        }
    }

    private func setCanPaste(_ canPaste: Bool) {
        self.canPaste = canPaste
        updatePasteControl()
    }

    /// 빈 칸일 때만 붙여넣기를 보인다
    private func updatePasteControl() {
        let isEmpty = (textField.text ?? "").isEmpty
        pasteControl.isHidden = !(canPaste && isEmpty)
        textField.snp.updateConstraints {
            $0.trailing.equalToSuperview().offset(pasteControl.isHidden ? -12 : -52)
        }
    }

    /// TargetAmountInputView 와 같은 포커스 표현. 형식 오류면 빨간 테두리
    private func setFocused(_ isFieldFocused: Bool) {
        self.isFieldFocused = isFieldFocused
        iconImageView.tintColor = isFieldFocused ? .seepBlue : .gray5
        fieldView.backgroundColor = isFieldFocused ? .gray1 : .gray2
        updateFieldBorder()
    }

    private func updateFieldBorder() {
        fieldView.layer.borderColor = (hasError ? UIColor.optionRed : UIColor.seepBlue).cgColor
        fieldView.layer.borderWidth = (hasError || isFieldFocused) ? 1 : 0
    }
}
