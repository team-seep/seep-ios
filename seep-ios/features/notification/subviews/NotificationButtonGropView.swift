import UIKit

final class NotificationButtonGropView: BaseView {
    private let targetDayButton = NotificationTypeRadioButton(type: .targetDay)
    
    private let beforeDayButton = NotificationTypeRadioButton(type: .everyday)
    
    private let beforeTwoDayButton = NotificationTypeRadioButton(type: .beforeTwoDay)
    
    private let beforeWeekButton = NotificationTypeRadioButton(type: .beforeWeek)
    
    private let everydayButton = NotificationTypeRadioButton(type: .everyday)
    
    override func setup() {
        self.addSubViews([
            self.targetDayButton,
            self.beforeDayButton,
            self.beforeTwoDayButton,
            self.beforeWeekButton,
            self.everydayButton
        ])
    }
    
    override func bindConstraints() {
        self.targetDayButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.beforeDayButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.targetDayButton.snp.bottom)
            make.right.equalToSuperview()
        }
        
        self.beforeTwoDayButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.beforeDayButton.snp.bottom)
            make.right.equalToSuperview()
        }
        
        self.beforeWeekButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.beforeTwoDayButton.snp.bottom)
            make.right.equalToSuperview()
        }
        
        self.everydayButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.beforeWeekButton.snp.bottom)
            make.right.equalToSuperview()
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(self.targetDayButton).priority(.high)
            make.bottom.equalTo(self.everydayButton).priority(.high)
        }
    }
}
