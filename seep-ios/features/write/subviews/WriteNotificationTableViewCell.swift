//
//  WriteNotificationTableViewCell.swift
//  seep-ios
//
//  Created by Hyun Sik Yoo on 2022/01/08.
//

import UIKit

final class WriteNotificationTableViewCell: BaseTableViewCell {
    static let registerId = "\(WriteNotificationTableViewCell.self)"
    
    private let containerView = UIView().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(r: 225, g: 227, b: 231).cgColor
    }
}
