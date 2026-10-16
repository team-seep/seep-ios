---
name: seep-run-approved
description: seep(싶)에서 사람이 승인(approved 라벨)한 기획 이슈를 하나 골라 테크스펙 구체화 → 브랜치 → 구현 → 린트·테스트 → 시뮬레이터 검증 → PR(develop)까지 자동으로 진행한다. "승인된 기획 진행해줘", "approved 이슈 처리", 매일 스케줄 실행에서 사용.
---

# 승인된 기획 실행

**`approved` 라벨이 사람의 승인이다.** 이 라벨이 붙은 이슈에 한해 브랜치 생성, 커밋, push, PR 생성까지 사용자 확인 없이 진행한다. **머지는 하지 않는다** (머지는 사람).
한 번 실행에 이슈 **1개**만 처리한다. 프로세스 전체는 `docs/process/planning.md`, 개발 절차는 `docs/process/pr-process.md`.

## 0. 대상 고르기

```bash
cd /Users/hyunsikyoo/Documents/Github/seep-ios
gh issue list -R team-seep/seep-ios --label approved --state open --json number,title,labels,createdAt \
  --jq '[.[] | select([.labels[].name] | index("in-progress") | not)] | sort_by(.createdAt) | .[0]'
```
- 없으면 "처리할 승인 기획 없음"으로 끝낸다.
- 고른 이슈에 `in-progress` 라벨을 달고 "🤖 개발 시작" 코멘트를 남긴다.

## 1. 테크스펙 구체화

- `gh issue view {n} --comments`로 본문과 **사람 코멘트(조정 요청)** 를 읽는다. 코멘트가 본문보다 우선한다.
- 이슈 본문을 테크스펙 형식(`docs/process/tech-spec-process.md`)으로 다듬는다: 요구사항 확정, TC를 Given/When/Then으로 구체화, 범위 밖 명시. TC 번호는 기획안의 번호를 유지하고 필요하면 뒤에 추가한다.
- TC마다 계층(유닛/자동화/수동)을 배정한다 (`docs/process/testing.md`).
- **트래킹 이벤트를 TC로 넣는다**: "TC-n: {동작}하면 {event} 로그가 1건 전송된다" (유닛).
- `gh issue edit {n} --body-file`로 갱신한다.
- 기획이 서버리스 조건을 못 지키거나 모호해 구현을 결정할 수 없으면 **여기서 멈춘다**: 질문을 코멘트로 남기고 `in-progress`를 떼고 `needs-input` 라벨을 단다.

## 2. 구현

사용자의 checkout(`~/Documents/Github/seep-ios`)은 건드리지 않고 **전용 worktree**에서 작업한다.
```bash
git fetch -q origin
WT=~/Documents/Github/seep-ios-worktrees/GH-{n}
git worktree add -b feature/GH-{n}-{영문-slug} "$WT" origin/develop
cd "$WT"
```
이후 모든 명령은 `$WT`에서 실행한다. PR을 올린 뒤 worktree는 그대로 둔다(리뷰 수정 때 재사용). 머지 후 정리는 `git worktree remove`.
- 이슈의 **"디자인" 섹션이 UI 기준**이다. Design 링크를 Artifact `read`로 열어 After 아트보드를 확인하고, 싶 디자인 시스템(`https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ`)의 토큰·컴포넌트 README에 적힌 원본 Swift 컴포넌트(`DdayLabel`, `HomeWishListCell` 등)를 재사용한다. "새 토큰"이 있으면 `UIColorExtension`/`UIFontExtension`에 먼저 추가한다.
- `CLAUDE.md`의 규칙(R1~R9)을 지킨다: Combine ViewModel, Repository로만 Realm 접근, 토큰·SwiftGen, Base 클래스 상속.
- Realm 모델을 바꾸면 R4: schemaVersion을 앱과 위젯 3곳에서 모두 올리고 migrationBlock에 분기를 추가한다.
- **트래킹 이벤트**: `seep-ios/log/`의 `LogObjectId`·`ScreenName`·`EventName`에 케이스를 추가하고, ViewModel에서 `dependency.logManager.sendEvent(event: ClickEvent(...))`로 보낸다. 형식은 기존 `HomeViewModel.sendClickLog` 참고.
- 새 파일은 `project.pbxproj` 등록이 필요하다 (동기화 폴더는 `seep-ios/model/Error`, `seep-ios/log`, `seep-iosTests/Log`뿐). 가능하면 기존 동기화 폴더 안에 두거나, 등록 후 빌드 결과 수로 포함 여부를 확인한다.
- 커밋 메시지: `GH-{n} : {설명}`.

## 3. 검증

1. `make lint` 통과
2. 유닛 TC 테스트 작성(`test_GH{n}_TC{m}_…`, 목 주입) → `make test` 통과. 결과 수가 늘었는지 확인
3. 자동화 TC는 `3dollars:simulator-test`로 실행하고 스크린샷·영상을 확보한다. UI 변경이면 Before/After를 남기고, **이슈의 디자인 미리보기와 실제 After를 나란히** 둔다(차이가 있으면 이유를 PR "설명이 필요한 결정"에)
4. 실패하면 고쳐서 다시 돌린다. 세 번 시도해도 안 되면 그 상태로 PR을 Draft로 올리고 실패 내용을 본문에 적는다

## 4. PR

- `.github/PULL_REQUEST_TEMPLATE.md`를 채워 `gh pr create -R team-seep/seep-ios --base develop`.
  - "의도": `Closes #{n}` + 한 줄 요약
  - TC 커버리지 표 (유닛 / 자동화 PASS + 증거 / 수동 ☐)
  - **트래킹 이벤트 표**: 이슈의 표와 실제 구현이 같은지
  - 스펙 밖 변경, 설명이 필요한 결정(최대 3개, 스스로 답한다)
  - 위험도는 `docs/process/pr-process.md` 기준
- PR이 `seep-ios/extensions/UIColorExtension.swift`, `UIFontExtension.swift`, `seep-ios/features/shared/**`, `seep-ios/Resources/Icons.xcassets`를 바꾸면 PR 본문 "기타"에 "디자인 시스템 갱신 필요"를 적는다(머지 후 디자인 시스템 artifact를 코드에 맞춰 갱신).
- 이슈에서 `in-progress`를 떼고 PR 링크를 코멘트로 남긴다: "🤖 PR #{pr} — 리뷰·머지 부탁드려요. 수동 TC: …"

## 5. 결과

마지막 메시지: 이슈 번호, PR 링크, 테스트 결과 한 줄, 남은 수동 TC.
