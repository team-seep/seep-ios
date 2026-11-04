import SwiftUI
import WidgetKit

/// 잠금화면 "다가오는 싶 D-day" 위젯 — 직사각형·원형·한 줄 (GH-47 R-1, R-3~R-6)
struct LockScreenDdayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "\(LockScreenDdayWidget.self)",
            provider: LockScreenProvider()
        ) { entry in
            LockScreenDdayEntryView(entry: entry)
        }
        .configurationDisplayName("다가오는 싶 D-day")
        .description("가장 가까운 D-day 위시를 잠금화면에서 봐요")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

/// 잠금화면은 시스템이 단색으로 칠하므로 색 대신 굵기·불투명도로 위계를 만든다 (R-8)
struct LockScreenDdayEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LockScreenEntry

    var body: some View {
        content
            .widgetURL(entry.ddayURL)
            .widgetBackground(Color.clear)
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryInline:
            inline
        default:
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let wish = entry.wish, let ddayText = entry.ddayText {
                Text(verbatim: Strings.Widget.LockScreen.nearestFormat(ddayText.dday))
                    .font(.custom("AppleSDGothicNeoEB00", size: 13))
                    .widgetAccentable()
                Text(verbatim: "\(wish.emoji) \(wish.title)")
                    .font(.custom("AppleSDGothicNeo-SemiBold", size: 16))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(ddayText.dueText)
                    .font(.custom("AppleSDGothicNeo-Medium", size: 12))
                    .opacity(0.6)
            } else {
                Text(verbatim: Strings.Widget.LockScreen.nearest)
                    .font(.custom("AppleSDGothicNeoEB00", size: 13))
                    .widgetAccentable()
                Text(verbatim: Strings.Widget.LockScreen.emptyTitle)
                    .font(.custom("AppleSDGothicNeo-SemiBold", size: 16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(verbatim: Strings.Widget.LockScreen.emptyCaption)
                    .font(.custom("AppleSDGothicNeo-Medium", size: 12))
                    .opacity(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                if let wish = entry.wish, let ddayText = entry.ddayText {
                    Text(wish.emoji)
                        .font(.system(size: 16))
                    Text(ddayText.dday)
                        .font(.custom("AppleSDGothicNeoEB00", size: ddayText.remainDay > DdayText.farFutureDays ? 13 : 18))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .widgetAccentable()
                } else {
                    Text(verbatim: "D-day")
                        .font(.custom("AppleSDGothicNeo-SemiBold", size: 10))
                        .opacity(0.7)
                    Text(verbatim: "–")
                        .font(.custom("AppleSDGothicNeoEB00", size: 18))
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var inline: some View {
        if let wish = entry.wish, let ddayText = entry.ddayText {
            return Text(verbatim: "\(wish.emoji) \(ddayText.dday) \(wish.title)")
        }
        return Text(LockScreenDdayPicker.remainText(count: entry.remainCount))
    }
}

struct LockScreenDdayEntryView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenDdayEntryView(entry: .preview)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
