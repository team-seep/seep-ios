import UIKit

import RxSwift
import RxCocoa

final class ProfileSwitch: BaseView {
    fileprivate let nicknameProfileType = PublishSubject<NicknameProfileType>()
    
    fileprivate var isEnable: Bool = true {
        didSet(newValue) {
            self.setEnable(isEnable: newValue)
        }
    }
    
    private let backgroundView = UIView().then {
        $0.layer.cornerRadius = 24
        $0.backgroundColor = UIColor(r: 232, g: 246, b: 255)
    }
    
    private let indicatorView = UIView().then {
        $0.backgroundColor = .seepBlue
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.blue.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowOpacity = 0.15
    }
    
    private let firstButton = UIButton().then {
        $0.setTitle("signup_nickname_first".localized, for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.setTitleColor(.gray3, for: .disabled)
        $0.titleLabel?.font = .appleExtraBold(size: 14)
    }
    
    private let secondButton = UIButton().then {
        $0.setTitle("signup_nickname_second".localized, for: .normal)
        $0.setTitleColor(.gray4, for: .normal)
        $0.setTitleColor(.gray3, for: .disabled)
        $0.titleLabel?.font = .appleRegular(size: 14)
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.backgroundView,
            self.indicatorView,
            self.firstButton,
            self.secondButton
        ])
        
        self.firstButton.rx.tap
            .map { NicknameProfileType.first }
            .do(onNext: { [weak self] type in
                self?.select(type: type)
            })
            .bind(to: self.nicknameProfileType)
            .disposed(by: self.disposeBag)
        
        self.secondButton.rx.tap
            .map { NicknameProfileType.second }
            .do(onNext: { [weak self] type in
                self?.select(type: type)
            })
            .bind(to: self.nicknameProfileType)
            .disposed(by: self.disposeBag)
    }
    
    override func bindConstraints() {
        self.backgroundView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.height.equalTo(48)
        }
        
        self.firstButton.snp.makeConstraints { make in
            make.left.equalTo(self.backgroundView).offset(8)
            make.top.equalTo(self.backgroundView).offset(8)
            make.right.equalTo(self.snp.centerX).offset(-4)
            make.bottom.equalTo(self.backgroundView).offset(-8)
        }
        
        self.secondButton.snp.makeConstraints { make in
            make.left.equalTo(self.snp.centerX).offset(4)
            make.top.equalTo(self.backgroundView).offset(8)
            make.right.equalTo(self.backgroundView).offset(-8)
            make.bottom.equalTo(self.backgroundView).offset(-8)
        }
        
        self.indicatorView.snp.makeConstraints { make in
            make.edges.equalTo(self.firstButton)
        }
        
        self.snp.makeConstraints { make in
            make.edges.equalTo(self.backgroundView).priority(.high)
        }
    }
    
    private func select(type: NicknameProfileType) {
        switch type {
        case .first:
            self.indicatorView.snp.remakeConstraints { make in
                make.edges.equalTo(self.firstButton)
            }
            self.firstButton.setTitleColor(.white, for: .normal)
            self.secondButton.setTitleColor(.gray4, for: .normal)
            
        case .second:
            self.indicatorView.snp.remakeConstraints { make in
                make.edges.equalTo(self.secondButton)
            }
            self.firstButton.setTitleColor(.gray4, for: .normal)
            self.secondButton.setTitleColor(.white, for: .normal)
        }
        
        self.firstButton.titleLabel?.font = type == .first
        ? .appleExtraBold(size: 14)
        : .appleRegular(size: 14)
        self.secondButton.titleLabel?.font = type == .second
        ? .appleExtraBold(size: 14)
        : .appleRegular(size: 14)
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
    
    private func setEnable(isEnable: Bool) {
        self.backgroundView.backgroundColor = isEnable
        ? UIColor(r: 232, g: 246, b: 255)
        : .gray2
        self.indicatorView.backgroundColor = isEnable
        ? .seepBlue
        : .gray2_5
        self.isUserInteractionEnabled = isEnable
        self.firstButton.isEnabled = isEnable
        self.secondButton.isEnabled = isEnable
    }
}

extension Reactive where Base: ProfileSwitch {
    var nicknameProfileType: ControlEvent<NicknameProfileType> {
        return ControlEvent(events: base.nicknameProfileType)
    }
    
    var isEnable: Binder<Bool> {
        return Binder(self.base) { view, isEnable in
            view.isEnable = isEnable
        }
    }
}
