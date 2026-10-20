import UIKit
import Combine

import CombineCocoa
import SnapKit

/// 앱 전체를 덮는 잠금 화면 (GH-46 R-6). 디자인 After 2.
/// 앱 전환기용 덮개(R-7)도 같은 화면에서 버튼만 숨겨 그린다
final class AppLockViewController: BaseViewController {
    private let viewModel: AppLockViewModel

    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray1
        view.layer.cornerRadius = 36
        return view
    }()

    private let iconImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: "lock", withConfiguration: configuration))
        imageView.tintColor = .gray5
        imageView.contentMode = .center
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        let text = Strings.AppLock.Screen.title
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: UIFont.appleLight(size: 22) as Any, .foregroundColor: UIColor.gray5]
        )
        attributedText.addAttribute(
            .font,
            value: UIFont.appleBold(size: 22) as Any,
            range: (text as NSString).range(of: Strings.AppLock.Screen.titleBold, options: .backwards)
        )
        label.attributedText = attributedText
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .appleRegular(size: 14)
        label.textColor = .gray4
        return label
    }()

    private let unlockButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .init(top: 15, leading: 32, bottom: 15, trailing: 32)
        let button = UIButton(configuration: config)
        button.backgroundColor = .tennisGreen
        button.layer.cornerRadius = 25
        return button
    }()

    init(viewModel: AppLockViewModel) {
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
    }

    private func setupUI() {
        view.backgroundColor = .gray2
        iconBackgroundView.addSubview(iconImageView)
        view.addSubViews([iconBackgroundView, titleLabel, descriptionLabel, unlockButton])

        iconBackgroundView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.size.equalTo(72)
            // 디자인처럼 아이콘·문구 묶음이 화면 가운데보다 조금 위에 오게 한다
            $0.centerY.equalTo(view.safeAreaLayoutGuide).offset(-100)
        }

        iconImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconBackgroundView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        unlockButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(50)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
        }
    }

    private func bind() {
        unlockButton.tapPublisher
            .subscribe(viewModel.input.didTapUnlock)
            .store(in: &cancellables)

        viewModel.output.description
            .main
            .withUnretained(self)
            .sink { (owner: AppLockViewController, description: String) in
                owner.descriptionLabel.text = description
            }
            .store(in: &cancellables)

        viewModel.output.unlockButtonTitle
            .main
            .withUnretained(self)
            .sink { (owner: AppLockViewController, title: String) in
                owner.unlockButton.setAttributedTitle(NSAttributedString(
                    string: title,
                    attributes: [.font: UIFont.appleExtraBold(size: 17) as Any, .foregroundColor: UIColor.gray1]
                ), for: .normal)
            }
            .store(in: &cancellables)

        viewModel.output.lockState
            .main
            .withUnretained(self)
            .sink { (owner: AppLockViewController, lockState: AppLockViewModel.LockState) in
                // 전환기용 덮개는 가리기만 한다. 버튼을 누를 일이 없다 (R-7)
                owner.unlockButton.isHidden = lockState != .locked
            }
            .store(in: &cancellables)
    }
}
