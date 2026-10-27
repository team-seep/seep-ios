import Foundation

/// 기기 언어를 바꾼 뒤 처음 앱을 열면 예약해 둔 D-day 알림을 다시 만든다 (GH-100 R-14).
/// 로컬 알림 문구는 예약할 때 정해져서, 다시 예약하지 않으면 예전 언어로 울린다. 같은 알림 id 로 덮어써서 개수·시간은 그대로다
struct NotificationLanguageRefresh {
    /// 이 버전 전에 예약한 알림은 모두 한국어였다
    static let legacyLanguage = "ko"

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol
        let preference: Preference
        /// 지금 앱이 보여 주는 언어. 번역이 없는 기기 언어면 원문(ko)이다
        let currentLanguage: () -> String

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared,
            preference: Preference = .shared,
            currentLanguage: @escaping () -> String = { Bundle.main.preferredLocalizations.first ?? NotificationLanguageRefresh.legacyLanguage }
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
            self.preference = preference
            self.currentLanguage = currentLanguage
        }
    }

    let dependency: Dependency

    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
    }

    /// 다시 예약한 위시 수를 돌려준다
    @discardableResult
    func run() -> Int {
        let language = dependency.currentLanguage()
        let scheduledLanguage = dependency.preference.notificationLanguage ?? Self.legacyLanguage
        guard language != scheduledLanguage else { return 0 }

        // 못 이룬 위시만 알림이 걸려 있다. 날짜·알림이 없는 위시는 reserveNotifications 가 건너뛴다
        let wishes = [Category.wantToDo, .wantToGet, .wantToGo].flatMap { category in
            dependency.wishRepository.fetchWishes(category: category, sort: .deadlineOrder, isOnlyFinished: false)
        }
        for wish in wishes {
            dependency.notificationManager.reserveNotifications(wish: wish)
        }
        dependency.preference.notificationLanguage = language
        return wishes.count
    }
}
