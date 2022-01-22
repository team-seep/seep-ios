import UIKit

import RxSwift
import RxCocoa

final class NotificationButtonGropView: BaseView {
    fileprivate let selectedType = PublishSubject<SeepNotification.NotificationType>()
    
    private let targetDayButton = NotificationTypeRadioButton(type: .targetDay)
    
    private let beforeDayButton = NotificationTypeRadioButton(type: .dayAgo)
    
    private let beforeTwoDayButton = NotificationTypeRadioButton(type: .twoDayAgo)
    
    private let beforeWeekButton = NotificationTypeRadioButton(type: .weekAgo)
    
    private let everydayButton = NotificationTypeRadioButton(type: .everyDay)
    
    override func setup() {
        self.addSubViews([
            self.targetDayButton,
            self.beforeDayButton,
            self.beforeTwoDayButton,
            self.beforeWeekButton,
            self.everydayButton
        ])
        self.selectRadioButton(type: .targetDay)
        
        self.targetDayButton.rx.tap
            .map { SeepNotification.NotificationType.targetDay }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeDayButton.rx.tap
            .map { SeepNotification.NotificationType.dayAgo }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeTwoDayButton.rx.tap
            .map { SeepNotification.NotificationType.twoDayAgo }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeWeekButton.rx.tap
            .map { SeepNotification.NotificationType.weekAgo }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.everydayButton.rx.tap
            .map { SeepNotification.NotificationType.everyDay }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
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
    
    private func selectRadioButton(type: SeepNotification.NotificationType) {
        self.targetDayButton.isSelected = type == .targetDay
        self.beforeDayButton.isSelected = type == .dayAgo
        self.beforeTwoDayButton.isSelected = type == .twoDayAgo
        self.beforeWeekButton.isSelected = type == .weekAgo
        self.everydayButton.isSelected = type == .everyDay
    }
}

extension Reactive where Base: NotificationButtonGropView {
    var selectedType: ControlEvent<SeepNotification.NotificationType> {
        return ControlEvent(events: base.selectedType)
    }
}
