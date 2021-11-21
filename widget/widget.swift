import WidgetKit
import SwiftUI
import Intents

@main
struct widgets: WidgetBundle {
  
  @WidgetBundleBuilder
  var body: some Widget {
    SmallWriteWidget()
    MediumWidget()
  }
}
