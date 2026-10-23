# 아키텍처 규칙 (RULES.md)

이 문서는 seep(싶) iOS 레포의 **아키텍처 규칙 9개**다.
AI가 코드를 많이 쓰는 환경에서 사람은 diff 전체가 아니라 **의도(TC)·경계·검증 증거**만 본다.
그래서 경계에 관한 규칙은 엄격하게, 화면 내부 구현은 관대하게 둔다.

## 운영 원칙

- **기계로 판별 가능한 규칙은 문서가 아니라 린트·스크립트로 강제한다.** 이 문서는 "왜"와 "예외"를 설명하는 곳이지, 위반을 잡는 곳이 아니다.
- **기존 위반은 베이스라인으로 동결하고 새 위반만 막는다.** 베이스라인에 있는 코드를 고칠 의무는 없지만, 그 파일을 크게 손댈 때 같이 고치는 걸 권장한다.
- 규칙은 10개를 넘기지 않는다. 새 규칙을 넣으려면 기존 규칙을 빼거나 합친다.
- 규칙 포맷: **규칙 한 문장 / 이유 / 좋은 예·나쁜 예 / 강제 수단 / 예외**.
- 강제 수단 우선순위: **린트(SwiftLint custom_rules) > 스크립트 > 문서**. 문서로만 강제되는 규칙은 R9 하나다.

> **SwiftUI 전환 완료 (GH-64, 2026-10).** 앱 전체가 SwiftUI + `@Observable` ViewModel이다(최소 iOS 18). UIKit은 `AppDelegate.swift`(Firebase·Realm·알림 델리게이트, UI 없음)만 쓴다. RxSwift·ReactorKit·SnapKit·Then·PanModal·CombineCocoa·ISEmojiView·Lottie·Kingfisher·SwiftyBeaver 의존성은 지웠고, 그 시절 린트 규칙(`no_new_rx`, `no_base_vc`, `vc_inherits_base`, `cell_inherits_base`, `snapkit_leading_trailing`, `no_then`, `no_uicolor_literal`, `no_uifont_name`, `no_screen_size`)도 지웠다.

## 한눈에 보기

| # | 규칙 | 강제 수단 | 베이스라인 |
|---|---|---|---|
| R1 | 화면은 SwiftUI View + `@Observable` ViewModel. UIKit·UIKit 래퍼 금지(`AppDelegate`·`SystemPasteboard` 제외) | 린트 `no_uikit` | 0건 |
| R2 | ViewModel은 UI를 모르고(UIKit·SwiftUI import 금지), 의존은 주입받는다 | 린트 `viewmodel_no_uikit_import`, `viewmodel_no_swiftui_import`, `viewmodel_no_uiapplication` | 0건 |
| R3 | Realm 읽기/쓰기는 Repository에서만 | 린트 `realm_only_in_repository` | 0건 |
| R4 | Realm 모델을 바꾸면 schemaVersion(앱+위젯)과 마이그레이션을 같이 바꾼다 | 스크립트 `check-realm-schema.sh` + 라벨 `schema-change` | 0건 |
| R5 | 시트·풀스크린은 `seepSheet`/`seepFullScreenCover`로만 띄운다 | 린트 `no_raw_sheet` | 0건 |
| R6 | UI 표현은 토큰(색·폰트)·SwiftGen(문자열·이미지)·컨테이너 기준 크기 | 린트 `no_color_literal`, `no_font_custom`, `no_text_literal`, `no_localized_literal` | 0건 |
| R7 | 타입은 책임 하나만 진다 (타입 400·파일 600줄 초과는 사유 필수) | 린트 `type_body_length`·`file_length` + `length_disable_reason` | 0건 |
| R8 | `print`·`try!`·`as!` 금지 | 린트 `no_print`, `force_try`, `force_cast` | 0건 |
| R9 | ViewModel 구조(Action/State/Route/Config/Dependency, `send(_:)`)·Route는 View에서 처리 | 문서 + AI 리뷰 | — |

린트 대상은 `seep-ios/`, `seep-iosTests/`, `widget/`(R1·R7·R8·`snapkit`·`then`만). `seep-ios/Generated/`(SwiftGen 산출물)는 제외.

---

## R1. 화면은 SwiftUI View + `@Observable` ViewModel로 쓴다

**규칙** — 화면·컴포넌트는 SwiftUI `View` + `@Observable` `XxxViewModel`로 만든다. `seep-ios/`에서 `import UIKit`, `UIViewRepresentable`/`UIViewControllerRepresentable`/`UIHostingController`를 쓰지 않는다(`AppDelegate.swift` 제외).

**이유** — 전환 전에는 세 패턴(ReactorKit / Combine ViewModel + UIKit / 위젯 SwiftUI)이 섞여 있었다. 패턴이 여럿이면 AI가 매번 어느 쪽을 따를지 추측하고, 리뷰어는 모든 방식을 읽어야 한다. 위젯·잠금화면 위젯·컨트롤이 이미 SwiftUI라 앱 화면도 SwiftUI로 모으면 컴포넌트·토큰을 같이 쓴다(GH-64). UIKit 래퍼도 막는 이유는 "일단 래퍼로" 남은 화면이 전환을 끝나지 않게 만들기 때문이다.

**좋은 예**
```swift
import Foundation
import Observation

@Observable
final class FinishedViewModel {
    private(set) var state = State()
    func send(_ action: Action) { ... }
}

struct FinishedView: View {
    @State var viewModel: FinishedViewModel
    var body: some View { ... }
}
```

**나쁜 예**
```swift
import UIKit                                        // ❌ 새 파일
final class FinishedViewController: BaseViewController { }  // ❌ 새 UIKit 화면
struct MapView: UIViewRepresentable { }             // ❌ UIKit 래퍼
import ReactorKit                                   // ❌
```

**강제 수단** — SwiftLint `no_uikit`.

**예외** — `AppDelegate.swift`는 `@UIApplicationDelegateAdaptor`로 Firebase·Realm·알림 델리게이트를 맡는 UI 아닌 코드라 제외. `AppShell/SystemPasteboard.swift`는 iOS SwiftUI에 클립보드 쓰기 API가 없어 `UIPasteboard`를 `PasteboardWriting` 프로토콜 뒤에 감싼 파일이라 제외(GH-77). ViewModel은 프로토콜만 `Dependency`로 받는다. 테스트 타깃(`seep-iosTests/`)은 색 값 비교 등에 UIKit을 쓸 수 있다.

---

## R2. ViewModel은 UI를 모르고, 의존은 주입받는다

**규칙** — `*ViewModel.swift`는 `import UIKit`·`import SwiftUI` 금지, `UIApplication.shared` 금지. `Foundation`·`Observation`(필요하면 `Combine`)만 쓴다. 외부 의존(Repository, Preference, NotificationManager 등)은 `Dependency`로 주입받고 **protocol 타입**으로 둔다.

**이유** — ViewModel이 UI를 모르면 ViewModel 테스트만으로 화면 로직이 검증된다(VC는 테스트하지 않는다). 의존이 protocol이면 테스트에서 목으로 갈아끼울 수 있다 (`MockWishRepository`, `MockNotificationManager`).

**좋은 예**
```swift
struct Dependency {
    let wishRepository: WishRepository                       // protocol
    let notificationManager: NotificationManagerProtocol     // protocol

    init(
        wishRepository: WishRepository = WishRepositoryImpl(),
        notificationManager: NotificationManagerProtocol = NotificationManager.shared
    ) { ... }
}
```

**나쁜 예**
```swift
import UIKit                                   // ❌
import SwiftUI                                 // ❌ ViewModel 에서
UIApplication.shared.open(url)                 // ❌ → Route(.openURL(url)) 로 View 에서 openURL
NotificationManager.shared.cancel(wish)        // ❌ 싱글턴 직접 호출 → Dependency 로
```

**강제 수단** — SwiftLint `viewmodel_no_uikit_import`, `viewmodel_no_swiftui_import`, `viewmodel_no_uiapplication`. protocol 타입 여부는 문서 + 리뷰.


---

## R3. Realm 읽기/쓰기는 Repository에서만 한다

**규칙** — `Realm()` 생성, `realm.objects/write/add/delete`는 `seep-ios/Repository/`에서만 한다. ViewModel은 Repository protocol을 통해서만 데이터를 다룬다.

**이유** — 이 앱의 "서버"는 로컬 Realm이다. 저장소 접근이 흩어지면 정렬·필터·완료 처리 같은 도메인 규칙이 화면마다 달라지고, 테스트에서 Realm을 목으로 바꿀 수 없다.

**좋은 예** — `WishRepository`(protocol) + `WishRepositoryImpl`, `HomeViewModel.Dependency.wishRepository`.

**나쁜 예**
```swift
// HomeViewModel.swift
let realm = try? Realm()                       // ❌
realm?.objects(WishDTO.self)
```

**강제 수단** — SwiftLint `realm_only_in_repository`.

**예외** — `AppDelegate.swift`(Realm 설정·마이그레이션), `widget/`(앱 Repository를 쓸 수 없는 별도 익스텐션 타깃이라 Provider에서 직접 읽는다 — 읽기 전용으로만. 위젯에서 쓰기가 필요하면 앱·위젯 두 타깃에 넣은 `seep-ios/Repository/WidgetCheckRepository`처럼 Repository를 거친다 — GH-48).

---

## R4. Realm 모델을 바꾸면 schemaVersion과 마이그레이션을 같이 바꾼다

**규칙** — `seep-ios/model/dto/*.swift`(Realm `Object`)의 저장 프로퍼티를 추가·삭제·타입 변경하면 같은 PR에서
1. `schemaVersion`을 올린다 — **`seep-ios/Repository/RealmConfiguration.swift` 한 곳**(앱 `AppDelegate`와 위젯 Provider·인텐트가 `RealmConfiguration.shared`를 같이 쓴다, GH-48). 설정을 직접 만드는 위젯 Provider가 있으면 그 값도 같게,
2. `AppDelegate.setupRealmConfig()`의 `migrationBlock`에 `oldSchemaVersion < 새버전` 분기를 추가한다.

**이유** — 로컬 DB 앱에서 스키마 불일치는 **업데이트 직후 실행 크래시 = 사용자 데이터 손실**이다. 위젯은 같은 App Group의 Realm 파일을 열기 때문에, 앱만 올리고 위젯을 빼먹으면 위젯이 깨진다. 그래서 값을 한 곳(`RealmConfiguration`)에 모으고, 따로 쓴 곳이 남아 있으면 기계로 같은지 본다.

**좋은 예**
```swift
config.schemaVersion = 4                       // RealmConfiguration.shared (앱·위젯 공용)
config.migrationBlock = { migration, oldSchemaVersion in
    if oldSchemaVersion < 3 { ... }
    if oldSchemaVersion < 4 {
        migration.enumerateObjects(ofType: WishDTO.className()) { _, newObject in
            newObject?["isPinned"] = false
        }
    }
}
```

**강제 수단** — `scripts/check-realm-schema.sh` (`make lint`, CI `lint.yml`).
- 항상: `RealmConfiguration`·`AppDelegate`·`widget/**/*Provider.swift` 중 `schemaVersion`을 직접 쓴 곳의 값이 모두 같은지.
- CI(`BASE_REF` 지정 시): `model/dto/`가 바뀌었는데 `schemaVersion`이 base와 같으면 실패.
- 라벨 `schema-change`가 붙어 리뷰어가 마이그레이션 코드를 먼저 본다. 마이그레이션 TC(구버전 데이터 → 신버전 실행)는 수동/자동화 TC로 반드시 넣는다 (`docs/process/e2e-and-manual-tests.md`).

**예외** — 저장되지 않는 computed 프로퍼티·메서드·주석만 바꿨다면 스크립트가 실패해도 PR 본문에 사유를 적고 리뷰어가 승인한다.

---

## R5. 시트·풀스크린은 `seepSheet`/`seepFullScreenCover`로만 띄운다

**규칙** — SwiftUI에서 시트·풀스크린은 `.seepSheet(item:)`/`.seepFullScreenCover(item:)`(`seep-ios/AppShell/SeepSheet.swift`)로만 띄운다. `.sheet(`·`.fullScreenCover(`를 직접 부르지 않는다.

**이유** — 앱 잠금(GH-46)은 열려 있는 시트 위까지 가려야 한다. SwiftUI에서 루트에 덮은 화면은 그 위에 뜬 시트를 가리지 못하므로, 모든 시트 내용 루트에 `.appLockOverlay()`를 붙여야 한다. 한 곳(`seepSheet`)에서만 띄우게 하면 빠뜨릴 수 없다. 높이에 맞춘 detent·인디케이터도 같이 통일된다.

**좋은 예**
```swift
.seepSheet(item: $viewModel.route.sortSheet) { sheet in
    SortOrderSheet(viewModel: sheet)
}
```

**나쁜 예**
```swift
.sheet(item: $route) { ... }   // ❌ 잠금 오버레이·detent 규칙이 빠진다
```

**강제 수단** — SwiftLint `no_raw_sheet`(정의 파일 `SeepSheet.swift` 제외).

**예외** — `widget/`(시트 없음). 시스템 `.alert`·`.confirmationDialog`는 잠길 때 닫으므로 이 규칙 밖이다.

---

## R6. UI 표현은 토큰·SwiftGen으로 한다

**규칙** (SwiftUI)
- 색은 `seep-ios/DesignSystem/SeepColor.swift`의 토큰(`Color.gray5`, `.seepBlue` …)만. `Color(red:…)`·`Color(r:…)`·`Color(hex:)` 직접 생성 금지.
- 폰트는 `SeepFont.swift`(`Font.appleBold(size:)` …)만. `Font.custom(…)` 직접 호출 금지.
- 화면 문구는 `Text(Strings.xxx)`. `Text("문구")` 리터럴 금지(숫자·고유명사처럼 번역하지 않는 값은 `Text(verbatim:)`).
- 레이아웃 크기는 `UIScreen`이 아니라 컨테이너 기준(`containerRelativeFrame`, `GeometryReader`는 꼭 필요할 때만)으로 정한다. 넓은 화면 기둥은 `SeepLayout.maxContentWidth`.

**이유** — 디자인 토큰을 거치지 않은 값은 리뷰에서 눈으로 잡을 수 없고, 다크모드·디자인 변경 때 전수 검색이 필요해진다. SwiftGen은 키 오타를 컴파일 에러로 바꾼다. 화면 크기로 고정한 값은 폴더블(아이폰 듀오)처럼 실행 중에 창 크기가 바뀌면 틀어진다 (GH-9).

**좋은 예**
```swift
Text(Strings.homeTitle)
    .font(.appleBold(size: 22))
    .foregroundStyle(Color.gray5)
```

**나쁜 예**
```swift
Text("하고 싶은 것들이")                         // ❌ 문자열 리터럴
    .font(.custom("AppleSDGothicNeo-Bold", size: 22)) // ❌
    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2)) // ❌ 색 리터럴
```

**강제 수단** — SwiftLint `no_color_literal`, `no_font_custom`, `no_text_literal`, `no_localized_literal`.

**예외** — 위젯은 색·폰트·문자열 규칙에서 제외한다(위젯 문구는 위젯 타깃 안에 있다). 위젯 색 토큰은 앱과 같은 `seep-ios/DesignSystem/SeepColor.swift`를 쓴다(앱·위젯 두 타깃 멤버). 토큰 정의 파일(`SeepColor.swift`·`SeepFont.swift`)은 색·폰트 규칙에서 제외. 문자열을 추가하면 `make swiftgen`으로 `Generated/Strings.swift`를 갱신해 같이 커밋한다.

---

## R7. 타입은 책임 하나만 진다

**규칙** — 타입 하나는 책임 하나. 여러 기능을 맡으면 하위 ViewModel/View로 분리한다(예: `HomeViewModel` → `HomeFilterHeaderViewModel`, `HomeWishCellViewModel`). 책임이 하나인데 타입 400줄·파일 600줄을 넘으면 `// swiftlint:disable:next type_body_length - {사유}`로 예외를 건다.

**이유** — AI는 기존 파일에 계속 덧붙이는 경향이 있다. 줄 수는 책임이 섞였다는 **신호**로만 쓰고, 넘으면 사유를 말하게 한다. 같은 파일 extension으로 옮겨 줄 수만 맞추는 우회는 `file_length`가 막는다.

**강제 수단** — SwiftLint `type_body_length`, `file_length`, `length_disable_reason`(사유 없는 disable 금지).

---

## R8. `print`·`try!`·`as!` 금지

**규칙** — `print`를 남기지 않는다. `try!`/`as!` 대신 `try?`/`do-catch`, `as?` + `guard`.

**이유** — `try!`는 Realm 쓰기 실패 같은 드문 상황에서 앱을 죽인다. 로컬 DB 앱에서 크래시는 곧 데이터 신뢰 상실이다. `print`는 릴리즈에 남아 의미 없는 로그가 된다.

**좋은 예**
```swift
do {
    try realm.write { realm.delete(target) }
} catch {
    return .failure(.writeFailed)
}
```

**강제 수단** — SwiftLint `no_print`, `force_try`(error), `force_cast`(error).

**예외** — 없음. 남겨야 할 로그는 `os.Logger`로 쓴다(GH-76에서 베이스라인 7건을 고쳤다).

---

## R9. ViewModel 구조·Route 처리를 통일한다

**규칙** — SwiftUI ViewModel은 `@Observable final class`이고 중첩 타입 `Action / State / Route / Config / Dependency`를 쓴다(`Route`·`Config`는 필요할 때만).
- View는 `viewModel.send(.action)`으로만 입력을 보낸다.
- 화면 상태는 `private(set) var state: State` 하나로 읽는다.
- 화면 이동·시트·URL 열기는 `private(set) var route: Route?`로 내보낸다. View가 `.navigationDestination`/`.seepSheet(item:)`/`openURL`로 처리하고 `send(.routeHandled)`로 비운다. 탭·딥링크 이동은 `AppRouter`가 맡는다.

전환 전 Combine ViewModel(`Input/Output`)은 화면을 옮길 때 이 구조로 바꾼다.

**이유** — 화면이 같은 모양이어야 AI가 새 화면을 만들 때도, 사람이 리뷰할 때도 "어디를 보면 되는지"를 안다. 테스트는 `send` → `state`/`route` 단언 하나로 통일된다(`seep-iosTests/Features/ViewModelTestCase.swift`). 기준 구현은 GH-64 P1의 SwiftUI `HomeViewModel`.

**좋은 예** — 루트 `CLAUDE.md`의 "ViewModel 구조" 템플릿.

**나쁜 예**
```swift
@Observable final class FinishedViewModel {
    var wishes: [Wish] = []           // ❌ State 밖 상태, View가 직접 바꿀 수 있다
    func didTapButton() { }           // ❌ Action 밖 입력
}
```

**강제 수단** — 이 문서 + `CLAUDE.md` + AI 리뷰. 반복 지적이 쌓이면 부분 규칙을 린트로 승격한다.

---

## 베이스라인 운영

- `.swiftlint-baseline.json`(`make lint-baseline`으로 생성). 베이스라인에 있는 위반은 보고되지 않는다. 파일을 옮기거나 크게 고쳐 매칭이 깨지면 그때 고친다.
- **custom_rules의 `message`를 바꾸면 베이스라인 매칭이 깨진다**(메시지가 매칭 키에 포함). 메시지를 바꿨으면 같은 PR에서 `make lint-baseline`으로 재생성하고, 항목 수가 늘지 않았는지 확인한다.
- 베이스라인은 **줄어들기만** 해야 한다. 항목이 늘어나는 PR은 리뷰어가 사유를 확인한다 (`baseline-change` 라벨).
- 예외: 새 규칙을 켜면 기존 코드 위반이 한꺼번에 동결되어 항목이 늘어난다(GH-64 P0의 `no_uikit` 등). 그 PR 본문에 규칙별 동결 수를 적고, 이후 PR에서는 다시 줄어들기만 한다.

## 규칙을 바꾸는 방법

1. PR 리뷰에서 같은 지적이 **3번** 이상 나오면 규칙 후보가 된다.
2. 기계 판별 가능하면 린트(custom_rule) → 아니면 스크립트 → 그래도 안 되면 이 문서.
3. 10개를 넘기면 기존 규칙을 합치거나 뺀다. 규칙 변경 PR은 이 문서·`.swiftlint.yml`·`CLAUDE.md`를 한 번에 바꾼다 (`verification-change` 라벨이 붙는다).
