import UIKit

final class SignupView: BaseView {
    let backButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_chevron_back"), for: .normal)
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .appleLight(size: 22)
        $0.textColor = .gray5
        $0.text = "signup_title".localized
        $0.setLineHeight(lineHeight: 30)
    }
    
    private let profileImage = UIImageView().then {
        $0.layer.cornerRadius = 50
        $0.layer.borderColor = UIColor.gray2_5.cgColor
        $0.layer.borderWidth = 1
        $0.layer.masksToBounds = true
    }
    
    let cameraButton = UIButton().then {
        $0.setImage(UIImage(named: "ic_camera"), for: .normal)
    }
    
    private let profileLabel = UILabel().then {
        $0.font = .appleRegular(size: 400)
        $0.textColor = .gray5
        $0.text = "signup_profile_title".localized
    }
    
    
}
