import UIKit
import Combine

import SnapKit

/// 위시 상세·작성의 "단계" 섹션. 헤더(아이콘·라벨·진행도) + 단계 목록 상자 + "단계 추가" 버튼.
final class WishStepsView: BaseView {
    let didTapStepPublisher = PassthroughSubject<Int, Never>()
    let deleteStepPublisher = PassthroughSubject<Int, Never>()

    /// false 면 작성 화면용: 체크 아이콘을 비활성으로 보여주고 탭해도 토글하지 않는다. 행 오른쪽에 삭제 버튼을 보여준다.
    var isCheckable = true

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()

    private let headerView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checklist")
        imageView.tintColor = .gray5
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 14)
        label.textColor = .gray5
        label.text = Strings.Detail.Step.title
        return label
    }()

    private let progressBar = StepProgressBar(width: 48)

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .appleSemiBold(size: 13)
        label.textColor = .gray4
        return label
    }()

    private let stepBoxView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2
        view.layer.cornerRadius = 12
        return view
    }()

    private let stepStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    let addButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.Detail.Step.add, for: .normal)
        button.setTitleColor(.seepBlue, for: .normal)
        button.setImage(Assets.Icons.icSmallPlus.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .seepBlue
        button.titleLabel?.font = .appleExtraBold(size: 14)
        button.semanticContentAttribute = .forceLeftToRight
        return button
    }()

    override func setup() {
        headerView.addSubViews([iconImageView, titleLabel, progressBar, progressLabel])
        stepBoxView.addSubview(stepStackView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(stepBoxView)
        stackView.addArrangedSubview(addButton)
        stackView.setCustomSpacing(0, after: stepBoxView)
        addSubview(stackView)
    }

    override func bindConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.height.equalTo(20)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }

        progressLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        progressBar.snp.makeConstraints {
            $0.trailing.equalTo(progressLabel.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
        }

        stepStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        addButton.snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func bind(steps: [WishStep]) {
        stepStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        steps.enumerated().forEach { index, step in
            let rowView = WishStepRowView(step: step, isFirst: index == 0, isCheckable: isCheckable)
            rowView.tag = index
            rowView.onTapDelete = { [weak self] in
                self?.deleteStepPublisher.send(index)
            }
            rowView.addTarget(self, action: #selector(didTapRow(_:)), for: .touchUpInside)
            rowView.addInteraction(UIContextMenuInteraction(delegate: self))
            stepStackView.addArrangedSubview(rowView)
        }
        stepBoxView.isHidden = steps.isEmpty
    }

    func bind(progress: WishStepProgress?) {
        progressBar.isHidden = progress == nil
        progressLabel.isHidden = progress == nil
        guard let progress else { return }

        progressBar.bind(progress: progress)
        progressLabel.text = Strings.Detail.Step.progressFormat(progress.doneCount, progress.totalCount)
    }

    func bind(isAddEnabled: Bool) {
        addButton.tintColor = isAddEnabled ? .seepBlue : .gray3
        addButton.setTitleColor(isAddEnabled ? .seepBlue : .gray3, for: .normal)
    }

    @objc private func didTapRow(_ sender: WishStepRowView) {
        didTapStepPublisher.send(sender.tag)
    }
}

extension WishStepsView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let index = interaction.view?.tag else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let deleteAction = UIAction(
                title: Strings.Detail.Step.delete,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.deleteStepPublisher.send(index)
            }
            return UIMenu(children: [deleteAction])
        }
    }
}

/// 단계 한 줄: 체크 아이콘 22 + 제목 16. 완료면 gray4 + 취소선. 체크할 수 없는 행(작성 화면)은 오른쪽에 삭제 버튼.
private final class WishStepRowView: UIControl {
    var onTapDelete: (() -> Void)?

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray2_5
        return view
    }()

    private let checkImageView = UIImageView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appleRegular(size: 16)
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(Assets.Icons.icClose.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray3
        button.accessibilityLabel = Strings.Detail.Step.delete
        return button
    }()

    init(step: WishStep, isFirst: Bool, isCheckable: Bool) {
        super.init(frame: .zero)
        setup(isFirst: isFirst, showsDeleteButton: !isCheckable)
        bind(step: step, isCheckable: isCheckable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(isFirst: Bool, showsDeleteButton: Bool) {
        addSubview(separatorView)
        addSubview(checkImageView)
        addSubview(titleLabel)
        addSubview(deleteButton)
        separatorView.isHidden = isFirst
        deleteButton.isHidden = !showsDeleteButton
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        snp.makeConstraints {
            $0.height.equalTo(44)
        }

        separatorView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(1)
        }

        checkImageView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(checkImageView.snp.trailing).offset(12)
            if showsDeleteButton {
                $0.trailing.lessThanOrEqualTo(deleteButton.snp.leading)
            } else {
                $0.trailing.lessThanOrEqualToSuperview()
            }
            $0.centerY.equalToSuperview()
        }
    }

    @objc private func didTapDelete() {
        onTapDelete?()
    }

    private func bind(step: WishStep, isCheckable: Bool) {
        checkImageView.image = step.isDone ? Assets.Icons.icCheckOn.image : Assets.Icons.icCheckOff.image
        checkImageView.alpha = isCheckable ? 1 : 0.4

        if step.isDone {
            titleLabel.attributedText = NSAttributedString(string: step.title, attributes: [
                .foregroundColor: UIColor.gray4,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: UIColor.gray4
            ])
        } else {
            titleLabel.attributedText = NSAttributedString(string: step.title, attributes: [
                .foregroundColor: UIColor.gray5
            ])
        }

        accessibilityLabel = step.title
        if isCheckable {
            accessibilityTraits = step.isDone ? [.button, .selected] : .button
        } else {
            accessibilityTraits = .staticText
        }
        isAccessibilityElement = true
    }
}

extension UIViewController {
    /// 단계 제목 입력 알럿. 위시 상세·작성 화면이 같이 쓴다.
    func presentAddWishStepAlert(onConfirm: @escaping (String) -> Void) {
        let alertController = UIAlertController(
            title: Strings.Detail.Step.AddAlert.title,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.placeholder = Strings.Detail.Step.AddAlert.placeholder
            textField.returnKeyType = .done
        }
        let cancelAction = UIAlertAction(title: Strings.commonCancel, style: .cancel)
        let confirmAction = UIAlertAction(
            title: Strings.Detail.Step.AddAlert.confirm,
            style: .default
        ) { [weak alertController] _ in
            onConfirm(alertController?.textFields?.first?.text ?? "")
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true)
    }
}
