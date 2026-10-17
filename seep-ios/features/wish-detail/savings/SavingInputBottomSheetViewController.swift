import UIKit
import Combine

import CombineCocoa
import PanModal
import SnapKit

/// "모은 돈 기록" 바텀시트 (GH-16 R-4). 금액 입력 + 빠른 버튼 + 미리보기 + 기록하기.
final class SavingInputBottomSheetViewController: BaseViewController {
    private enum Layout {
        static let contentHeight: CGFloat = 348
    }

    private let viewModel: SavingInputViewModel
    private var keyboardHeight: CGFloat = 0

    private let indicatorView = BottomSheetIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        let text = Strings.Detail.Saving.Sheet.title
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (text as NSString).range(of: Strings.Detail.Saving.Sheet.titleBold)
        )
        label.numberOfLines = 0
        label.attributedText = attributedText
        return label
    }()

    private let fieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 6
        return view
    }()

    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = .appleRegular(size: 16)
        textField.textColor = .gray5
        textField.textAlignment = .right
        textField.keyboardType = .numberPad
        textField.attributedPlaceholder = NSAttributedString(
            string: Strings.Write.TargetAmount.placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        textField.accessibilityLabel = Strings.Detail.Saving.Sheet.amount
        return textField
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 16)
        label.textColor = .gray5
        label.text = Strings.Common.wonUnit
        return label
    }()

    private let quickStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    private let plus10kButton = SavingInputBottomSheetViewController.makeQuickButton(Strings.Detail.Saving.Sheet.plus10k)
    private let plus50kButton = SavingInputBottomSheetViewController.makeQuickButton(Strings.Detail.Saving.Sheet.plus50k)
    private let plus100kButton = SavingInputBottomSheetViewController.makeQuickButton(Strings.Detail.Saving.Sheet.plus100k)
    private let remainingAllButton = SavingInputBottomSheetViewController.makeQuickButton(
        Strings.Detail.Saving.Sheet.remainingAll
    )

    private let previewLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Saving.Sheet.save, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .appleExtraBold(size: 17)
        button.layer.cornerRadius = 25
        return button
    }()

    init(viewModel: SavingInputViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()
        setupKeyboardNotification()
    }

    private static func makeQuickButton(_ title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.gray5, for: .normal)
        button.titleLabel?.font = .appleMedium(size: 14)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray2_5.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        return button
    }

    private func setupUI() {
        view.backgroundColor = .white
        fieldView.addSubViews([textField, unitLabel])
        [plus10kButton, plus50kButton, plus100kButton, remainingAllButton].forEach(quickStackView.addArrangedSubview)
        view.addSubViews([indicatorView, titleLabel, fieldView, quickStackView, previewLabel, saveButton])

        indicatorView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(indicatorView.snp.bottom).offset(14)
        }

        fieldView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.height.equalTo(52)
        }

        unitLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)

        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(unitLabel.snp.leading).offset(-4)
            $0.top.bottom.equalToSuperview()
        }

        quickStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
            $0.top.equalTo(fieldView.snp.bottom).offset(12)
        }

        quickStackView.arrangedSubviews.forEach { button in
            button.snp.makeConstraints {
                $0.height.equalTo(32)
            }
        }

        previewLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(quickStackView.snp.bottom).offset(16)
        }

        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(previewLabel.snp.bottom).offset(28)
            $0.height.equalTo(50)
        }
    }

    private func bind() {
        textField.controlEventPublisher(for: .editingChanged)
            .map { [weak self] _ in self?.textField.text ?? "" }
            .subscribe(viewModel.input.inputAmountText)
            .store(in: &cancellables)

        plus10kButton.tapPublisher
            .map { SavingInputViewModel.QuickAmount.plus(10_000) }
            .subscribe(viewModel.input.didTapQuickAmount)
            .store(in: &cancellables)

        plus50kButton.tapPublisher
            .map { SavingInputViewModel.QuickAmount.plus(50_000) }
            .subscribe(viewModel.input.didTapQuickAmount)
            .store(in: &cancellables)

        plus100kButton.tapPublisher
            .map { SavingInputViewModel.QuickAmount.plus(100_000) }
            .subscribe(viewModel.input.didTapQuickAmount)
            .store(in: &cancellables)

        remainingAllButton.tapPublisher
            .map { SavingInputViewModel.QuickAmount.remainingAll }
            .subscribe(viewModel.input.didTapQuickAmount)
            .store(in: &cancellables)

        saveButton.tapPublisher
            .subscribe(viewModel.input.didTapSave)
            .store(in: &cancellables)

        viewModel.output.amountText
            .main
            .withUnretained(self)
            .sink { (owner: SavingInputBottomSheetViewController, text: String) in
                owner.textField.text = text
            }
            .store(in: &cancellables)

        viewModel.output.isSaveEnabled
            .main
            .withUnretained(self)
            .sink { (owner: SavingInputBottomSheetViewController, isEnabled: Bool) in
                owner.saveButton.isEnabled = isEnabled
                owner.saveButton.backgroundColor = isEnabled ? .tennisGreen : .gray3
            }
            .store(in: &cancellables)

        viewModel.output.preview
            .main
            .withUnretained(self)
            .sink { (owner: SavingInputBottomSheetViewController, preview: WishSavingProgress?) in
                owner.bindPreview(preview)
            }
            .store(in: &cancellables)

        viewModel.output.route
            .main
            .withUnretained(self)
            .sink { (owner: SavingInputBottomSheetViewController, route: SavingInputViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }

    private func bindPreview(_ preview: WishSavingProgress?) {
        guard let preview else {
            previewLabel.attributedText = nil
            return
        }

        let amountText = Strings.Detail.Saving.Sheet.previewAmountFormat(
            AmountFormatter.string(from: preview.savedAmount),
            AmountFormatter.string(from: preview.targetAmount)
        )
        let text = Strings.Detail.Saving.Sheet.previewFormat(amountText, preview.percent)
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray4]
        )
        attributedText.addAttributes(
            [.font: UIFont.appleBold(size: 14) as Any, .foregroundColor: UIColor.gray5],
            range: (text as NSString).range(of: amountText)
        )
        previewLabel.attributedText = attributedText
    }

    private func setupKeyboardNotification() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .withUnretained(self)
            .sink { (owner: SavingInputBottomSheetViewController, notification: Notification) in
                owner.updateKeyboardHeight(notification)
            }
            .store(in: &cancellables)
    }

    /// 키보드가 시트를 가리지 않도록 시트 높이에 키보드 높이를 더한다 (TC-15)
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
extension SavingInputBottomSheetViewController {
    private func handleRoute(_ route: SavingInputViewModel.Route) {
        switch route {
        case .dismiss:
            view.endEditing(true)
            dismiss(animated: true)
        }
    }
}

extension SavingInputBottomSheetViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(Layout.contentHeight + keyboardHeight)
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
