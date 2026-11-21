import WidgetKit

/// 위젯 타임라인 다시 그리기. 동기화로 다른 기기의 변경을 받았을 때 쓴다 (GH-93)
enum WidgetReloader {
    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
