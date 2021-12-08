//
//  ViewExtensions.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/04.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
