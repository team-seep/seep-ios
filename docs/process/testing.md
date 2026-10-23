# 테스트 작성 가이드

테스트는 **diff가 아니라 의도 문서(GitHub Issue 테크스펙)의 TC에서 도출한다.** AI가 코드를 쓰더라도 "무엇을 검증할지"는 사람이 TC 목록으로 먼저 승인하고, 코드는 그 다음이다.
의도 문서는 `docs/process/tech-spec-process.md`, 아키텍처 규칙은 `docs/architecture/RULES.md`.

## 흐름

```
GitHub Issue #n 의 TC-1..n
   │  "GH-12 테스트 케이스 도출해줘"  (브랜치명 feature/GH-12-… → gh issue view 12)
   ▼
TC별 계층 배정 (유닛 / 자동화 / 수동)  ──▶ 사람 승인
   │              │                  │
   ▼              ▼                  ▼
유닛 테스트 코드   simulator-test     PR 본문 체크박스
   │              │                  │
   ▼              ▼                  ▼
CI 결과 코멘트    스크린샷·영상 증거    작성자 체크
```

## 테스트의 세 계층

| 계층 | 무엇을 검증 | 실행 주체·시점 | 증거 |
|---|---|---|---|
| **1. 유닛 테스트 코드** | ViewModel Action→State/Route(SwiftUI)·Input→Output/Route(레거시), Repository 로직(정렬·필터·완료), 모델 변환(DTO↔도메인) | `xcodebuild test` — CI가 PR마다 | CI 결과 코멘트(통과 수·실패 목록) |
| **2. 자동화 테스트 TC** | 시뮬레이터를 에이전트가 조작해 화면을 실제로 거치는 E2E. 탭·스와이프·딥링크·위젯을 넣고 스크린샷·영상으로 판정 | `3dollars:simulator-test` 스킬 — PR 올리기 전, 이번 이슈 TC만 | PR 본문 "증거" 섹션 |
| **3. 수동 테스트 TC** | 시뮬레이터로 상황 자체를 만들 수 없어 실기기·사람이 필요한 것 | 작성자 — PR 올리기 전 | PR 본문 체크박스 |

- TC 하나는 **반드시 셋 중 하나 이상**에 배정된다. 어디에도 없는 TC가 있으면 PR을 열 수 없다.
- **위 계층을 먼저 쓴다.** 유닛으로 덮이면 유닛, 안 되면 자동화, 그것도 안 되면 수동. 계층을 내릴 때는 이유가 있어야 한다.
- 한 TC가 두 계층에 걸쳐도 된다 (알림 취소 호출은 유닛, 홈 목록 갱신은 자동화).
- **2와 3의 경계는 "시뮬레이터로 그 상황을 만들 수 있는가" 하나다.** 판정이 사람 눈이어야 한다는 건 2번이지 3번이 아니다.

### 무엇이 어느 계층인가

| 대상 | 계층 | 이유 |
|---|---|---|
| Input → Output/Route, State 전이, 토스트 문구 | 1 유닛 | ViewModel 경계에서 단언된다 |
| 알림 예약·취소 호출 (`NotificationManagerProtocol`) | 1 유닛 | 목으로 호출 기록 단언 (`MockNotificationManager`) |
| 정렬·필터·D-day 계산, DTO ↔ `Wish` 변환 | 1 유닛 | 순수 함수 |
| 화면 진입·전환, 바텀시트, 스와이프 삭제, 목록 갱신 | 2 자동화 | 실제 화면을 거쳐야 의미가 있다 |
| 위젯 렌더링·위젯 탭 딥링크(`widget://`) | 2 자동화 | 홈 화면에 위젯 추가 후 스크린샷, `simctl openurl` |
| 로컬 알림 권한 팝업 | 2 자동화 | `simctl privacy reset` 후 재현 |
| 다크모드·기기 폭·긴 제목·이모지·빈 목록 | 2 자동화 | 시뮬레이터 설정으로 상태를 만든다 |
| Realm 마이그레이션 (구버전 데이터 → 신버전) | 2 자동화 | 구버전 빌드 설치·데이터 생성 → 신버전 덮어 설치 |
| 로컬 알림이 **예정 시각에 실제로** 울리는지 | 3 수동 | 시간 경과·잠금화면 확인이 필요 (시뮬레이터 시간 조작 불가) |
| 사진 공유(인스타 스토리 등 외부 앱) | 3 수동 | 시뮬레이터에 대상 앱이 없다 |
| 실기기 위젯 갱신 주기, 앱스토어 이동 | 3 수동 | 시뮬레이터에 기능 자체가 없다 |

세부 항목과 화면 변경 PR 공통 체크는 `docs/process/e2e-and-manual-tests.md`.

## 1. 유닛 테스트 코드

### 파일 위치 · 네이밍

```
seep-iosTests/
├── Features/                         # 화면별 기능 테스트 (GH-64~) — 동기화 폴더, 넣기만 하면 실행된다
│   ├── ViewModelTestCase.swift       # 공용 바탕: logManager(MockLogManager)·waitUntil·observeChange·clickEvents
│   └── {화면}/{화면}FeatureTests.swift
├── {ViewModel이름}Tests.swift        # 기존 화면 로직 테스트 (전환 전 ViewModel)
├── {Repository·Service 이름}Tests.swift
└── Mock/Mock{Protocol}.swift         # MockWishRepository, MockNotificationManager
```

- **화면별 기능 테스트**: SwiftUI로 옮긴 화면은 `Features/{화면}/{화면}FeatureTests.swift`에 둔다. `ViewModelTestCase`를 상속하고 `viewModel.send(.action)` 뒤에 `state`·`route`·`logManager`를 단언한다. 비동기 Action은 `waitUntil { … }`.
- `Features/` 밖에 새 테스트·목 파일을 두면 `project.pbxproj`의 `seep-iosTests` 타깃에 등록해야 실행된다(동기화 폴더는 `seep-iosTests/Features`·`seep-iosTests/Log`). 추가 후 `make test` 결과의 통과 수가 늘었는지 확인한다.
- 테스트 타깃은 `@testable import seep_ios_dev`로 앱 모듈에 접근한다 (Debug 구성의 PRODUCT_NAME이 `seep-ios-dev`).
- 메서드명: **`test_GH{이슈번호}_TC{n}_{조건}_{기대결과}()`** — 한글 허용.
  - `test_GH12_TC1_위시를완료하면_예약된알림이취소된다()`
  - TC 하나를 여러 메서드로 나누면 전부 같은 접두: `test_GH12_TC2_...` 2개
  - TC와 무관한 회귀 테스트는 `test_회귀_...` 접두
- **TC 번호는 이슈 안에서 유일하다. 이슈의 `TC-n`을 그대로 쓴다.** 파일이 갈라져도 1부터 다시 시작하지 않는다.
- 이슈에 없는 케이스를 테스트로 만들고 싶으면 **이슈에 TC를 먼저 추가**하고 그 번호를 쓴다. 코드가 스펙보다 앞서가지 않는다.
- `// MARK: GH-12 TC1` 으로 묶는다.
- Given / When / Then 주석 3개를 반드시 쓴다.
- 기존 테스트(`test_finishWish_success_cancelsNotifications` 등 접두 없는 메서드)는 그대로 둔다. 손대게 되면 이 규칙으로 이름을 바꾼다.

### 실행

```bash
make test                 # scripts/run-tests.sh — 첫 번째 iPhone 시뮬레이터로 실행 + build/summary.md
scripts/run-tests.sh <UDID>
```

직접 실행할 때:
```bash
xcodebuild test \
  -project seep-ios.xcodeproj \
  -scheme seep-ios \
  -destination 'platform=iOS Simulator,id=<xcrun simctl list devices available 로 확인한 UDID>' \
  -only-testing:seep-iosTests/HomeViewModelTests
```

> ⚠️ `CODE_SIGNING_ALLOWED=NO`로 서명을 끄지 않는다. App Group 엔타이틀먼트가 빠져 `AppDelegate`의 `containerURL(...)!`이 nil이 되고 테스트 호스트가 실행 직후 크래시한다(테스트가 끝없이 대기). 팀 계정 없이 돌릴 때는 ad-hoc 서명 `CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=`을 붙인다 (`make test`는 이미 붙인다).

### CI (PR 증거)

`.github/workflows/test.yml`이 PR마다 macOS 러너에서 전체 테스트를 돌리고:
- `scripts/test-summary.sh`로 결과를 마크다운(통과/실패/스킵 수 + **실패한 테스트와 실패 메시지만**)으로 만들어 **PR 코멘트(갱신형)** 와 Job Summary에 붙인다. 통과한 테스트는 나열하지 않는다
- `tests.xcresult`를 아티팩트로 올린다(14일)
- 실패한 테스트가 있으면 체크가 빨간불

이슈 TC 대비 커버리지는 CI가 아니라 PR 본문 "TC" 표에서 본다(아래 "PR에 남기는 것"). 메서드명 `test_GH{n}_TC{n}_` 접두로 TC와 테스트를 잇기 때문에 **네이밍 규칙이 곧 증거 규칙**이다.

### ViewModel 테스트 작성법

```swift
import XCTest
import Combine

@testable import seep_ios_dev

final class HomeViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    // MARK: GH-12 TC1

    func test_GH12_TC1_위시를완료하면_예약된알림이취소된다() {
        // Given
        let repository = MockWishRepository()
        let notificationManager = MockNotificationManager()
        repository.fetchWishesResult = [wish]
        repository.finishWishResult = .success(finishedWish)
        let viewModel = HomeViewModel(dependency: .init(
            wishRepository: repository,
            preference: Preference(name: "test"),
            notificationManager: notificationManager
        ))
        viewModel.input.firstLoad.send()

        // When
        viewModel.input.didTapFinish.send(wish)

        // Then
        XCTAssertEqual(notificationManager.cancelledWishes.map(\.id), [wish.id])
    }
}
```

- **Dependency는 목으로 주입**한다 (R2). `Preference`는 `Preference(name: "test")`처럼 테스트 전용 suite로.
- **비동기 판단**: Input이 동기로 처리되면 `send` 후 바로 단언. `Task {}`·`receive(on:)`이 끼면 `expectation` + `wait(for:timeout:)`.
- **Route 검증**: `if case .presentWrite = route { expectation.fulfill() }` 패턴.
- **State 검증**: State가 private이면 Output으로 드러나는 결과로 검증한다. 접근 제어를 풀지 않는다.
- Reactor(레거시) 화면의 TC는 Reactor 테스트를 새로 쓰기보다, 그 화면을 ViewModel로 옮기는 이슈를 먼저 검토한다 (R1).

### 목(Mock) 규칙

- 위치 `seep-iosTests/Mock/Mock{Protocol}.swift`, 클래스명 `Mock{Protocol}`.
- 메서드마다 `var {메서드}Result` 스텁 프로퍼티, 호출 기록은 `private(set) var xxxCalls` / `xxxCalledIds` 배열로 스파이.
- 테스트 파일 안에 `private class Mock...`을 만들지 않는다. 공용으로 빼야 다음 테스트가 재사용한다.
- 목이 필요한데 대상이 protocol이 아니면(싱글턴 직접 호출 등) **protocol로 분리하는 것까지가 테스트 작업**이다 (`NotificationManagerProtocol` 선례).

## 2. 자동화 테스트 TC

시뮬레이터를 에이전트가 직접 조작해 TC 조건을 만들고, 스크린샷·영상으로 판정한다. 실행은 `3dollars:simulator-test` 스킬(레포의 이 문서를 읽고 동작한다) 또는 Claude에게 "시뮬레이터로 GH-12 TC-3 검증해줘".

- **테스트 코드를 만들지 않는다.** XCTest UI 테스트도 쓰지 않는다. 산출물은 코드가 아니라 증거다.
- **시나리오의 원본은 이슈 TC 한 줄이다.** 재현 단계를 레포에 따로 파일로 두지 않는다.
- **언제**: PR 올리기 전, **이번 이슈의 자동화 TC만** 돌린다.
- **판정**: 케이스마다 `PASS` / `FAIL` / `UNCLEAR` / `BLOCKED`. **UNCLEAR·BLOCKED는 통과가 아니다** — 재현 경로를 고치거나 수동 TC로 내린다.
- **증거**: 스크린샷·영상을 PR 본문 "증거" 섹션에 TC 번호와 함께 붙인다 (PR 본문에 드래그 업로드, 또는 레포의 `verification-assets` prerelease에 올려 URL로 건다. git 브랜치에 커밋하지 않는다).

## 3. 수동 테스트 TC

시뮬레이터로 **상황 자체를 만들 수 없는 것만** 남는다 (실제 알림 수신 시각, 외부 앱 공유, 실기기 위젯 갱신).
PR 본문에 체크박스로 넣고 **작성자가 올리기 전에 체크**한다. 미체크 항목이 있으면 머지하지 않는다.

## PR에 남기는 것

PR 본문 `## TC` 섹션 맨 위에 **커버리지 표**를 넣는다. 사람은 이 표만 본다.
표는 세션 기억이 아니라 매번 **이슈 TC 목록 + 레포의 `test_GH{n}_TC{n}_` 메서드 + 자동화 판정**으로 다시 만든다.

```markdown
커버리지 3/4 · ⚠️ 미커버 TC-4

| TC | 내용 | 계층 | 테스트 / 증거 | 결과 |
|---|---|---|---|---|
| TC-1 | 완료 시 알림 취소 | 유닛 | `test_GH12_TC1_위시를완료하면_예약된알림이취소된다` | ✅ |
| TC-2 | 완료 실패 시 알림 유지 | 유닛 | `test_GH12_TC2_…` | ✅ |
| TC-3 | 업데이트 후 기존 위시 유지 | 자동화 | migration.mp4 | ✅ PASS |
| TC-4 | 예정 시각 알림 수신 | 수동 | 아래 체크 | ☐ |
```

- **미커버** = 유닛 테스트도, 자동화 PASS 증거도, 수동 배정도 없는 TC. 숨기지 않고 ⚠️로 보인다.
- CI 코멘트(`test.yml`)는 유닛 실행 결과의 원본이고, 본문 표는 **스펙 대비 커버 여부**의 원본이다.
