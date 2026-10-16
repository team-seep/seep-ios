# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**싶(seep)** 은 하고 싶은 것·갖고 싶은 것·가고 싶은 곳을 적는 위시리스트 iOS 앱입니다. 서버 없이 **로컬 Realm**에 저장하고, App Group으로 **위젯**과 데이터를 공유하며, D-day **로컬 알림**을 예약합니다.

- 타깃: `seep-ios`(앱), `widgetExtension`(WidgetKit, SwiftUI), `seep-iosTests`(XCTest)
- iOS 16.0+, UIKit 코드 기반 UI(SnapKit). SwiftUI는 위젯에서만
- 의존성: Swift Package Manager (Realm, Combine/CombineCocoa, RxSwift·ReactorKit(레거시), SnapKit, Kingfisher, Lottie, PanModal, ISEmojiView, Firebase)
- Git-flow, 메인 개발 브랜치 `develop`, 원격 `team-seep/seep-ios`

## 필수 명령어

```bash
make lint            # SwiftLint(새 위반만) + scripts/check-realm-schema.sh — 코드 작성 후 반드시
make lint-fix        # SwiftLint 자동 수정
make test            # 유닛 테스트 + build/summary.md (결과 수·실패 목록)
make swiftgen        # Localization.strings / xcassets 변경 후 Generated/ 갱신
make lint-baseline   # 베이스라인 재생성 (custom_rules 메시지를 바꿨을 때만)
```

빌드:
```bash
xcodebuild build \
  -project seep-ios.xcodeproj \
  -scheme seep-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<UDID>'
```
- 시뮬레이터는 `xcrun simctl list devices available | grep iPhone`으로 먼저 확인한다. 기기명은 머신마다 다르다.
- 스킴은 `seep-ios` 하나(Debug = dev 번들 `macgongmon.seep-ios.dev`, 모듈명 `seep_ios_dev` / Release = `macgongmon.seep-ios`). 위젯은 `widgetExtension` 스킴.
- 일반 그룹 구조라(동기화 폴더는 `seep-ios/model/Error`, `seep-ios/log`, `seep-iosTests/Log`뿐) **새 파일은 `project.pbxproj`에 타깃 멤버로 등록해야 빌드에 들어간다.** 테스트 파일은 `seep-iosTests` 타깃, 위젯과 같이 쓰는 파일(`WishDTO` 등)은 `widgetExtension` 타깃에도 넣는다. 등록이 빠지면 빌드는 통과해도 그 파일이 컴파일되지 않으니, 추가한 테스트가 실제로 실행됐는지 결과 수로 확인한다.
- Realm은 20.0.6(Xcode 26.1~27 지원). CI는 `macos-26` 러너.
- 서명 없이 빌드할 때 `CODE_SIGNING_ALLOWED=NO`를 쓰지 않는다 — App Group 엔타이틀먼트가 빠져 실행 직후 크래시한다. 대신 `CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=`.

## 개발 프로세스 (AI 개발 흐름)

**의도(이슈 TC) → 규칙 안에서 구현 → TC에서 테스트 도출 → 증거 → PR.** 사람 리뷰어는 diff 전체가 아니라 의도·경계·증거만 본다.

| 문서 | 내용 |
|---|---|
| [docs/process/planning.md](docs/process/planning.md) | AI 기획 추천(매일) → `approved` 승인 → 자동 개발(매일) → 출시 2주 뒤 사용량(매주). 서버리스 조건, 트래킹 이벤트 형식 |
| [docs/process/pr-process.md](docs/process/pr-process.md) | 전체 흐름 한 장 요약, 위험도(경량/풀코스), "PR 만들어줘" 시 Claude가 하는 일 |
| [docs/process/tech-spec-process.md](docs/process/tech-spec-process.md) | GitHub Issue = 테크스펙(요약·요구사항·TC). 이슈 번호가 티켓 키 (`GH-12`) |
| [docs/process/testing.md](docs/process/testing.md) | 테스트 3계층(유닛/자동화/수동), 네이밍 `test_GH{n}_TC{m}_{조건}_{기대결과}()`, 목 규칙 |
| [docs/process/e2e-and-manual-tests.md](docs/process/e2e-and-manual-tests.md) | 자동화/수동 분류, UI 변경 공통 체크, 영역별(위젯·마이그레이션·알림) 체크 |
| [docs/process/verification-change.md](docs/process/verification-change.md) | `verification-change`·`baseline-change`·`schema-change` 라벨 |
| [docs/architecture/RULES.md](docs/architecture/RULES.md) | 아키텍처 규칙 R1~R9 (규칙/이유/예시/강제 수단/예외) |

작업 시 지킬 것:
- **브랜치**: `feature/GH-{이슈}-{설명}` (develop 기반). 브랜치명에서 이슈 번호를 읽어 `gh issue view`로 요구사항·TC를 확인하고 시작한다.
- **TC가 먼저다.** 이슈에 없는 케이스를 테스트로 만들려면 이슈에 TC를 먼저 추가한다(추가 전 사용자 확인). TC 번호는 이슈 안에서 유일하고 파일마다 1부터 다시 세지 않는다.
- **테스트 계층 배정은 승인받는다.** TC별로 유닛/자동화/수동 표를 먼저 보여주고, 승인 후 유닛 테스트 코드만 작성한다.
- **PR**: `.github/PULL_REQUEST_TEMPLATE.md`를 채워 `gh pr create --base develop`. 본문(위험도·커버리지 표·드리프트·설명이 필요한 결정)은 pr-process.md 절차대로 만들고, **생성 전에 본문을 보여주고 확인받는다.**
- 이슈 생성·수정, push, PR 생성은 외부에 보이는 작업이라 매번 확인받는다.
- **`approved` 라벨이 붙은 이슈**는 사람 승인이 끝난 것이다. `seep-run-approved` 스킬로 진행할 때는 브랜치·커밋·push·PR까지 확인 없이 한다(머지는 안 함).
- 프로젝트 스킬(`.claude/skills/`): `seep-idea-scout`(기획 추천), `seep-run-approved`(승인 기획 자동 개발), `seep-usage-report`(출시 후 사용량).
- 가슴속 3천원용 `3dollars:*` 플러그인 스킬(pr-body, test-cases, drift 등)은 지라·노션 전제라 이 레포에서 쓰지 않는다. 같은 단계를 위 문서대로 수행한다. 예외: `3dollars:simulator-test`는 레포의 `docs/process/testing.md`를 읽고 동작하므로 자동화 TC 실행에 쓴다.

## 아키텍처 규칙 요약

상세·예외는 [RULES.md](docs/architecture/RULES.md). 기존 위반은 `.swiftlint-baseline.json`에 동결, **새 위반만** 실패.

- **R1** 새 코드는 Combine + ViewModel. `RxSwift`/`ReactorKit` 새 import, `BaseVC` 신규 상속 금지 (기준 구현: `HomeViewModel`)
- **R2** `*ViewModel.swift`는 `import UIKit`·`UIApplication.shared` 금지. 의존은 `Dependency`로 주입, protocol 타입
- **R3** `Realm()`·`realm.write/objects/...`는 `seep-ios/Repository/`에서만 (예외: AppDelegate 설정, widget Provider, 레거시 `WishServices`)
- **R4** `model/dto/` 저장 프로퍼티를 바꾸면 `schemaVersion`을 **앱(AppDelegate) + 위젯 Provider 3곳 모두** 올리고 `migrationBlock`에 분기 추가
- **R5** VC는 `BaseViewController`, Cell은 `BaseCollectionViewCell`/`BaseTableViewCell` 상속
- **R6** 색은 `UIColorExtension` 토큰(`.gray5`, `.seepBlue`…), 폰트는 `UIFontExtension`(`.appleBold(size:)`…), 문자열은 SwiftGen `Strings.xxx`, 이미지는 `Assets.xxx`. SnapKit `leading/trailing`. `then` 금지
- **R7** 타입은 책임 하나. 타입 400·파일 600줄 초과는 `// swiftlint:disable:next type_body_length - {사유}`
- **R8** `print`·`try!`·`as!` 금지
- **R9** ViewModel 구조 Input/Output/Route/Config/Dependency/State, Route 처리는 VC `// MARK: Route` extension

## 로그 (트래킹 이벤트)

가슴속 3천원 iOS Log 모듈과 같은 형식이다 (`seep-ios/log/`).
- 이벤트: `ClickEvent`(GA `click`) / `ImpressionEvent`(`impression`) / `CustomEvent` — 공통 파라미터 `screen`, 클릭·노출은 `object_type`·`object_id`
- 전송: ViewModel `Dependency.logManager: LogManagerProtocol = LogManager.shared` → `sendEvent(event:)`. 화면명은 `Output.screenName`
- 페이지뷰: VC에서 `override var screenName: ScreenName { viewModel.output.screenName }` (BaseViewController가 viewDidLoad에서 전송)
- 테스트: `seep-iosTests/Log/MockLogManager.swift`의 `sentEvents`로 단언
- 새 값은 snake_case로 `LogObjectId`·`ScreenName`·`EventName`·`ParameterName`에 추가

## 디렉터리 구조

```
seep-ios/
├── features/{화면}/          # Home, write, wish-detail, wish-edit, finished, notification, share-photo, splash
│   ├── {Name}ViewController.swift / {Name}View.swift
│   ├── {Name}ViewModel.swift      # 신규 (Combine)
│   ├── {Name}Reactor.swift        # 레거시 (ReactorKit)
│   └── subviews/, cell/
├── features/base/            # BaseViewController(Combine), BaseVC(Rx), BaseView, Base*Cell, BaseCoordinator
├── features/shared/          # 공용 UI 컴포넌트
├── Repository/               # WishRepository(Protocol+Impl), RemoteConfigRepository — Realm 접근 지점
├── services/                 # WishServices (레거시, Reactor 화면용)
├── model/dto/                # Realm Object (WishDTO, NotificationDTO) — 바꾸면 R4
├── model/presentation/       # 도메인 모델 (Wish, SeepNotification, HashtagType)
├── log/                      # LogManager(Firebase Analytics), ClickEvent·ImpressionEvent·CustomEvent, ScreenName …
├── manager/                  # NotificationManager(로컬 알림), ToastManager
├── uilts/                    # Preference(UserDefaults), DateUtils, AlertUtils …
├── extensions/               # UIColorExtension(색 토큰), UIFontExtension(폰트) …
├── Generated/                # SwiftGen 산출물 (Strings.swift, Assets.swift) — 직접 수정 금지
└── Resources/                # xcassets, en.lproj/Localization.strings, Firebase plist, Lottie
widget/                       # small-write / small-remain / medium-horizontal / medium-vertical 위젯
seep-iosTests/                # {ViewModel}Tests.swift, Mock/Mock{Protocol}.swift
```

## 주요 개발 패턴

### ViewModel 구조 (R9)

```swift
import Foundation
import Combine

extension MyViewModel {
    struct Input {
        let viewDidLoad = PassthroughSubject<Void, Never>()
        let didTapFinish = PassthroughSubject<Wish, Never>()
    }

    struct Output {
        let wishes = CurrentValueSubject<[Wish], Never>([])
        let toast = PassthroughSubject<String, Never>()
        let route = PassthroughSubject<Route, Never>()
    }

    enum Route {
        case pushWishDetail(WishDetailReactor)
        case showErrorAlert(Error)
    }

    struct Config {
        let category: Category
    }

    struct State {
        var wishes: [Wish] = []
    }

    struct Dependency {
        let wishRepository: WishRepository
        let notificationManager: NotificationManagerProtocol

        init(
            wishRepository: WishRepository = WishRepositoryImpl(),
            notificationManager: NotificationManagerProtocol = NotificationManager.shared
        ) {
            self.wishRepository = wishRepository
            self.notificationManager = notificationManager
        }
    }
}

final class MyViewModel {
    let input = Input()
    let output = Output()
    private var state = State()
    private let config: Config
    private let dependency: Dependency
    private var cancellables = Set<AnyCancellable>()

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        bind()
    }

    private func bind() {
        input.didTapFinish
            .withUnretained(self)
            .sink { (owner: MyViewModel, wish: Wish) in
                owner.finishWish(wish)
            }
            .store(in: &cancellables)
    }

    private func finishWish(_ wish: Wish) {
        switch dependency.wishRepository.finishWish(wish: wish) {
        case .success(let finished):
            dependency.notificationManager.cancelNotifications(wish: finished)
        case .failure(let error):
            output.route.send(.showErrorAlert(error))
        }
    }
}
```

### ViewController

```swift
final class MyViewController: BaseViewController {
    private let viewModel: MyViewModel

    init(viewModel: MyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    private func bind() {
        viewModel.output.route
            .main                              // PublisherExtension: receive(on: DispatchQueue.main)
            .withUnretained(self)
            .sink { (owner: MyViewController, route: MyViewModel.Route) in
                owner.handleRoute(route)
            }
            .store(in: &cancellables)
    }
}

// MARK: Route
extension MyViewController {
    private func handleRoute(_ route: MyViewModel.Route) {
        switch route {
        case .pushWishDetail(let reactor):
            pushWishDetail(reactor: reactor)
        case .showErrorAlert(let error):
            showErrorAlert(error)
        }
    }
}
```

### Repository (R3)

- Protocol + Impl 구조 (`WishRepository` / `WishRepositoryImpl`). 쓰기 결과는 `Result<_, RepositoryError>`로 돌려준다 (`try!` 금지, R8).
- 새 조회/쓰기는 레거시 `WishServices`가 아니라 `WishRepository`에 메서드를 추가하고, `seep-iosTests/Mock/MockWishRepository.swift`도 같이 맞춘다.

### UI

- 코드 기반 UI + SnapKit. 클로저 초기화 사용(`then` 금지), `leading/trailing`.
- 색·폰트·문자열·이미지는 토큰/SwiftGen만 (R6). 새 색은 `UIColorExtension`에 토큰부터, 새 문자열은 `Localization.strings`에 키 추가 → `make swiftgen`.
- 신규 셀은 `BaseCollectionViewCell` 상속, `setup()`/`bindConstraints()` 오버라이드.

## 코드 스타일

- Import 순서: 표준 → 서드파티, 사이 한 줄.
- 파일 구성: Import → 선언 → Nested Types → Properties → Initializers → Public → Private → Extensions.
- 주석은 "왜"에 집중.
- 커밋 메시지: `GH-12 : {한 줄 설명}` (이슈 없으면 `NO-ISSUE : …`).
