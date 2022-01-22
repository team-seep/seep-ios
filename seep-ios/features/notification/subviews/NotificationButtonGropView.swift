import UIKit

import RxSwift
import RxCocoa

final class NotificationButtonGropView: BaseView {
    fileprivate let selectedType = PublishSubject<NotificationTypeRadioButton.ButtonType>()
    
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
        self.selectRadioButton(type: .targetDay)
        
        self.targetDayButton.rx.tap
            .map { NotificationTypeRadioButton.ButtonType.targetDay }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeDayButton.rx.tap
            .map { NotificationTypeRadioButton.ButtonType.beforeDay }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeTwoDayButton.rx.tap
            .map { NotificationTypeRadioButton.ButtonType.beforeTwoDay }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.beforeWeekButton.rx.tap
            .map { NotificationTypeRadioButton.ButtonType.beforeWeek }
            .do(onNext: { [weak self] type in
                self?.selectRadioButton(type: type)
            })
            .bind(to: self.selectedType)
            .disposed(by: self.disposeBag)
        
        self.everydayButton.rx.tap
            .map { NotificationTypeRadioButton.ButtonType.everyday }
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
    
    private func selectRadioButton(type: NotificationTypeRadioButton.ButtonType) {
        self.targetDayButton.isSelected = type == .targetDay
        self.beforeDayButton.isSelected = type == .beforeDay
        self.beforeTwoDayButton.isSelected = type == .beforeTwoDay
        self.beforeWeekButton.isSelected = type == .beforeWeek
        self.everydayButton.isSelected = type == .everyday
    }
}

extension Reactive where Base: NotificationButtonGropView {
    var selectedType: ControlEvent<NotificationTypeRadioButton.ButtonType> {
        return ControlEvent(events: base.selectedType)
    }
}
