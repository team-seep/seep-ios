//
//  UIScreenExtensions.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/06.
//

import UIKit

extension UIScreen {
    static var smallWidgetWidth: CGFloat {
        switch Self.main.bounds.size {
        case CGSize(width: 428, height: 926):
            return 170
            
        case CGSize(width: 414, height: 896):
            return 169
            
        case CGSize(width: 414, height: 736):
            return 159
            
        case CGSize(width: 390, height: 844):
            return 158
            
        case CGSize(width: 375, height: 812):
            return 155
            
        case CGSize(width: 375, height: 667):
            return 148
            
        case CGSize(width: 360, height: 780):
            return 155
            
        case CGSize(width: 320, height: 568):
            return 141
            
        default:
            return 155
        }
    }
    
    static var mediumWidgetWidth: CGFloat {
        switch Self.main.bounds.size {
        case CGSize(width: 428, height: 926):
            return 364
            
        case CGSize(width: 414, height: 896):
            return 360
            
        case CGSize(width: 414, height: 736):
            return 348
            
        case CGSize(width: 390, height: 844):
            return 338
            
        case CGSize(width: 375, height: 812):
            return 329
            
        case CGSize(width: 375, height: 667):
            return 321
            
        case CGSize(width: 360, height: 780):
            return 329
            
        case CGSize(width: 320, height: 568):
            return 292
            
        default:
            return 329
        }
    }
}
