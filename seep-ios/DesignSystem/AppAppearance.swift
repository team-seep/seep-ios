import SwiftUI

/// 설정 "화면 모드" (GH-85 R-3). 앱 루트에 `.preferredColorScheme`으로 건다. 위젯은 늘 시스템을 따른다
enum AppAppearance: String, CaseIterable {
    case system
    case light
    case dark

    /// `Preference`와 앱 루트(`@AppStorage`)가 같이 읽는 UserDefaults 키
    static let storageKey = "appearance"

    /// nil 이면 시스템 설정을 따른다
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
