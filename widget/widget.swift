import WidgetKit
import SwiftUI
import Intents

@main
struct widgets: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        SmallWriteWidget()
        SmallRemainWidget()
        MediumVerticalWidget()
        MediumHorizontalWidget()
        CheckWidget()
        LockScreenDdayWidget()
        LockScreenRemainWidget()
        if #available(iOS 18.0, *) {
            SeepWriteControl()
        }
    }
}
