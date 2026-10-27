---
name: seep-run-approved
description: seep(싶)에서 사람이 승인(approved 라벨)한 기획 이슈를 하나 골라 테크스펙 구체화 → 브랜치 → 구현 → 린트·테스트 → 시뮬레이터 검증 → (필요하면) 싶 디자인 시스템 갱신 → PR(develop)까지 자동으로 진행한다. 반영이 밀린 머지 PR이 있으면 개발 전에 디자인 시스템에 먼저 반영한다. "승인된 기획 진행해줘", "approved 이슈 처리", 매일 스케줄 실행에서 사용.
---

# 승인된 기획 실행

**`approved` 라벨이 사람의 승인이다.** 이 라벨이 붙은 이슈에 한해 브랜치 생성, 커밋, push, PR 생성까지 사용자 확인 없이 진행한다. **머지는 하지 않는다** (머지는 사람).
한 번 실행에 이슈 **1개**만 처리한다. 프로세스 전체는 `docs/process/planning.md`, 개발 절차는 `docs/process/pr-process.md`.

## 0. 밀린 디자인 시스템 동기화 (개발보다 먼저, 예비 단계)

디자인 시스템은 원칙적으로 **개발하는 PR 안에서 바로 반영**한다(4-1단계). 이 단계는 그때 반영하지 못했거나 사람이 직접 올린 PR처럼, 머지된 PR 중 디자인 시스템 반영이 밀린 것이 있으면 **이번 실행의 개발 전에** 싶 디자인 시스템(`https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ`)에 먼저 반영한다. 다음 기획·개발이 최신 토큰·컴포넌트를 기준으로 삼게 하기 위해서다. 승인 이슈가 없는 날에도 이 단계는 수행한다.

```bash
gh pr list -R team-seep/seep-ios --state merged --label design-system-update \
  --json number,title,mergedAt --jq 'sort_by(.mergedAt)'
```
- 없으면 바로 1단계(대상 고르기)로 간다.
- 오래된 PR부터 하나씩:
  1. `gh pr diff {pr} -R team-seep/seep-ios`에서 `seep-ios/DesignSystem/**`, `seep-ios/Resources/Icons.xcassets` 변경만 본다. 코드 기준은 **origin/develop의 현재 파일**이다(머지 후 더 바뀌었을 수 있다).
  2. 디자인 시스템을 Artifact `read`로 열고, 결과가 주는 타입 지침의 "Revising" 절차대로 바뀐 것만 고친다.
     - 색·폰트 토큰 → `project/tokens.json`(통째로) + `usage`
     - 공용 컴포넌트 추가·변경 → `project/components/{Name}/README.md`(원본 Swift 경로, 크기·토큰·상태) + `preview.html`(`bundle.css`·토큰으로 그린 미리보기), 필요하면 `bundle.css`
     - 아이콘 → 에셋 업로드 + 인덱스 `assetGroups` 기록
     - 인덱스 `lastChange`: `by` 사용자 이름, `via` "seep-run-approved", `note` "PR #{pr} 반영"
  3. PR에 코멘트 "🎨 디자인 시스템 반영: {바뀐 토큰·컴포넌트·아이콘 요약}"를 남기고 `design-system-update` 라벨을 떼고 `design-system-synced` 라벨을 단다.
- 반영에 실패하면(권한·충돌·판단 불가) PR에 실패 이유를 코멘트하고 `design-system-update` 라벨은 그대로 둔다(다음 실행에 재시도). **개발은 막지 않고** 1단계로 넘어간다. 최종 보고에 실패를 적는다.

## 1. 대상 고르기

```bash
cd /Users/hyunsikyoo/Documents/Github/seep-ios
gh issue list -R team-seep/seep-ios --label approved --state open --json number,title,labels,createdAt \
  --jq '[.[] | select([.labels[].name] | index("in-progress") | not)] | sort_by(.createdAt) | .[0]'
```
- 없으면 "처리할 승인 기획 없음"으로 끝낸다 (0단계 결과는 보고한다).
- 고른 이슈에 `in-progress` 라벨을 달고 "🤖 개발 시작" 코멘트를 남긴다.

## 2. 테크스펙 구체화

- `gh issue view {n} --comments`로 본문과 **사람 코멘트(조정 요청)** 를 읽는다. 코멘트가 본문보다 우선한다.
- 이슈 본문을 테크스펙 형식(`docs/process/tech-spec-process.md`)으로 다듬는다: 요구사항 확정, TC를 Given/When/Then으로 구체화, 범위 밖 명시. TC 번호는 기획안의 번호를 유지하고 필요하면 뒤에 추가한다.
- TC마다 계층(유닛/자동화/수동)을 배정한다 (`docs/process/testing.md`).
- **트래킹 이벤트를 TC로 넣는다**: "TC-n: {동작}하면 {event} 로그가 1건 전송된다" (유닛).
- `gh issue edit {n} --body-file`로 갱신한다.
- 기획이 서버리스 조건을 못 지키거나 모호해 구현을 결정할 수 없으면 **여기서 멈춘다**: 질문을 코멘트로 남기고 `in-progress`를 떼고 `needs-input` 라벨을 단다.

## 3. 구현

사용자의 checkout(`~/Documents/Github/seep-ios`)은 건드리지 않고 **전용 worktree**에서 작업한다.
```bash
git fetch -q origin
WT=~/Documents/Github/seep-ios-worktrees/GH-{n}
git worktree add -b feature/GH-{n}-{영문-slug} "$WT" origin/develop
cd "$WT"
```
이후 모든 명령은 `$WT`에서 실행한다. PR을 올린 뒤 worktree는 그대로 둔다(리뷰 수정 때 재사용). 머지 후 정리는 `git worktree remove`.
- 이슈의 **"디자인" 섹션이 UI 기준**이다. Design 링크를 Artifact `read`로 열어 After 아트보드를 확인하고, 싶 디자인 시스템(`https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ`)의 토큰·컴포넌트 README에 적힌 원본 Swift 컴포넌트(`DdayLabel`, `HomeWishListCell` 등)를 재사용한다. "새 토큰"이 있으면 `UIColorExtension`/`UIFontExtension`에 먼저 추가한다.
- `CLAUDE.md`의 규칙(R1~R9)을 지킨다: `@Observable` ViewModel, Repository로만 DB 접근, 토큰·SwiftGen.
- DB 레코드를 바꾸면 R4: `AppDatabase.migrator`에 새 마이그레이션을 추가하고 동기화 대비 규칙(UUID PK·`updatedAt`·`deletedAt`·UNIQUE 금지)을 지킨다.
- **트래킹 이벤트**: `seep-ios/log/`의 `LogObjectId`·`ScreenName`·`EventName`에 케이스를 추가하고, ViewModel에서 `dependency.logManager.sendEvent(event: ClickEvent(...))`로 보낸다. 형식은 기존 `HomeViewModel.sendClickLog` 참고.
- 새 파일은 `project.pbxproj` 등록이 필요하다 (동기화 폴더는 `seep-ios/model/Error`, `seep-ios/log`, `seep-iosTests/Log`뿐). 가능하면 기존 동기화 폴더 안에 두거나, 등록 후 빌드 결과 수로 포함 여부를 확인한다.
- 커밋 메시지: `GH-{n} : {설명}`.

## 4. 검증

1. `make lint` 통과
2. 유닛 TC 테스트 작성(`test_GH{n}_TC{m}_…`, 목 주입) → `make test` 통과. 결과 수가 늘었는지 확인
3. 자동화 TC는 `3dollars:simulator-test`로 실행하고 스크린샷·영상을 확보한다. UI 변경이면 Before/After를 남기고, **이슈의 디자인 미리보기와 실제 After를 나란히** 둔다(차이가 있으면 이유를 PR "설명이 필요한 결정"에)
4. 실패하면 고쳐서 다시 돌린다. 세 번 시도해도 안 되면 그 상태로 PR을 Draft로 올리고 실패 내용을 본문에 적는다

## 4-1. 디자인 시스템 반영 (해당하면, PR 전에)

이번 변경이 `seep-ios/DesignSystem/**`, `seep-ios/Resources/Icons.xcassets`를 바꾸거나, 화면을 그리는 규칙(레이아웃·간격·넓은 화면 등)을 새로 정했다면 **PR을 올리기 전에** 싶 디자인 시스템(`https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ`)을 같이 갱신한다. 다음 기획·디자인이 바로 최신 기준을 쓰게 하기 위해서다.
- 방법은 0단계 2번과 같다: Artifact `read` → 타입 지침의 "Revising" 절차로 **바뀐 것만** 고친다(토큰 → `project/tokens.json`, 공용 컴포넌트 → `project/components/{Name}/README.md`·`preview.html`·`bundle.css`, 아이콘 → 에셋 업로드 + `assetGroups`, 규칙 → `project/README.md`). 인덱스 `lastChange`: `via` "seep-run-approved", `note` "GH-{n} {바뀐 것}".
- 기준은 이 브랜치의 코드다. PR이 리뷰에서 바뀌면 같은 방식으로 다시 맞춘다.
- 해당 없으면 건너뛴다(대부분의 기능 PR).

## 5. PR

- `.github/PULL_REQUEST_TEMPLATE.md`를 채워 `gh pr create -R team-seep/seep-ios --base develop`.
  - "의도": `Closes #{n}` + 한 줄 요약
  - TC 커버리지 표 (유닛 / 자동화 PASS + 증거 / 수동 ☐)
  - **트래킹 이벤트 표**: 이슈의 표와 실제 구현이 같은지
  - 스펙 밖 변경, 설명이 필요한 결정(최대 3개, 스스로 답한다)
  - 위험도는 `docs/process/pr-process.md` 기준
- 4-1단계에서 디자인 시스템을 반영했으면 PR 본문 "기타"에 "🎨 디자인 시스템 반영: {바뀐 토큰·컴포넌트·아이콘·규칙}"을 적고 **`design-system-synced` 라벨**을 단다. 반영에 실패했으면 "디자인 시스템 갱신 필요: {바뀐 것} (실패 이유)"를 적고 **`design-system-update` 라벨**을 단다 — 머지된 뒤 다음 실행의 0단계가 재시도한다.
- 이슈에서 `in-progress`를 떼고 PR 링크를 코멘트로 남긴다: "🤖 PR #{pr} — 리뷰·머지 부탁드려요. 수동 TC: …"

## 6. 결과

마지막 메시지: 디자인 시스템 반영 결과(이번 PR에서 반영한 것 + 0단계에서 반영한 밀린 PR, 실패 시 이유 — 없으면 "반영할 것 없음"), 이슈 번호, PR 링크, 테스트 결과 한 줄, 남은 수동 TC.
