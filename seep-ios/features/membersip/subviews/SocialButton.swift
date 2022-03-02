import UIKit

import RxSwift
import RxCocoa

final class SocialButton: BaseView {
    fileprivate let tapGesture = UITapGestureRecognizer()
    
    private let iconImage = UIImageView()
    
    private let titleLabel = UILabel().then {
        $0.font = .appleExtraBold(size: 16)
    }
    
    init(socialType: SocialType) {
        super.init(frame: .zero)
        
        self.bind(socialType: socialType)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        self.layer.cornerRadius = 25
        self.addSubViews([
            self.iconImage,
            self.titleLabel
        ])
    }
    
    override func bindConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.iconImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(self.titleLabel.snp.left).offset(-8)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
    }
    
    private func bind(socialType: SocialType) {
        switch socialType {
        case .kakao:
            self.iconImage.image = UIImage(named: "ic_kakao")
            self.titleLabel.text = "membership_signin_with_kakao".localized
            self.titleLabel.textColor = .gray5
            self.backgroundColor = UIColor(r: 254, g: 233, b: 0)
            
        case .apple:
            self.iconImage.image = UIImage(named: "ic_apple")
            self.titleLabel.text = "membership_signin_with_apple".localized
            self.titleLabel.textColor = .gray1
            self.backgroundColor = .black
        }
    }
}

extension Reactive where Base: SocialButton {
    var tap: ControlEvent<Void> {
        return ControlEvent(events: base.tapGesture.rx.event.map { _ in ()})
    }
}
