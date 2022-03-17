import UIKit

final class ProfileView: BaseView {
    private let profileImage = UIImageView().then {
        $0.backgroundColor = .gray2
        $0.layer.cornerRadius = 50
        $0.layer.borderColor = UIColor.gray2_5.cgColor
        $0.layer.borderWidth = 1
        $0.layer.masksToBounds = true
        $0.image = UIImage(named: "img_profile_default")
    }
    
    fileprivate let cameraButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_camera"), for: .normal)
    }
    
    override func setup() {
        self.addSubViews([
            self.profileImage,
            self.cameraButton
        ])
    }
    
    override func bindConstraints() {
        self.profileImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(100)
        }
        
        self.cameraButton.snp.makeConstraints { make in
            make.right.equalTo(self.profileImage).offset(-4)
            make.bottom.equalTo(self.profileImage).offset(-4)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        self.snp.makeConstraints { make in
            make.edges.equalTo(self.profileImage).priority(.high)
        }
    }
}
