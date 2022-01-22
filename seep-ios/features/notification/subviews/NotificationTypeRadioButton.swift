import UIKit

import RxSwift
import RxCocoa

final class NotificationTypeRadioButton: BaseView {
    static let height: CGFloat = 56
    fileprivate let tapGesture = UITapGestureRecognizer()
    
    var isSelected: Bool {
        didSet {
            self.checkImage.image = isSelected
                ? UIImage(named: "ic_radio_on")
                : UIImage(named: "ic_radio_off")
        }
    }
    
    enum ButtonType {
        case targetDay
        case beforeDay
        case beforeTwoDay
        case beforeWeek
        case everyday
        
        var title: String {
            switch self {
            case .targetDay:
                return "notification_type_targat_day".localized
                
            case .beforeDay:
                return "notification_type_before_day".localized
                
            case .beforeTwoDay:
                return "notification_type_before_two_day".localized
                
            case .beforeWeek:
                return "notification_type_before_week".localized
                
            case .everyday:
                return "notification_type_everyday".localized
            }
        }
    }
    private let titleLabel = UILabel().then {
        $0.font = .appleRegular(size: 16)
        $0.textColor = .black
    }
    
    private let checkImage = UIImageView().then {
        $0.image = UIImage(named: "ic_radio_off")
    }
    
    init(type: ButtonType) {
        self.titleLabel.text = type.title
        self.isSelected = false
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        self.addGestureRecognizer(self.tapGesture)
        self.backgroundColor = .clear
        self.addSubViews([
            self.titleLabel,
            self.checkImage
        ])
    }
    
    override func bindConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        self.checkImage.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(self.titleLabel)
            make.width.height.equalTo(24)
        }
        
        self.snp.makeConstraints { make in
            make.height.equalTo(Self.height)
        }
    }
}

extension Reactive where Base: NotificationTypeRadioButton {
    var tap: ControlEvent<Void> {
        return ControlEvent(events: base.tapGesture.rx.event.map { _ in () })
    }
}
