import UIKit

import RxSwift
import RxCocoa

final class ProfileView: BaseView {
    private let containerView = UIView().then {
        $0.backgroundColor = UIColor(r: 255, g: 197, b: 146)
        $0.layer.cornerRadius = 50
        $0.layer.borderColor = UIColor.gray2_5.cgColor
        $0.layer.borderWidth = 1
    }
    
    private let textLabel = UILabel().then {
        $0.font = .appleBold(size: 36)
        $0.textColor = .gray5
        $0.text = "예나"
    }
    
    private let profileImage = UIImageView().then {
        $0.layer.cornerRadius = 50
        $0.layer.masksToBounds = true
        $0.image = UIImage(named: "img_profile_default")
        $0.isHidden = true
    }
    
    fileprivate let cameraButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_camera"), for: .normal)
    }
    
    override func setup() {
        self.containerView.addSubViews([
            self.textLabel,
            self.profileImage
        ])
        self.addSubViews([
            self.containerView,
            self.cameraButton
        ])
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(100)
        }
        
        self.textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.profileImage.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView)
        }
        
        self.cameraButton.snp.makeConstraints { make in
            make.right.equalTo(self.profileImage).offset(-4)
            make.bottom.equalTo(self.profileImage).offset(-4)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        self.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView).priority(.high)
        }
    }
    
    fileprivate func bind(image: UIImage?) {
        self.profileImage.isHidden = image != nil
        self.profileImage.image = image
    }
    
    fileprivate func bind(name: String, type: NicknameProfileType) {
        guard !name.isEmpty else { return }
        switch type {
        case .first:
            guard name.count < 2 else { return }
            let index = name.index(name.startIndex, offsetBy: 1)
            
            self.textLabel.text = String(name[..<index])

        case .second:
            guard name.count < 3 else { return }
            let index = name.index(name.startIndex, offsetBy: 2)
            
            self.textLabel.text = String(name[..<index])
        }
    }
}

extension Reactive where Base: ProfileView {
    var tapCameraButton: ControlEvent<Void> {
        return base.cameraButton.rx.tap
    }
    
    var image: Binder<UIImage?> {
        return Binder(self.base) { view, image in
            view.bind(image: image)
        }
    }
    
    var nickname: Binder<(String, NicknameProfileType)> {
        return Binder(self.base) { view, nickname in
            view.bind(name: nickname.0, type: nickname.1)
        }
    }
}
