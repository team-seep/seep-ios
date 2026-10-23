import Foundation
import Observation

extension SharePhotoViewModel {
    enum ShareType: Equatable {
        case emoji
        case photo
    }

    enum Action: Equatable {
        case onAppear
        case tooltipDidDisappear
        case doubleTapCard
        case tapEmojiTab
        case tapPhotoTab
        case selectPhoto(String)
        case selectEmoji(String)
        /// 화면이 그린 카드 PNG. 그리지 못했으면 nil
        case tapShare(pngData: Data?)
        case routeHandled
    }

    struct State: Equatable {
        /// 카드 왼쪽 위 마감일 "2026.12.20". 날짜가 없으면 nil(숨김)
        var dateText: String?
        /// 카드 D-day 뱃지. 날짜가 없으면 nil(숨김)
        var ddayText: String?
        var title = ""
        /// 카드 가운데 이모지. 이모지 탭에서 바꿔도 위시의 이모지는 그대로다
        var emoji = ""
        var emojiBackground = ShareCardPalette.fallback
        var isTextBlack = true
        var isTooltipVisible = false
        var shareType: ShareType = .emoji
        var photoIds: [String] = []
        var selectedPhotoId: String?
        var isSaving = false

        /// 카드에 고른 사진을 깔지(사진 탭 + 고른 사진 있음)
        var showsPhotoBackground: Bool {
            shareType == .photo && selectedPhotoId != nil
        }
    }

    enum Route: Equatable {
        /// 앨범 권한이 없다 — "설정"으로 보내는 알럿
        case permissionDeniedAlert(message: String)
        case errorAlert(message: String)
        /// 앨범에 저장했다 — 화면을 닫고 토스트
        case saved
    }

    struct Config {
        let wish: Wish
    }

    struct Dependency {
        let photoLibrary: PhotoLibraryProviding
        let userDefaults: UserDefaultsUtils
        let averageColor: (String) -> ShareCardRGB?
        let now: () -> Date
        let calendar: Calendar

        init(
            photoLibrary: PhotoLibraryProviding = PhotoLibrary(),
            userDefaults: UserDefaultsUtils = UserDefaultsUtils(),
            averageColor: @escaping (String) -> ShareCardRGB? = ShareCardPalette.averageColor(of:),
            now: @escaping () -> Date = Date.init,
            calendar: Calendar = .current
        ) {
            self.photoLibrary = photoLibrary
            self.userDefaults = userDefaults
            self.averageColor = averageColor
            self.now = now
            self.calendar = calendar
        }
    }
}

/// 위시를 한 장의 카드로 만들어 앨범에 저장한다 (GH-64 TC-1201~1203, 기존 SharePhotoReactor)
@Observable
final class SharePhotoViewModel {
    let screenName: ScreenName = .sharePhoto
    private(set) var state = State()
    private(set) var route: Route?

    private let config: Config
    private let dependency: Dependency

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        state = makeInitialState()
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            // 처음 한 번만 "두 번 탭하면 글자색" 말풍선을 보여준다
            state.isTooltipVisible = !dependency.userDefaults.getSharePhotoTooltipIsShow()

        case .tooltipDidDisappear:
            dependency.userDefaults.setSharePhotoTooltipIsShow(isShown: true)
            state.isTooltipVisible = false

        case .doubleTapCard:
            state.isTextBlack.toggle()

        case .tapEmojiTab:
            state.shareType = .emoji

        case .tapPhotoTab:
            Task { @MainActor in await openPhotoTab() }

        case .selectPhoto(let photoId):
            state.selectedPhotoId = photoId

        case .selectEmoji(let emoji):
            state.emoji = emoji
            state.emojiBackground = dependency.averageColor(emoji) ?? ShareCardPalette.fallback

        case .tapShare(let pngData):
            guard !state.isSaving else { return }
            guard let pngData else {
                route = .errorAlert(message: Strings.SharePhoto.saveFailed)
                return
            }
            state.isSaving = true
            Task { @MainActor in await save(pngData) }

        case .routeHandled:
            route = nil
        }
    }

    // MARK: Private

    private func makeInitialState() -> State {
        let wish = config.wish
        var state = State()
        state.title = wish.title
        state.emoji = wish.emoji
        state.emojiBackground = dependency.averageColor(wish.emoji) ?? ShareCardPalette.fallback
        if let endDate = wish.endDate {
            state.dateText = Self.dateText(endDate, calendar: dependency.calendar)
            state.ddayText = Self.ddayText(endDate: endDate, now: dependency.now(), calendar: dependency.calendar)
        }
        return state
    }

    @MainActor
    private func openPhotoTab() async {
        guard await ensureAuthorization() else { return }
        let ids = dependency.photoLibrary.fetchPhotoIds()
        state.photoIds = ids
        if state.selectedPhotoId == nil {
            state.selectedPhotoId = ids.first
        }
        state.shareType = .photo
    }

    @MainActor
    private func save(_ pngData: Data) async {
        defer { state.isSaving = false }
        guard await ensureAuthorization() else { return }
        do {
            try await dependency.photoLibrary.savePNG(pngData)
            route = .saved
        } catch {
            route = .errorAlert(message: Strings.SharePhoto.saveFailed)
        }
    }

    /// 권한이 없으면 묻고, 거절됐으면 "설정" 알럿을 띄운다
    @MainActor
    private func ensureAuthorization() async -> Bool {
        var status = dependency.photoLibrary.authorizationStatus()
        if status == .notDetermined {
            status = await dependency.photoLibrary.requestAuthorization()
        }
        guard status == .authorized else {
            route = .permissionDeniedAlert(message: Strings.sharePhotoDenyMessage)
            return false
        }
        return true
    }

    static func dateText(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ko")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    /// 카드 D-day. 당일은 "D-Day", 지난 날은 "D+n", 365일 넘게 남으면 "먼훗날" (기존 공유 카드 규칙)
    static func ddayText(endDate: Date, now: Date, calendar: Calendar) -> String {
        let remainDay = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: endDate)
        ).day ?? -1

        if remainDay < 0 {
            return "D+\(abs(remainDay))"
        } else if remainDay == 0 {
            return "D-Day"
        } else if remainDay <= 365 {
            return "D-\(remainDay)"
        } else {
            return Strings.homeInFarFurture
        }
    }
}
