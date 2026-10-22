//
//  ViewExtensions.swift
//  widgetExtension
//
//  Created by Hyun Sik Yoo on 2021/12/04.
//

import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// containerBackground가 없으면 위젯 대신 "Please adopt containerBackground API"를 그린다.
    func widgetBackground(_ color: Color) -> some View {
        containerBackground(color, for: .widget)
    }
}

extension WidgetConfiguration {
    /// 기본 content margin(약 16pt)을 끈다. 각 위젯 뷰가 자체 여백을 갖고 있어 겹치면 잘린다.
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        contentMarginsDisabled()
    }
}
