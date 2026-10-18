import UIKit
import Combine

import CombineCocoa
import PanModal
import SnapKit

/// 완료 직후 "이루고 나니 어때요?" 한 줄 소감 바텀시트 (GH-25 R-1).
final class FinishNoteBottomSheetViewController: BaseViewController {
    override var screenName: ScreenName { viewModel.output.screenName }

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let bottomInset: CGFloat = 8
        /// 레이아웃 전 첫 표시용 높이. 실제 높이는 viewDidLayoutSubviews 에서 콘텐츠에 맞춘다
        static let estimatedContentHeight: CGFloat = 400
    }

    private let viewModel: FinishNoteViewModel
    private var contentHeight: CGFloat = Layout.estimatedContentHeight
    private var keyboardHeight: CGFloat = 0

    private let indicatorView = BottomSheetIndicator()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        label.numberOfLines = 0
        label.text = Strings.Home.FinishNote.description
        return label
    }()

    private let fieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 12
        return view
    }()

    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = .appleRegular(size: 16)
        textField.textColor = .gray5
        textField.returnKeyType = .done
        textField.attributedPlaceholder = NSAttributedString(
            string: Strings.Home.FinishNote.placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        textField.accessibilityLabel = Strings.Home.FinishNote.field
        return textField
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.textAlignment = .right
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Home.FinishNote.save, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .appleExtraBold(size: 17)
        button.layer.cornerRadius = 25
        return button
    }()

    private let skipButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Home.FinishNote.skip, for: .normal)
        button.setTitleColor(.gray4, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        return button
    }()

    init(viewModel: FinishNoteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindWish(viewModel.output.wish)
        bind()
        setupKeyboardNotification()
        viewModel.input.viewDidLoad.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 긴 제목은 헤드라인이 여러 줄이 되므로 시트 높이를 콘텐츠에 맞춘다
        let fittedHeight = ceil(skipButton.frame.maxY + Layout.bottomInset)
        guard fittedHeight > 0, abs(fittedHeight - contentHeight) > 0.5 else { return }
        contentHeight = fittedHeight
        panModalSetNeedsLayoutUpdate()
    }

    private func setupUI() {
        view.backgroundColor = .white
        fieldView.addSubview(textField)
        view.addSubViews([
            indicatorView,
            emojiLabel,
            titleLabel,
            descriptionLabel,
            fieldView,
            countLabel,
            saveButton,
            skipButton
        ])

        indicatorView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.horizontalInset)
            $0.top.equalTo(indicatorView.snp.bottom).offset(12)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(emojiLabel.snp.bottom).offset(10)
        }

        descriptionLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
        }

        fieldView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            $0.height.equalTo(52)
        }

        textField.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }

        countLabel.snp.makeConstraints {
            $0.trailing.equalTo(fieldView)
            $0.top.equalTo(fieldView.snp.bottom).offset(8)
        }

        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(countLabel.snp.bottom).offset(22)
            $0.height.equalTo(50)
        }

        skipButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            $0.top.equalTo(saveButton.snp.bottom).offset(6)
            $0.height.equalTo(44)
        }
    }

    private func bindWish(_ wish: Wish) {
        emojiLabel.text = wish.emoji

        let text = Strings.Home.FinishNote.titleFormat(wish.title)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (text as NSString).range(of: Strings.Home.FinishNote.titleBold, options: .backwards)
        )
        titleLabel.attributedText = attributedText
    }

    private func bind() {
        textField.controlEventPublisher(for: .editingChanged)
            .map { [weak self] _ in self?.textField.text ?? "" }
            .subscribe(viewModel.input.inputNote)
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidEndOnExit)
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, _) in
                owner.view.endEditing(true)
            }
            .store(in: &cancellables)

        saveButton.tapPublisher
            .subscribe(viewModel.input.didTapSave)
            .store(in: &cancellables)

        skipButton.tapPublisher
            .subscribe(viewModel.input.didTapSkip)
            .store(in: &cancellables)

        viewModel.output.noteText
            .main
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, text: String) in
                owner.updateTextIfNeeded(text)
            }
            .store(in: &cancellables)

        viewModel.output.countText
            .main
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, text: String) in
                owner.countLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.output.isSaveEnabled
            .main
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, isEnabled: Bool) in
                owner.saveButton.isEnabled = isEnabled
                owner.saveButton.backgroundColor = isEnabled ? .tennisGreen : .gray3
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, route: FinishNoteViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    /// 한글 조합 중(markedText)에는 글자를 바꾸지 않는다. 조합이 끝나면 다시 editingChanged 가 와서 40자로 잘린다
    private func updateTextIfNeeded(_ text: String) {
        guard textField.markedTextRange == nil, textField.text != text else { return }
        textField.text = text
    }

    private func setupKeyboardNotification() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .withUnretained(self)
            .sink { (owner: FinishNoteBottomSheetViewController, notification: Notification) in
                owner.updateKeyboardHeight(notification)
            }
            .store(in: &cancellables)
    }

    /// 키보드가 CTA 를 가리지 않도록 시트 높이에 키보드 높이를 더한다 (TC-13)
    private func updateKeyboardHeight(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let screenHeight = view.window?.windowScene?.screen.bounds.height ?? frame.maxY
        let safeAreaBottom = view.window?.safeAreaInsets.bottom ?? 0
        let overlap = max(screenHeight - frame.minY - safeAreaBottom, 0)
        guard overlap != keyboardHeight else { return }
        keyboardHeight = overlap
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .shortForm)
    }
}

// MARK: Route
extension FinishNoteBottomSheetViewController {
    private func handleRoute(_ route: FinishNoteViewModel.Route) {
        switch route {
        case .dismiss:
            view.endEditing(true)
            dismiss(animated: true)
        case .showErrorAlert(let error):
            showErrorAlert(error)
        }
    }
}

extension FinishNoteBottomSheetViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(contentHeight + keyboardHeight)
    }

    var longFormHeight: PanModalHeight {
        shortFormHeight
    }

    var showDragIndicator: Bool {
        return false
    }

    var cornerRadius: CGFloat {
        return 16
    }
}
