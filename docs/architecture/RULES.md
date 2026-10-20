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

## 한눈에 보기

| # | 규칙 | 강제 수단 | 베이스라인 |
|---|---|---|---|
| R1 | 새 코드는 Combine + ViewModel. RxSwift·ReactorKit·`BaseVC` 신규 사용 금지 | 린트 `no_new_rx`, `no_base_vc` | 80건 동결 |
| R2 | ViewModel은 UI를 모르고, 의존은 주입받는다 | 린트 `viewmodel_no_uikit_import`, `viewmodel_no_uiapplication` | 1건 동결 |
| R3 | Realm 읽기/쓰기는 Repository에서만 | 린트 `realm_only_in_repository` | 0건 |
| R4 | Realm 모델을 바꾸면 schemaVersion(앱+위젯)과 마이그레이션을 같이 바꾼다 | 스크립트 `check-realm-schema.sh` + 라벨 `schema-change` | 0건 |
| R5 | ViewController/Cell은 Base 클래스를 상속 | 린트 `vc_inherits_base`, `cell_inherits_base` | 0건 |
| R6 | UI 표현은 토큰(색·폰트)·SwiftGen(문자열·이미지)·leading/trailing·클로저 초기화·화면 크기 고정 금지 | 린트 `no_uicolor_literal`, `no_uifont_name`, `no_localized_literal`, `snapkit_leading_trailing`, `no_then`, `no_screen_size` | 529건 동결 |
| R7 | 타입은 책임 하나만 진다 (타입 400·파일 600줄 초과는 사유 필수) | 린트 `type_body_length`·`file_length` + `length_disable_reason` | 0건 |
| R8 | `print`·`try!`·`as!` 금지 | 린트 `no_print`, `force_try`, `force_cast` | 15건 동결 |
| R9 | ViewModel 구조(Input/Output/Route/Config/Dependency/State)·Route는 VC extension | 문서 + AI 리뷰 | — |

린트 대상은 `seep-ios/`, `seep-iosTests/`, `widget/`(R1·R7·R8·`snapkit`·`then`만). `seep-ios/Generated/`(SwiftGen 산출물)는 제외.

---

## R1. 새 코드는 Combine + ViewModel로 쓴다

**규칙** — 새 화면·새 컴포넌트는 Combine 기반 `XxxViewModel` + `BaseViewController`로 만든다. `RxSwift`/`RxCocoa`/`ReactorKit`/`RxDataSources`를 새 파일에 import하지 않고, 새 VC가 `BaseVC`(Rx용)를 상속하지 않는다.

**이유** — 레포에 두 패턴(ReactorKit 레거시 / Combine ViewModel 신규 — `HomeViewModel`)이 섞여 있다. 패턴이 둘이면 AI가 매번 어느 쪽을 따를지 추측하고, 리뷰어는 두 방식을 다 읽어야 한다. 이동 방향을 하나로 고정해야 섞인 상태가 줄어든다.

**좋은 예**
```swift
import Combine

final class FinishedViewModel {
    let input = Input()
    let output = Output()
}

final class FinishedViewController: BaseViewController { ... }
```

**나쁜 예**
```swift
import ReactorKit                                   // ❌ 새 파일
final class FinishedViewController: BaseVC, View { } // ❌ BaseVC 신규 상속
```

**강제 수단** — SwiftLint `no_new_rx`, `no_base_vc`.

**예외(베이스라인)** — 기존 Reactor 화면(Write, WishDetail, WishEdit, Finished, Notification, SharePhoto, Splash, PageItem)의 import·상속 80건 동결. 그 화면을 **크게** 고칠 때는 ViewModel로 옮기는 걸 우선 검토한다(옮기면 베이스라인 항목이 저절로 사라진다). `seep-ios/features/base/`는 두 패턴의 공용 기반이라 제외.

---

## R2. ViewModel은 UI를 모르고, 의존은 주입받는다

**규칙** — `*ViewModel.swift`는 `import UIKit` 금지, `UIApplication.shared` 금지. 외부 의존(Repository, Preference, NotificationManager 등)은 `Dependency`로 주입받고 **protocol 타입**으로 둔다.

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
UIApplication.shared.open(url)                 // ❌ → Route(.openURL(url)) 로 VC에서
NotificationManager.shared.cancel(wish)        // ❌ 싱글턴 직접 호출 → Dependency 로
```

**강제 수단** — SwiftLint `viewmodel_no_uikit_import`, `viewmodel_no_uiapplication`. protocol 타입 여부는 문서 + 리뷰.

**예외(베이스라인)** — `HomeFilterHeaderViewModel`의 `import UIKit` 1건 동결.

---

## R3. Realm 읽기/쓰기는 Repository에서만 한다

**규칙** — `Realm()` 생성, `realm.objects/write/add/delete`는 `seep-ios/Repository/`(그리고 레거시 `seep-ios/services/`)에서만 한다. ViewModel·Reactor·VC는 Repository protocol을 통해서만 데이터를 다룬다.

**이유** — 이 앱의 "서버"는 로컬 Realm이다. 저장소 접근이 흩어지면 정렬·필터·완료 처리 같은 도메인 규칙이 화면마다 달라지고, 테스트에서 Realm을 목으로 바꿀 수 없다.

**좋은 예** — `WishRepository`(protocol) + `WishRepositoryImpl`, `HomeViewModel.Dependency.wishRepository`.

**나쁜 예**
```swift
// HomeViewModel.swift
let realm = try? Realm()                       // ❌
realm?.objects(WishDTO.self)
```

**강제 수단** — SwiftLint `realm_only_in_repository`.

**예외** — `AppDelegate.swift`(Realm 설정·마이그레이션), `widget/`(앱 Repository를 쓸 수 없는 별도 익스텐션 타깃이라 Provider에서 직접 읽는다 — 읽기 전용으로만). 레거시 `WishServices`는 Reactor 화면이 쓰는 중이라 허용하되, 새 기능은 `WishRepository`에 메서드를 추가한다.

---

## R4. Realm 모델을 바꾸면 schemaVersion과 마이그레이션을 같이 바꾼다

**규칙** — `seep-ios/model/dto/*.swift`(Realm `Object`)의 저장 프로퍼티를 추가·삭제·타입 변경하면 같은 PR에서
1. `schemaVersion`을 올린다 — **앱(`AppDelegate.swift`)과 위젯 Provider(`widget/**/*Provider.swift`, 현재 4곳) 전부 같은 값**으로,
2. `AppDelegate.setupRealmConfig()`의 `migrationBlock`에 `oldSchemaVersion < 새버전` 분기를 추가한다.

**이유** — 로컬 DB 앱에서 스키마 불일치는 **업데이트 직후 실행 크래시 = 사용자 데이터 손실**이다. 위젯은 같은 App Group의 Realm 파일을 자기 설정으로 열기 때문에, 앱만 올리고 위젯을 빼먹으면 위젯이 깨진다. 사람이 기억하기 어려운 5곳 동기화라 기계로 막는다.

**좋은 예**
```swift
config.schemaVersion = 4                       // AppDelegate + widget/*Provider.swift 전부 4
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
- 항상: 앱·위젯의 `schemaVersion` 값이 모두 같은지.
- CI(`BASE_REF` 지정 시): `model/dto/`가 바뀌었는데 `schemaVersion`이 base와 같으면 실패.
- 라벨 `schema-change`가 붙어 리뷰어가 마이그레이션 코드를 먼저 본다. 마이그레이션 TC(구버전 데이터 → 신버전 실행)는 수동/자동화 TC로 반드시 넣는다 (`docs/process/e2e-and-manual-tests.md`).

**예외** — 저장되지 않는 computed 프로퍼티·메서드·주석만 바꿨다면 스크립트가 실패해도 PR 본문에 사유를 적고 리뷰어가 승인한다.

---

## R5. ViewController/Cell은 Base 클래스를 상속한다

**규칙** — VC는 `BaseViewController`, `UICollectionViewCell`은 `BaseCollectionViewCell`, `UITableViewCell`은 `BaseTableViewCell`을 상속한다.

**이유** — `cancellables`, `setup()`/`bindConstraints()` 호출 순서, `prepareForReuse`에서의 구독 해제를 한 곳에서 관리한다. 셀 재사용 시 구독이 안 풀려 이벤트가 중복되는 버그를 구조로 막는다.

**강제 수단** — SwiftLint `vc_inherits_base`, `cell_inherits_base`.

**예외** — `seep-ios/features/base/` 자체, `widget/`(SwiftUI).

---

## R6. UI 표현은 토큰·SwiftGen·leading/trailing·클로저 초기화로 한다

**규칙**
- 색은 `UIColorExtension.swift`의 토큰(`.gray1`~`.gray5`, `.seepBlue`, `.tennisGreen` …)만. `UIColor(r:g:b:)` 직접 생성 금지 — 새 색은 토큰부터 추가한다.
- 폰트는 `UIFontExtension.swift`(`.appleBold(size:)` …)만. `UIFont(name:)` 금지.
- 문자열은 SwiftGen `Strings.xxx`, 이미지는 `Assets.xxx`. `"key".localized` 금지 (키 오타가 런타임에야 드러난다).
- SnapKit은 `left/right` 대신 `leading/trailing`.
- 신규 코드에서 `then` 금지 — 클로저 초기화를 쓴다.
- 레이아웃 크기를 화면(`UIScreen.main`·`UIUtils.windowBounds`·`RatioUtils`)으로 고정하지 않는다. 뷰·컬렉션뷰의 `bounds`, `layoutEnvironment.container`, `.fractionalWidth`로 계산하고, 창 크기가 바뀌면(`viewWillTransition`) 레이아웃을 무효화한다.

**이유** — 디자인 토큰을 거치지 않은 값은 리뷰에서 눈으로 잡을 수 없고, 다크모드·디자인 변경 때 전수 검색이 필요해진다. SwiftGen은 키 오타를 컴파일 에러로 바꾼다. 화면 크기로 고정한 값은 폴더블(아이폰 듀오)처럼 실행 중에 창 크기가 바뀌면 틀어진다 (GH-9).

**좋은 예**
```swift
private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = Strings.commonCancel
    label.textColor = .gray5
    label.font = .appleBold(size: 22)
    return label
}()

titleLabel.snp.makeConstraints {
    $0.leading.equalToSuperview().offset(20)
}
```

**나쁜 예**
```swift
let label = UILabel().then {                    // ❌ then
    $0.text = "home_title".localized            // ❌ 문자열 키 리터럴
    $0.textColor = UIColor(r: 51, g: 51, b: 51) // ❌ 색 리터럴
    $0.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 22) // ❌
}
make.left.equalToSuperview()                    // ❌ left
```

**강제 수단** — SwiftLint `no_uicolor_literal`, `no_uifont_name`, `no_localized_literal`, `snapkit_leading_trailing`, `no_then`, `no_screen_size`.

**예외(베이스라인)** — 기존 코드 529건 동결 (`snapkit` 189, `then` 159, `localized` 107, 색 45, 폰트 21, 화면 크기 8). `RatioUtils.swift`·`UIUtils.swift`(헬퍼 정의)는 `no_screen_size`에서 제외 — 남은 사용처가 정리되면 헬퍼를 지운다. 위젯(SwiftUI)은 색·폰트·문자열 규칙에서 제외 (`widget/extensions/ColorExtensions.swift` 사용). 문자열을 추가하면 `make swiftgen`으로 `Generated/Strings.swift`를 갱신해 같이 커밋한다.

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

**예외(베이스라인)** — `print` 7건, `try!` 8건 동결.

---

## R9. ViewModel 구조·Route 분리를 통일한다

**규칙** — 모든 ViewModel은 `Input / Output / Route / Config / Dependency / State` 중첩 타입 구조를 따른다 (`Route`·`Config`·`Dependency`·`State`는 필요할 때만). Route 처리는 ViewController의 `// MARK: Route` extension으로 분리한다.

**이유** — 화면이 같은 모양이어야 AI가 새 화면을 만들 때도, 사람이 리뷰할 때도 "어디를 보면 되는지"를 안다. 기준 구현은 `HomeViewModel`.

**좋은 예** — 루트 `CLAUDE.md`의 "ViewModel 구조" 템플릿, `seep-ios/features/Home/HomeViewModel.swift`.

**나쁜 예**
```swift
final class FinishedViewModel {
    let didTapButton = PassthroughSubject<Void, Never>()   // ❌ Input 밖에 흩어진 입력
    var wishes: [Wish] = []                                // ❌ State 밖 상태
}
```

**강제 수단** — 이 문서 + `CLAUDE.md` + AI 리뷰. 반복 지적이 쌓이면 부분 규칙을 린트로 승격한다.

---

## 베이스라인 운영

- `.swiftlint-baseline.json`(`make lint-baseline`으로 생성). 베이스라인에 있는 위반은 보고되지 않는다. 파일을 옮기거나 크게 고쳐 매칭이 깨지면 그때 고친다.
- **custom_rules의 `message`를 바꾸면 베이스라인 매칭이 깨진다**(메시지가 매칭 키에 포함). 메시지를 바꿨으면 같은 PR에서 `make lint-baseline`으로 재생성하고, 항목 수가 늘지 않았는지 확인한다.
- 베이스라인은 **줄어들기만** 해야 한다. 항목이 늘어나는 PR은 리뷰어가 사유를 확인한다 (`baseline-change` 라벨).

## 규칙을 바꾸는 방법

1. PR 리뷰에서 같은 지적이 **3번** 이상 나오면 규칙 후보가 된다.
2. 기계 판별 가능하면 린트(custom_rule) → 아니면 스크립트 → 그래도 안 되면 이 문서.
3. 10개를 넘기면 기존 규칙을 합치거나 뺀다. 규칙 변경 PR은 이 문서·`.swiftlint.yml`·`CLAUDE.md`를 한 번에 바꾼다 (`verification-change` 라벨이 붙는다).
