import UIKit

final class DdayLabel: PaddingLabel {
    init() {
        super.init(topInset: 3, bottomInset: 1, leftInset: 6, rightInset: 6)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(dday: Date?) {
        if let dday = dday {
            let remainDay = Calendar.current.dateComponents([.day], from: Date().startOfDay, to: dday.startOfDay).day ?? -1
            
            switch remainDay {
            case _ where remainDay < 0:
                textColor = .optionPurple
                backgroundColor = .optionPurple.withAlphaComponent(0.15)
            case 0..<8:
                textColor = .optionRed
                backgroundColor = UIColor(r: 255, g: 236, b: 235)
            case 8..<31:
                textColor = UIColor(r: 56, g: 202, b: 79)
                backgroundColor = UIColor(r: 231, g: 251, b: 234)
            default:
                textColor = UIColor(r: 62, g: 163, b: 254)
                backgroundColor = UIColor(r: 236, g: 243, b: 250)
            }
            
            if remainDay < 0 {
                text = "D+\(abs(remainDay))"
            } else if remainDay <= 365 {
                text = "D-\(remainDay)"
            } else {
                text = "home_in_far_furture".localized
            }
        } else {
            backgroundColor = UIColor(r: 236, g: 243, b: 250)
            textColor = UIColor(r: 62, g: 163, b: 254)
            text = "home_no_deanline".localized
        }
    }
    
    private func setup() {
        font = .appleBold(size: 11)
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
}
