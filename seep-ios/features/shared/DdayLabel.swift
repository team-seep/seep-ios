import UIKit

final class DdayLabel: PaddingLabel {
    init() {
        super.init(topInset: 3, bottomInset: 1, leftInset: 6, rightInset: 6)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 문구·색 규칙은 `DdayStyle`이 정한다 (GH-59). 홈 셀 표기(당일 "D-0")는 그대로 둔다.
    func bind(dday: Date?) {
        let style = DdayStyle(endDate: dday)
        textColor = style.tone.textColor
        backgroundColor = style.tone.badgeBackgroundColor
        text = style.labelText
    }
    
    private func setup() {
        font = .appleBold(size: 11)
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
}

extension DdayTone {
    var textColor: UIColor {
        switch self {
        case .past:
            return .optionPurple
        case .urgent:
            return .optionRed
        case .soon:
            return .ddayGreenText
        case .later:
            return .ddayBlueText
        }
    }

    /// 홈 셀 배지 바탕. 상세 D-day 줄은 바탕 없이 글자색만 쓴다
    var badgeBackgroundColor: UIColor {
        switch self {
        case .past:
            return .optionPurple.withAlphaComponent(0.15)
        case .urgent:
            return .ddayRedBg
        case .soon:
            return .ddayGreenBg
        case .later:
            return .ddayBlueBg
        }
    }
}
