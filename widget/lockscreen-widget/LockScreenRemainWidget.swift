import SwiftUI
import WidgetKit

/// 잠금화면 "남은 싶" 원형 위젯 — 완료하지 않은 위시 수 (GH-47 R-7)
struct LockScreenRemainWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "\(LockScreenRemainWidget.self)",
            provider: LockScreenProvider()
        ) { entry in
            LockScreenRemainEntryView(entry: entry)
        }
        .configurationDisplayName("남은 싶")
        .description("아직 못 이룬 위시가 몇 개인지 봐요")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenRemainEntryView: View {
    let entry: LockScreenEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("남은 싶")
                    .font(.custom("AppleSDGothicNeo-SemiBold", size: 10))
                    .opacity(0.7)
                Text("\(entry.remainCount)")
                    .font(.custom("AppleSDGothicNeoEB00", size: 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .widgetAccentable()
            }
            .padding(.horizontal, 4)
        }
        .widgetURL(entry.remainURL)
        .widgetBackground(Color.clear)
    }
}

struct LockScreenRemainEntryView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenRemainEntryView(entry: .preview)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
