# PR 프로세스 (한 장 요약)

AI가 코드를 많이 쓰는 환경에서 사람 리뷰어는 **diff 전체가 아니라 의도(TC) · 경계 · 검증 증거**만 본다.
나머지(스타일, 구조 규칙, 회귀)는 린트·스크립트·테스트·AI가 맡는다. 이 문서는 전체 흐름과 도구, PR 위험도별 요구 수준을 정한다.

## 흐름과 도구

| 단계 | 하는 일 | 도구 / Claude에게 | 산출물이 가는 곳 |
|---|---|---|---|
| 1. 의도 정의 | 이슈에 요약·요구사항·TC 작성 | `.github/ISSUE_TEMPLATE/feature.yml` · "GH-12 테크스펙 써줘" | GitHub Issue 본문 (단일 진실 소스) |
| 2. 브랜치 | git-flow, develop 기반 | `feature/GH-12-{설명}` / `bugfix/GH-12-…` / `hotfix/…` | — |
| 3. 코드 작성 | 규칙 9개(R1~R9) 안에서 구현 | `docs/architecture/RULES.md`, `CLAUDE.md`, `make lint` | 로컬 + `lint.yml` |
| 4. 테스트 | TC를 세 계층(유닛/자동화/수동)에 배정 → 승인 → 유닛만 코드 | "GH-12 테스트 케이스 도출해줘", `docs/process/testing.md`, `make test` | `seep-iosTests/`, 메서드명 `test_GH12_TC{n}_` |
| 5. 동작 증거 | TC 커버리지 표(본문) / 유닛 실행 결과·실패 목록(CI 코멘트) / 자동화 TC 스크린샷·영상 | `test.yml` + `scripts/test-summary.sh`, `3dollars:simulator-test` | PR 코멘트(자동), 본문 "TC"·"증거" |
| 6. 스코프 드리프트 | 이슈 요구사항 ↔ diff 대조, 스펙 밖 변경 목록 | "GH-12 드리프트 확인해줘" | 본문 "스펙 밖 변경" |
| 7. 자동화·수동 범위 | 유닛으로 안 덮이는 TC를 자동화/수동으로 가르고 UI 공통·영역 체크 추가 | `docs/process/e2e-and-manual-tests.md` | 본문 "TC" 체크리스트 |
| 8. 검증 장치 변경 | 린트·CI·규칙·스키마 파일을 건드린 PR 표시 | `.github/labeler.yml` + `labeler.yml`, `docs/process/verification-change.md` | 라벨 + 파일 목록 코멘트 |
| 9. 설명이 필요한 결정 | diff에서 비자명한 결정 최대 3개를 작성자에게 질문 | "PR 올리기 전에 설명 필요한 결정 물어봐줘" | 본문 "설명이 필요한 결정" |
| PR 생성 | 위 결과를 템플릿에 채워 생성 | "PR 만들어줘" → `.github/PULL_REQUEST_TEMPLATE.md` 형식으로 `gh pr create --base develop` | GitHub PR |
| 리뷰 | 의도·경계·증거 기준 리뷰 | `/code-review` + 사람 | PR 코멘트 |

작성자 기준 순서: **이슈(TC) → 브랜치 → 구현 → 테스트 도출·작성 → `make lint` → `make test` → (UI면) simulator-test → PR**.

"PR 만들어줘"라고 하면 Claude는 6·7·9단계를 안에서 수행해 본문을 채운다:
1. 브랜치명에서 이슈 번호 추출 → `gh issue view {n}`로 요구사항·TC 읽기
2. `git diff develop...HEAD`로 요구사항별 구현 여부와 스펙 밖 변경 정리 (드리프트)
3. 레포의 `test_GH{n}_TC{m}_` 메서드 + 자동화 판정으로 커버리지 표 작성 (미커버는 ⚠️)
4. UI 파일·영역 트리거에 맞춰 체크리스트 삽입
5. 비자명한 결정을 작성자에게 묻고 Q/A 기록
6. 아래 위험도 기준으로 판정 → **본문을 보여주고 확인받은 뒤** `gh pr create`

## 위험도: 경량 / 풀코스

PR 본문 첫 줄 `위험도:`에 적는다. 작성자가 바꿀 수 있다(바꾸면 사유 한 줄).

| | 경량 | 풀코스 |
|---|---|---|
| **조건** | 아래 전부: 문서/테스트/CI만 바뀜 **또는** 한 화면(feature 디렉터리 하나) 안의 UI·로직 변경, Repository·Realm 모델·위젯·AppDelegate/SceneDelegate 미변경, 베이스라인 미변경 | 하나라도: `schema-change`·`baseline-change` 라벨, Repository·`model/` 변경, 위젯, 딥링크·알림·App Group, 2개 이상 feature 디렉터리 동시 변경, 의존성(SPM) 변경 |
| **자동 검증** | `lint.yml`, `test.yml` | 동일 |
| **본문 필수** | 의도 링크, 변경 불릿, TC 커버리지 표 + 수동·공통 체크(해당 시) | + 드리프트 요구사항 표 **전체**, 설명이 필요한 결정 Q/A, UI 변경이면 Before/After 증거, 스키마 변경이면 마이그레이션 TC 증거 |
| **사람 리뷰** | 본문만 보고 승인 가능. 스펙 밖 변경이 "없음"이면 diff를 열 필요 없음 | 라벨이 가리키는 파일(검증 장치·DTO·마이그레이션)을 **먼저** 읽고, 그다음 드리프트 표의 "부분/없음" 항목 |
| **머지 조건** | CI 초록 + 커버리지 표에 ⚠️·FAIL 없음 + 체크리스트 전부 체크 | + 셀프 리뷰 체크(1인 개발이면 `/code-review` 결과 반영 확인) |

## 예외

- **핫픽스**(`hotfix/`): 이슈 생략 가능. 본문 "의도"에 장애 내용 1줄 + 재현 경로, 풀코스 취급.
- **릴리즈 브랜치**(`release/`): 버전·빌드 번호 변경만이면 경량.
- **의존성 업데이트**: SPM 버전 변경은 풀코스 (Realm 등 저장소 라이브러리는 마이그레이션 영향 확인).

## 규칙을 바꾸고 싶을 때

이 문서, `RULES.md`, `.swiftlint.yml`, `CLAUDE.md`는 **함께** 바뀐다. 입구는 반복 리뷰 지적(3회 이상) 또는 `verification-change` 라벨이 붙는 PR이며, 린트·CI 변경은 적용 전에 확인받는다.
