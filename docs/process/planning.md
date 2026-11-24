# 기획 프로세스 (AI 추천 → 승인 → 자동 개발 → 사용량 확인)

seep은 사이드 프로젝트라 기획은 가볍게 둔다. **AI가 기획안을 추천하고, 사람은 승인·검수·출시 시점만 정한다.** 승인한 기획은 기존 개발 프로세스(`docs/process/pr-process.md`)를 자동으로 타고 리뷰 준비까지 가며, 사람이 개발 빌드로 검수하면 develop에 머지되고, 출시 후에는 쓰는지만 확인한다.

```
[seep-idea-scout]  매일 1개 ──▶ Issue (idea, src:*, size:*)
                                   │
                    사람: approved 라벨 / 코멘트로 조정 / 사유 남기고 닫기(반려)
                                   │
[Orca Seep 봇] approved 라벨 즉시 / 매일 14:00 점검
        └▶ 작업자(seep-run-approved) ──▶ (밀린 design-system-update PR → 디자인 시스템 반영) → 테크스펙 구체화
             → 브랜치 → 구현 → lint·test·simulator-test → PR → 리뷰 준비 게이트(CI·TC 증거·독립 리뷰) → 보드 '리뷰'
                                   │                         (못 넘으면 needs-input, 사람이 확인)
                    사람: "개발 배포해줘" → Seep: '리뷰' PR들을 temp 브랜치로 합쳐 개발앱 배포
                    사람: 검수 피드백 → Seep: 각 PR 수정 / "검수 끝" → Seep: develop 머지·마일스톤·출시 대기
                    사람: "출시하자" → Seep: release 브랜치·버전·심사 요청
                    App Store 출시 → Seep: 출시됨·finish(vX.Y.Z)·GitHub 릴리즈
                                   │
[seep-usage-report] 매주 ──▶ 출시 2주 뒤 GA 사용량을 이슈에 코멘트 (tracked)
```

## 1. 기획 추천 (`.claude/skills/seep-idea-scout`)

- **주기**: 매일 1개 (로컬 스케줄, 오전 10시).
- **방식** (회차마다 순환):
  | 라벨 | 방식 |
  |---|---|
  | `src:competitor` | 경쟁 앱(위시리스트·버킷리스트·D-day·목표 앱) 분석 → seep에 없는 기능 |
  | `src:fusion` | 접점 없는 분야(게임·피트니스·가계부·여행·수집 등)의 메커니즘을 위시에 융합 |
  | `src:research` | 커뮤니티·리뷰·트렌드 글 여러 곳을 조사해 공통 니즈로 기획 |
- **서버리스 조건**: 로컬 DB(GRDB)·App Group·WidgetKit·App Intents·로컬 알림·기기 내 프레임워크·CloudKit(본인 iCloud)·Firebase Remote Config/Analytics만으로 되는 기획만. Firebase Auth·Firestore·Storage를 통한 **로그인 사용자의 내 데이터 동기화**는 허용(GH-93). 비회원에서도 기능이 동작해야 한다(로그인이 필요한 부분은 비회원에게 안내만). 자체 서버, 원격 푸시, 공개·소셜(남의 위시 보기), 서버가 필요한 외부 API는 제외.
- **중복 방지**: 이미 있는 기능, 기존 기획(열림·닫힘 전부)과 겹치면 버린다. **반려 사유는 다음 추천의 제약이 된다.**
- **크기**: `size:S`(화면 하나) / `size:M`(여러 화면 또는 DB 레코드 변경) / `size:L`(새 프레임워크·타깃). S·M 우선.

## 1-1. 디자인 제안

기획안마다 핵심 화면 1~3장을 **현재 앱과 같은 테마**로 그린다.

- 기준: **싶 디자인 시스템** (Claude Design System 아티팩트, 비공개) — https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ
  - 코드에서 뽑은 토큰(색 22 · 타이포 10 · 간격 8 · 라운드 6 · 그림자 1), 컴포넌트 10개(뱃지·카테고리 탭·위시 셀·CTA·필터 바·입력·토스트 등, 원본 Swift 경로 포함), 아이콘·로고·일러스트, 현재 화면 스크린샷 4장
  - 규칙: 402×874pt, 토큰·컴포넌트만, UIKit으로 구현 가능한 것만, 새 토큰은 이유와 함께 따로 표시
- 산출물: **Design 아티팩트**(Before/After 아트보드, 편집·코멘트 가능) + 이슈 본문 **미리보기 PNG**(레포 `design-previews` prerelease에 업로드, 브랜치에 커밋하지 않음)
- 승인 후 자동 개발은 이 디자인을 UI 기준으로 삼고, PR에서 디자인 미리보기와 실제 After 스크린샷을 나란히 비교한다.
- 디자인 시스템 갱신: 색·폰트·공용 컴포넌트·아이콘·화면 규칙을 바꾸는 개발은 **그 PR 안에서 디자인 시스템도 같이 갱신**하고 `design-system-synced` 라벨을 단다. 그때 반영하지 못했으면 `design-system-update` 라벨을 남기고, 머지 후 다음 `seep-run-approved` 실행이 **개발보다 먼저** 반영한다. 바로 맞추고 싶으면 "싶 디자인 시스템 코드랑 다시 맞춰줘".

## 2. 승인

| 하고 싶은 것 | 방법 |
|---|---|
| 승인 | 이슈에 `approved` 라벨 (보드에서 카드를 열어 오른쪽 패널 Labels에서 붙여도 된다 → 보드 '승인' 칼럼으로 이동) |
| 조정 후 승인 | 코멘트로 조정 내용("TC-2는 빼줘", "위젯 말고 앱 안에서만") → `approved` 라벨. 코멘트가 본문보다 우선한다 |
| 반려 | 사유 한 줄 코멘트 후 닫기 |
| 보류 | 그냥 둔다 (열린 `idea`는 다음 추천의 중복 판단에만 쓰인다) |

`approved` 라벨이 **자동 개발(브랜치·커밋·push·PR·리뷰 준비)의 승인**이다. 라벨을 붙이는 순간 개발이 시작된다(Orca Seep 봇). develop 머지는 사람이 개발 빌드로 검수한 뒤다(3-1절).

## 3. 자동 개발 (`.claude/skills/seep-run-approved`)

- **시작**: Orca **Seep 봇**(싶 1인 창업자 봇)(이 Mac에서 실행, Orca가 켜져 있어야 함)의 자동화 두 개가 작업자를 새 Orca 워크트리에 띄운다.
  | 자동화 | 언제 | 하는 일 |
  |---|---|---|
  | 싶 approved → 개발 작업자 | `approved` 라벨이 붙을 때 | 개발 중인 이슈가 없으면 그 이슈로 작업자 시작, 있으면 '승인'에서 대기 |
  | 싶 자동 개발 매일 점검 | 매일 14:00 | Mac이 꺼져 있던 동안 놓친 승인 이슈, 밀린 `design-system-update` 반영을 같은 방식으로 시작 |
- **개발 중인 것은 하나만**: 다른 이슈에 `in-progress`가 있으면 기다린다("⏳" 코멘트, 보드 '승인'). 앞 작업자가 '리뷰'·보류로 끝나면 Seep이 다음 이슈를 띄운다. '리뷰' PR은 여러 개 쌓일 수 있다(개발 배포 때 함께 검수).
- 진행 라벨: `in-progress`(개발 중, '리뷰' 도달·보류까지) → 해제. 결정할 수 없거나 게이트에서 보류되면 코멘트 + `needs-input`(답하고 라벨을 떼면 다음 점검에 재개).
- **리뷰 준비 게이트**(스킬 6단계): CI 초록 → TC 증거(⚠️·FAIL 없음) → 구현과 별개인 에이전트의 리뷰에서 `important` 없음 → 충돌 없음. 통과하면 보드 '리뷰'. **작업자는 머지하지 않는다.** 수동 TC는 이슈의 "🧪 검수 때 확인" 목록으로 옮긴다.

## 3-1. 검수 · 머지 · 출시 (사람이 시점을 정하고 Seep이 실행)

| 사람이 Seep에게 | Seep이 하는 일 | 보드 |
|---|---|---|
| "개발 배포해줘" | '리뷰' PR들을 `temp/` 통합 브랜치로 합쳐 Xcode Cloud "개발앱 배포"로 TestFlight 배포. 이슈별 "🧪 검수 때 확인"을 모아 보여준다 | 리뷰 |
| 검수 피드백 | 해당 PR(같은 워크트리)에서 고치고 CI·TC 증거를 다시 통과시킨다. 필요하면 다시 개발 배포 | 리뷰 |
| "검수 끝"·"검수 완료" (PR 지정 또는 전부) | develop 머지(`--merge`), 다음 릴리즈 마일스톤 지정 (스킬 9단계) | 출시 대기 |
| "출시하자" | 마일스톤의 '출시 대기' 이슈로 release 브랜치·버전 → 앱스토어 빌드 → 심사 요청 | 출시 대기 |
| (App Store 출시) | 출시 확인 → 포함 이슈 닫기, git-flow finish(main·태그·develop), GitHub 릴리즈, 마일스톤 닫고 다음 마일스톤 열기. 출시 신호는 ASC 웹훅으로 받을 예정(연결 전에는 오너가 "출시됐어") | 출시됨 |

풀코스 PR(`schema-change`·`baseline-change`·`verification-change`)은 검수 때 라벨이 가리키는 파일부터 본다(작업자가 PR 코멘트로 짚어 둔다).
- 구현 중 디자인 시스템에 영향이 있으면 PR 전에 디자인 시스템도 갱신한다(스킬 4-1단계). 개발 전에는 반영이 밀린 `design-system-update` PR을 먼저 반영한다(실패해도 개발은 진행, 라벨을 남겨 다음 실행에 재시도).
- 절차는 기존과 같다: 테크스펙(TC) 구체화 → 규칙 R1~R9 안에서 구현 → `make lint` → `make test` → `simulator-test` → PR(`Closes #n`).

## 4. 트래킹 이벤트

기획마다 "기능을 실제로 쓰는가"를 볼 이벤트를 **필요한 만큼**(보통 1~3개) 정한다. 형식은 가슴속 3천원 iOS Log 모듈과 같다 (`seep-ios/log/`).

| 종류 | 코드 | GA 이벤트 | 파라미터 |
|---|---|---|---|
| 클릭 | `ClickEvent(screen: .home, objectType: .button, objectId: .write)` | `click` | `screen`, `object_type`, `object_id` (+추가 파라미터) |
| 노출 | `ImpressionEvent(screen:, objectType:, objectId:)` | `impression` | 동일 |
| 그 외 | `CustomEvent(screen:, name: .xxx)` | `EventName` 값 | `screen` (+추가) |
| 페이지뷰 | `BaseViewController.screenName` override | `screen_view` | `screen_name`, `screen_class` |

- ViewModel의 `Dependency.logManager: LogManagerProtocol`로 보낸다 (R2). 테스트는 `seep-iosTests/Log/MockLogManager.swift`로 `sentEvents`를 단언한다.
- 새 값은 snake_case로 `LogObjectId` / `ScreenName` / `EventName` / `ParameterName`에 추가한다.
- 트래킹 이벤트는 TC로도 넣는다: "TC-n: {동작}하면 `click`(object_id=`xxx`) 로그가 1건 전송된다" (유닛).
- Debug 빌드는 Dev Firebase 프로젝트로 가므로 운영 수치에 섞이지 않는다.

## 5. 사용량 확인 (`.claude/skills/seep-usage-report`)

- **주기**: 매주 월요일. 이슈가 닫혔고(PR 머지), 그 커밋이 들어간 **첫 릴리즈 태그**가 2주 지난 기획을 찾는다.
- GA(Prod 속성)에서 트래킹 이벤트별 횟수·사용자 수와 같은 기간 활성 사용자 수를 조회해 이슈에 코멘트하고 `tracked` 라벨을 단다.
- 해석·권고는 하지 않는다. 개선·제거 판단은 사람이 하고, 필요하면 새 기획 이슈로 이어진다.
- GA에서 `object_id`·`screen`으로 거르려면 Firebase 콘솔에서 **맞춤 측정기준**(이벤트 범위)으로 등록해야 한다 (최초 1회).

## 라벨

| 라벨 | 의미 |
|---|---|
| `idea` | AI가 추천한 기획안 |
| `src:competitor` / `src:fusion` / `src:research` | 추천 방식 |
| `size:S` / `size:M` / `size:L` | 크기 |
| `approved` | 사람 승인 → 자동 개발 대상 (붙이는 즉시 시작) |
| `in-progress` | 자동 개발 진행 중 ('리뷰' 도달 또는 보류까지) |
| `needs-input` | 자동 개발이 사람 답을 기다림 (질문, 또는 리뷰 준비 게이트 보류) |
| `tracked` | 출시 후 사용량 리포트 완료 |
| `design-system-update` | (PR) 디자인 시스템 반영이 필요한데 PR에서 못 함 — 머지 후 다음 실행이 반영 |
| `design-system-synced` | (PR) 디자인 시스템 반영 완료 (PR 안에서 또는 머지 후) |

## 기록: Project · 마일스톤

- 조직 프로젝트 **"싶 로드맵"**(https://github.com/orgs/team-seep/projects/2): Status 기획 → 승인 → 개발 중 → 리뷰 → 출시 대기 → 출시됨(+보류). 보드 뷰(Status), 릴리즈 뷰(마일스톤별).
  - 자동(Project 워크플로): 새 이슈 → 추가·기획, PR 연결 → 리뷰, 이슈 닫힘 → 출시됨.
  - Seep 봇·스킬이 바꾸는 것: `approved` 라벨 → 승인(대기 포함), 개발 중, 리뷰, 출시 대기(검수 후 머지).
- 릴리즈는 레포 **마일스톤**(`v2.10.0` …)으로 묶는다. 검수 후 머지 때 Seep이 다음 마일스톤을 붙인다. 출시 흐름은 3-1절.

## 스케줄

| 작업 | 어디서 | 주기 |
|---|---|---|
| `seep-idea-scout` | Orca Seep 봇 | 매일 10:00 |
| `seep-run-approved` | Orca Seep 봇 (위 3절) | `approved` 라벨 즉시 + 매일 14:00 점검 |
| `seep-usage-report` | Orca Seep 봇 | 매주 월 11:00 |

Orca(이 Mac)가 켜져 있을 때 실행되고, 꺼져 있었으면 다음 점검 때 돈다. 수동 실행: Claude에게 "기획 추천해줘" / "승인된 기획 진행해줘" / "기획 사용량 확인해줘".
