import AppIntents

/// 단축어·Siri·Spotlight 에 싶 적기를 노출한다. 컨트롤과 같은 `OpenWriteIntent` (GH-49 R-7)
/// App Shortcuts 문구는 빌드 때 상수로 뽑혀야 해서 SwiftGen 대신 문자열을 직접 쓴다
struct SeepAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenWriteIntent(target: .wantToDo, source: .shortcut),
            phrases: ["\(.applicationName)에 하고 싶은 것 적기"],
            shortTitle: "하고 싶은 것 적기",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenWriteIntent(target: .wantToGet, source: .shortcut),
            phrases: ["\(.applicationName)에 갖고 싶은 것 적기"],
            shortTitle: "갖고 싶은 것 적기",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenWriteIntent(target: .wantToGo, source: .shortcut),
            phrases: ["\(.applicationName)에 가고 싶은 곳 적기"],
            shortTitle: "가고 싶은 곳 적기",
            systemImageName: "square.and.pencil"
        )
    }
}
