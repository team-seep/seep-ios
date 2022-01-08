//
//  WriteNotificationTableViewCell.swift
//  seep-ios
//
//  Created by Hyun Sik Yoo on 2022/01/08.
//

import UIKit

final class WriteNotificationTableViewCell: BaseTableViewCell {
    static let registerId = "\(WriteNotificationTableViewCell.self)"
    static let height: CGFloat = 56
    
    private let containerView = UIView().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(r: 225, g: 227, b: 231).cgColor
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .appleRegular(size: 16)
        $0.textColor = .gray5
        $0.text = "당일, 오전 11시 00분"
    }
    
    private let rightArrowImage = UIImageView().then {
        $0.image = UIImage(named: "ic_arrow_right")
    }
    
    override func setup() {
        self.selectionStyle = .none
        self.addSubViews([
            self.containerView,
            self.titleLabel,
            self.rightArrowImage
        ])
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(16)
            make.centerY.equalTo(self.containerView)
            make.right.equalTo(self.rightArrowImage.snp.left).offset(-16)
        }
        
        self.rightArrowImage.snp.makeConstraints { make in
            make.centerY.equalTo(self.containerView)
            make.right.equalTo(self.containerView).offset(-16)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
    }
}
