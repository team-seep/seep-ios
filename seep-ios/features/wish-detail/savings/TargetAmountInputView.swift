import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 작성·수정 화면의 "목표 금액 (선택)" 입력 (GH-16 R-1·R-2·R-7).
/// 갖고 싶어요가 아니면 접는다. 접히면 높이 0 이 되도록 위쪽 간격(26)까지 이 뷰가 갖는다.
final class TargetAmountInputView: BaseView {
    private enum Layout {
        static let topSpacing: CGFloat = 26
        static let fieldHeight: CGFloat = 52
    }

    /// 입력이 바뀔 때마다 금액(원)을 보낸다. 비우면 0.
    let amountPublisher = PassthroughSubject<Int, Never>()

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
        imageView.image = UIImage(systemName: "banknote")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(
            string: Strings.Write.TargetAmount.title,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.append(NSAttributedString(
            string: Strings.Write.TargetAmount.optional,
            attributes: [.font: UIFont.appleRegular(size: 14) as Any, .foregroundColor: UIColor.gray4]
        ))
        label.attributedText = attributedText
        return label
    }()

    private let fieldView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 6
        return view
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.font = .appleRegular(size: 16)
        textField.textColor = .gray5
        textField.textAlignment = .right
        textField.keyboardType = .numberPad
        textField.attributedPlaceholder = NSAttributedString(
            string: Strings.Write.TargetAmount.placeholder,
            attributes: [.foregroundColor: UIColor.gray3]
        )
        textField.accessibilityLabel = Strings.Write.TargetAmount.title
        return textField
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 16)
        label.textColor = .gray5
        label.text = Strings.Common.wonUnit
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .appleMedium(size: 12)
        label.textColor = .gray4
        label.text = Strings.Write.TargetAmount.caption
        return label
    }()

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel])
        fieldView.addSubViews([textField, unitLabel])
        [spacerView, headerView, fieldView, captionLabel].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(10, after: headerView)
        stackView.setCustomSpacing(8, after: fieldView)
        addSubview(stackView)
        bindTextField()
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

        unitLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(unitLabel.snp.leading).offset(-4)
            $0.top.bottom.equalToSuperview()
        }
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    /// 수정 화면 초기값
    func setAmount(_ amount: Int) {
        textField.text = AmountFormatter.inputText(from: amount)
    }

    /// 갖고 싶어요가 아니면 접는다 (R-1). 입력값은 지우지 않는다.
    func setCollapsed(_ isCollapsed: Bool) {
        stackView.arrangedSubviews.forEach { $0.isHidden = isCollapsed }
        if isCollapsed {
            textField.resignFirstResponder()
        }
    }

    private func bindTextField() {
        textField.controlEventPublisher(for: .editingChanged)
            .withUnretained(self)
            .sink { (owner: TargetAmountInputView, _) in
                let amount = AmountFormatter.amount(from: owner.textField.text)
                owner.textField.text = AmountFormatter.inputText(from: amount)
                owner.amountPublisher.send(amount)
            }
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidBegin)
            .withUnretained(self)
            .sink { (owner: TargetAmountInputView, _) in
                owner.setFocused(true)
            }
            .store(in: &cancellables)

        textField.controlEventPublisher(for: .editingDidEnd)
            .withUnretained(self)
            .sink { (owner: TargetAmountInputView, _) in
                owner.setFocused(false)
            }
            .store(in: &cancellables)
    }

    /// TextInputField 와 같은 포커스 표현
    private func setFocused(_ isFocused: Bool) {
        iconImageView.tintColor = isFocused ? .seepBlue : .gray5
        fieldView.backgroundColor = isFocused ? .white : .gray2
        fieldView.layer.borderColor = UIColor.seepBlue.cgColor
        fieldView.layer.borderWidth = isFocused ? 1 : 0
    }
}
