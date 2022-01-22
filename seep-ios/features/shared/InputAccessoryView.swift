import UIKit

final class InputAccessoryView: BaseView {
    let finishButton = UIButton().then {
        $0.setTitle("완료", for: .normal)
        $0.setTitleColor(.seepBlue, for: .normal)
        $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 16)
    }
    
    let dividorView = UIView().then {
        $0.backgroundColor = UIColor(r: 232, g: 232, b: 232)
    }
    
    override func setup() {
        self.backgroundColor = .white
        self.addSubViews([
            self.finishButton,
            self.dividorView
        ])
    }
    
    override func bindConstraints() {
        self.finishButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        
        self.dividorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalToSuperview()
        }
    }
}
