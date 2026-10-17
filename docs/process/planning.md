# 기획 프로세스 (AI 추천 → 승인 → 자동 개발 → 사용량 확인)

seep은 사이드 프로젝트라 기획은 가볍게 둔다. **AI가 기획안을 추천하고, 사람은 승인만 한다.** 승인한 기획은 기존 개발 프로세스(`docs/process/pr-process.md`)를 자동으로 타고, 출시 후에는 쓰는지만 확인한다.

```
[seep-idea-scout]  매일 1개 ──▶ Issue (idea, src:*, size:*)
                                   │
                    사람: approved 라벨 / 코멘트로 조정 / 사유 남기고 닫기(반려)
                                   │
[seep-run-approved] 매일 ──▶ (머지된 design-system-update PR → 디자인 시스템 반영) → 테크스펙 구체화 → worktree 브랜치 → 구현 → lint·test·simulator-test → PR
                                   │
                    사람: 리뷰·머지 → release 태그(vX.Y.Z)
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
- **서버리스 조건**: 로컬 Realm·App Group·WidgetKit·App Intents·로컬 알림·기기 내 프레임워크·CloudKit(본인 iCloud)·Firebase Remote Config/Analytics만으로 되는 기획만. 자체 서버, 원격 푸시, 계정·소셜, 서버가 필요한 외부 API는 제외.
- **중복 방지**: 이미 있는 기능, 기존 기획(열림·닫힘 전부)과 겹치면 버린다. **반려 사유는 다음 추천의 제약이 된다.**
- **크기**: `size:S`(화면 하나) / `size:M`(여러 화면 또는 Realm 모델 변경) / `size:L`(새 프레임워크·타깃). S·M 우선.

## 1-1. 디자인 제안

기획안마다 핵심 화면 1~3장을 **현재 앱과 같은 테마**로 그린다.

- 기준: **싶 디자인 시스템** (Claude Design System 아티팩트, 비공개) — https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ
  - 코드에서 뽑은 토큰(색 22 · 타이포 10 · 간격 8 · 라운드 6 · 그림자 1), 컴포넌트 10개(뱃지·카테고리 탭·위시 셀·CTA·필터 바·입력·토스트 등, 원본 Swift 경로 포함), 아이콘·로고·일러스트, 현재 화면 스크린샷 4장
  - 규칙: 402×874pt, 토큰·컴포넌트만, UIKit으로 구현 가능한 것만, 새 토큰은 이유와 함께 따로 표시
- 산출물: **Design 아티팩트**(Before/After 아트보드, 편집·코멘트 가능) + 이슈 본문 **미리보기 PNG**(레포 `design-previews` prerelease에 업로드, 브랜치에 커밋하지 않음)
- 승인 후 자동 개발은 이 디자인을 UI 기준으로 삼고, PR에서 디자인 미리보기와 실제 After 스크린샷을 나란히 비교한다.
- 디자인 시스템 갱신: 색·폰트·공용 컴포넌트·아이콘을 바꾼 PR에는 `design-system-update` 라벨을 단다. 머지되면 다음 `seep-run-approved` 실행이 **개발보다 먼저** 디자인 시스템에 반영하고 라벨을 `design-system-synced`로 바꾼다. 바로 반영하고 싶으면 "싶 디자인 시스템 코드랑 다시 맞춰줘".

## 2. 승인

| 하고 싶은 것 | 방법 |
|---|---|
| 승인 | 이슈에 `approved` 라벨 |
| 조정 후 승인 | 코멘트로 조정 내용("TC-2는 빼줘", "위젯 말고 앱 안에서만") → `approved` 라벨. 코멘트가 본문보다 우선한다 |
| 반려 | 사유 한 줄 코멘트 후 닫기 |
| 보류 | 그냥 둔다 (열린 `idea`는 다음 추천의 중복 판단에만 쓰인다) |

`approved` 라벨이 **자동 개발(브랜치·커밋·push·PR)의 승인**이다. 머지는 사람이 한다.

## 3. 자동 개발 (`.claude/skills/seep-run-approved`)

- **주기**: 매일 1회 (오후 2시), 승인된 이슈 중 가장 오래된 것 **1개**.
- 사용자 checkout은 건드리지 않고 `~/Documents/Github/seep-ios-worktrees/GH-{n}` worktree에서 작업한다.
- 진행 라벨: `in-progress`(작업 중) → PR 생성 후 해제. 결정할 수 없으면 질문 코멘트 + `needs-input`(답하면 라벨을 떼고 `approved`가 남아 있으면 다음 실행에 재개).
- 개발 전에 머지된 `design-system-update` PR을 디자인 시스템에 먼저 반영한다(실패해도 개발은 진행, 라벨을 남겨 다음 실행에 재시도).
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
| `approved` | 사람 승인 → 자동 개발 대상 |
| `in-progress` | 자동 개발 진행 중 |
| `needs-input` | 자동 개발이 사람 답을 기다림 |
| `tracked` | 출시 후 사용량 리포트 완료 |
| `design-system-update` | (PR) 색·폰트·공용 컴포넌트·아이콘 변경 — 머지 후 디자인 시스템 반영 대기 |
| `design-system-synced` | (PR) 디자인 시스템 반영 완료 |

## 스케줄 (로컬, Claude 데스크톱 앱)

| 작업 | 주기 |
|---|---|
| `seep-idea-scout` | 매일 10:00 |
| `seep-run-approved` | 매일 14:00 |
| `seep-usage-report` | 매주 월 11:00 |

데스크톱 앱이 켜져 있을 때 실행되고, 꺼져 있었으면 다음 실행 때 돈다. 수동 실행: Claude에게 "기획 추천해줘" / "승인된 기획 진행해줘" / "기획 사용량 확인해줘".
