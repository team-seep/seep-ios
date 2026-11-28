---
name: seep-run-approved
description: seep(싶)에서 사람이 승인(approved 라벨)한 기획 이슈를 하나 골라 테크스펙 구체화 → 브랜치 → 구현 → 린트·테스트 → 시뮬레이터 검증 → (필요하면) 싶 디자인 시스템 갱신 → PR(develop) → CI·TC 증거·독립 리뷰(리뷰 준비 게이트)까지 자동으로 진행하고 보드 '리뷰'에서 멈춘다. 머지는 오너 검수(개발 배포) 뒤 Seep 봇이 한다(9단계). 반영이 밀린 머지 PR이 있으면 개발 전에 디자인 시스템에 먼저 반영한다. "승인된 기획 진행해줘", "approved 이슈 처리", "GH-12 자동 개발해줘", Orca Seep 봇의 작업자 실행·매일 점검에서 사용.
---

# 승인된 기획 실행

**`approved` 라벨이 사람의 승인이다.** 이 라벨이 붙은 이슈에 한해 브랜치 생성, 커밋, push, PR 생성, 그리고 **6단계 리뷰 준비 게이트**(CI·TC 증거·독립 리뷰)까지 사용자 확인 없이 진행하고 보드 '리뷰'에서 멈춘다. **작업자는 머지하지 않는다.** 머지는 오너가 개발 빌드로 검수한 뒤 Seep 봇이 한다(9단계). 사람이 정하는 지점은 승인(라벨), 검수(개발 배포·피드백·검수 끝), 출시(심사 요청)다.
한 번 실행에 이슈 **1개**만 처리한다. 프로세스 전체는 `docs/process/planning.md`, 개발 절차는 `docs/process/pr-process.md`.

**실행 경로** — 보통 Orca **Seep 봇**(싶 1인 창업자 봇)이 시작한다(`docs/process/planning.md` 3절):
- 이슈에 `approved` 라벨이 붙으면(또는 앞 작업자가 '리뷰'·보류로 끝나면) 봇이 이 스킬을 따르는 작업자를 새 Orca 워크트리에 띄운다. 프롬프트에 이슈 번호가 있다.
- 매일 14:00 봇이 놓친 승인 이슈·밀린 디자인 시스템 반영을 훑어 같은 방식으로 띄운다.
- 사람이 직접 "승인된 기획 진행해줘"라고 해도 된다.

**Project 상태** — 단계마다 조직 프로젝트 "싶 로드맵"(team-seep #2)의 Status를 바꾼다:
```bash
set_status() { # $1 이슈 번호, $2 옵션 id
  local item
  item=$(gh project item-list 2 --owner team-seep --format json --limit 1000 \
    --jq ".items[] | select(.content.number==$1 and .content.repository==\"team-seep/seep-ios\") | .id")
  [ -z "$item" ] && item=$(gh project item-add 2 --owner team-seep --url "https://github.com/team-seep/seep-ios/issues/$1" --format json --jq .id)
  gh project item-edit --project-id PVT_kwDOBliDVc4Bs4GA --id "$item" \
    --field-id PVTSSF_lADOBliDVc4Bs4GAzhrEIZM --single-select-option-id "$2" >/dev/null
}
# 기획 ae94312a · 승인 2c84df42 · 개발 중 ec4b6332 · 리뷰 0effc9cc · 출시 대기 dc03b5cb · 출시됨 31931633 · 보류 5de0aa54
```
상태 변경이 실패해도(권한·네트워크) 개발은 멈추지 않는다. 최종 보고에 적는다.

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

- 프롬프트에 이슈 번호가 있으면 그 이슈다. `approved` 라벨이 있고 열려 있는지 다시 확인하고, 아니면 이유 한 줄로 끝낸다.
- 번호가 없으면 가장 오래된 승인 이슈를 고른다:
```bash
gh issue list -R team-seep/seep-ios --label approved --state open --json number,title,labels,createdAt \
  --jq '[.[] | select([.labels[].name] | (index("in-progress") or index("needs-input")) | not)] | sort_by(.createdAt) | .[0]'
```
- 없으면 "처리할 승인 기획 없음"으로 끝낸다 (0단계 결과는 보고한다).
- **동시에 하나만**: 다른 이슈에 `in-progress`가 있으면 시작하지 않는다(`in-progress`는 '리뷰'에 도달하거나 보류될 때까지 붙어 있다 — 개발 중인 것만 하나). 고른 이슈에 "⏳ #{진행 중} 끝나면 이어서 진행해요" 코멘트를 (이미 없을 때만) 남기고 `set_status {n} 2c84df42`(승인)로 둔 뒤 끝낸다. 앞 작업자가 끝나면 봇이 다음 이슈를 띄운다.
- 시작하면 `in-progress` 라벨을 달고 "🤖 개발 시작" 코멘트를 남기고 `set_status {n} ec4b6332`(개발 중).

## 2. 테크스펙 구체화

- `gh issue view {n} --comments`로 본문과 **사람 코멘트(조정 요청)** 를 읽는다. 코멘트가 본문보다 우선한다.
- 이슈 본문을 테크스펙 형식(`docs/process/tech-spec-process.md`)으로 다듬는다: 요구사항 확정, TC를 Given/When/Then으로 구체화, 범위 밖 명시. TC 번호는 기획안의 번호를 유지하고 필요하면 뒤에 추가한다.
- TC마다 계층(유닛/자동화/수동)을 배정한다 (`docs/process/testing.md`).
- **트래킹 이벤트를 TC로 넣는다**: "TC-n: {동작}하면 {event} 로그가 1건 전송된다" (유닛).
- `gh issue edit {n} --body-file`로 갱신한다.
- 새로 저장하는 데이터의 서버 저장 설계(`docs/architecture/server-sync-design.md` §4.1)가 빠졌거나 모호해 구현을 결정할 수 없으면 **여기서 멈춘다**: 질문을 코멘트로 남기고 `in-progress`를 떼고 `needs-input` 라벨을 단다.

## 3. 구현

사용자의 checkout(`~/Documents/Github/seep-ios`)은 건드리지 않는다.
- **Orca 작업자로 실행됐으면** 이미 전용 워크트리 안이다. 그 자리에서 브랜치를 만든다:
  ```bash
  git fetch -q origin && git switch -c feature/GH-{n}-{영문-slug} origin/develop
  ```
- 그 밖(사람이 직접 실행 등)이면 전용 worktree를 만든다:
  ```bash
  git fetch -q origin
  WT=~/Documents/Github/seep-ios-worktrees/GH-{n}
  git worktree add -b feature/GH-{n}-{영문-slug} "$WT" origin/develop
  cd "$WT"
  ```
이후 모든 명령은 그 워크트리에서 실행한다. 머지 전까지 워크트리는 그대로 둔다(CI·리뷰 수정 때 재사용).
- 이슈의 **"디자인" 섹션이 UI 기준**이다. Design 링크를 Artifact `read`로 열어 After 아트보드를 확인하고, 싶 디자인 시스템(`https://claude.ai/artifact/Mhev8UMsdUZ6yEhfXfndUQ`)의 토큰·컴포넌트 README에 적힌 원본 Swift 컴포넌트(`DdayLabel`, `HomeWishListCell` 등)를 재사용한다. "새 토큰"이 있으면 `UIColorExtension`/`UIFontExtension`에 먼저 추가한다.
- `CLAUDE.md`의 규칙(R1~R9)을 지킨다: `@Observable` ViewModel, Repository로만 DB 접근, 토큰·SwiftGen.
- DB 레코드를 바꾸면 R4: `AppDatabase.migrator`에 새 마이그레이션을 추가하고 동기화 대비 규칙(UUID PK·`updatedAt`·`deletedAt`·UNIQUE 금지)을 지킨다.
- **트래킹 이벤트**: `seep-ios/log/`의 `LogObjectId`·`ScreenName`·`EventName`에 케이스를 추가하고, ViewModel에서 `dependency.logManager.sendEvent(event: ClickEvent(...))`로 보낸다. 형식은 기존 `HomeViewModel.sendClickLog` 참고.
- 새 파일은 동기화 폴더(CLAUDE.md 목록) 안이면 넣기만 하고, 그 밖이면 `make project`로 프로젝트를 다시 만든다. `project.pbxproj`는 직접 고치지 않는다(R10). 위젯과 같이 쓰는 파일은 `project.yml`의 `widgetExtension` sources에 더한다.
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
- PR 본문 맨 끝에 `🤖 seep-run-approved 자동 개발` 한 줄을 둔다.
- 4단계에서 Draft로 올렸으면 6단계를 건너뛰고 7단계 "보류"로 간다.

## 6. 리뷰 준비 게이트

PR을 **오너가 검수할 수 있는 상태**까지 책임진다. 아래를 순서대로 전부 통과하면 '리뷰'로 넘긴다. **머지하지 않는다.**

1. **CI**: `gh pr checks {pr} -R team-seep/seep-ios --watch`. 실패하면 PR의 실패 테스트 코멘트(이름·`파일:줄`·메시지)와 로그(`gh run view --log-failed`)를 보고 고쳐 push한다 — 고치면 "✅ 다시 통과" 코멘트가 달린다. 모두 통과하면 코멘트는 없고 체크 초록이 증거다. 세 번 고쳐도 실패하면 보류.
2. **TC 증거**: PR 본문 커버리지 표에 `⚠️ 미커버`·`FAIL`이 없고, 유닛 TC는 `make test` 결과로, 자동화 TC는 스크린샷·영상으로 덮였다. 수동 TC는 이슈에 "🧪 검수 때 확인" 체크리스트 코멘트로 옮긴다 — 오너가 개발 빌드로 확인한다.
3. **독립 리뷰**: 구현 맥락이 없는 새 에이전트에게 리뷰를 맡긴다 — `code-review` 스킬을 `medium`으로 이 PR 번호에 실행한다(또는 Agent 도구로 diff와 이슈 TC만 주고 "정확성 버그·이슈 요구사항 누락·CLAUDE.md 규칙 위반"을 찾게 한다). `important` 지적은 고쳐서 push하고 1번부터 다시. 두 바퀴를 돌아도 `important`가 남으면 보류. 받아들이지 않은 지적은 PR 코멘트에 이유를 남긴다.
4. **충돌 없음**: `gh pr view {pr} --json mergeable`이 `MERGEABLE`. 아니면 `origin/develop`을 머지해 충돌을 풀고 1번부터 다시.

전부 통과하면:
- 위험도가 풀코스(`schema-change`·`baseline-change`·`verification-change` 라벨 등)면 PR 코멘트로 "검수 때 먼저 볼 파일: …"을 남긴다(보류는 아니다).
- 이슈에서 `in-progress`를 떼고 `set_status {n} 0effc9cc`(리뷰).
- 이슈 코멘트: "👀 PR #{pr} 리뷰 준비 완료 — 개발 배포로 검수해 주세요. 🧪 검수 때 확인: …"
- 워크트리는 그대로 둔다(검수 피드백 수정 때 재사용).

## 7. 보류 (게이트를 못 넘었을 때)

- PR에 "🙋 리뷰 준비 보류 — {걸린 게이트}: {이유}" 코멘트를 남긴다. Status는 '개발 중'으로 둔다.
- 이슈에서 `in-progress`를 떼고 `needs-input`을 단다(다음 이슈가 막히지 않게, 그리고 매일 점검이 이 이슈를 다시 고르지 않게). 오너가 방향을 코멘트하고 `needs-input`을 떼면 다음 실행이 이어서 한다.
- Orca 작업자로 실행됐으면 보고에 "결정 필요"로 적는다(봇이 항목을 Needs you로 둔다).

## 8. 결과

마지막 메시지: 디자인 시스템 반영 결과(이번 PR에서 반영한 것 + 0단계에서 반영한 밀린 PR, 실패 시 이유 — 없으면 "반영할 것 없음"), 이슈 번호, PR 링크, 결과(리뷰 준비 완료 / 보류 + 걸린 게이트), 테스트 결과 한 줄, 검수 때 확인할 수동 TC.

## 9. 검수 후 머지 (Seep 봇, 오너가 "검수 끝"이라고 할 때)

작업자 단계가 아니다. 오너가 개발 빌드로 검수를 마친 PR만 Seep 봇이 머지한다(`docs/process/planning.md` 3-1절).
- 검수 피드백은 같은 PR(같은 워크트리)에서 고치고 6단계 1·2·4를 다시 통과시킨다.
- 머지: `gh pr merge {pr} -R team-seep/seep-ios --merge --delete-branch`. `Closes #n`은 기본 브랜치(main)가 아니라서 이슈를 닫지 않는다 — 이슈는 출시 때 닫는다.
- 다음 릴리즈 마일스톤(열린 것 중 버전이 가장 낮은 것)을 이슈·PR에 붙이고 `set_status {n} dc03b5cb`(출시 대기):
  ```bash
  MS=$(gh api 'repos/team-seep/seep-ios/milestones?state=open' --jq 'sort_by(.title | ltrimstr("v") | split(".") | map(tonumber)) | .[0].title')
  gh issue edit {n} -R team-seep/seep-ios --milestone "$MS"
  ```
  열린 마일스톤이 없으면 마지막 태그의 minor를 올린 `vX.(Y+1).0`을 만든다.
- 직접 만든 worktree면 `git worktree remove`로 정리한다.
