# 검증 장치 변경 감지

린트·테스트·CI·규칙 문서는 PR을 검증하는 **장치**다. 장치 자체를 바꾸는 PR은 린트·테스트가 초록불이어도 그 결과를 그대로 믿을 수 없다.
그래서 **경로만 보고 결정론적으로** 라벨을 붙이고, 바뀐 장치 파일 목록을 코멘트로 남긴다. AI 판단은 개입하지 않는다.

## 라벨 (`.github/labeler.yml`, `actions/labeler`)

| 라벨 | 붙는 조건 (경로) | 리뷰어가 볼 것 |
|---|---|---|
| `verification-change` | `.github/**`, `.swiftlint.yml`, 베이스라인, `scripts/**`, `makefile`, `seep-iosTests/**`, `docs/architecture/RULES.md`, `CLAUDE.md`, `.claude/skills/**`(자동화 스킬) | 코드보다 **이 파일들을 먼저** 본다. 왜 바꿨는지가 본문 "설명이 필요한 결정"에 있어야 한다 |
| `baseline-change` | `.swiftlint-baseline.json` | 베이스라인은 **줄어들기만** 해야 한다. 항목이 늘었으면 사유 확인 (RULES.md "베이스라인 운영") |
| `schema-change` | `seep-ios/model/dto/**`, `seep-ios/Repository/AppDatabase.swift`, `seep-ios/Repository/LegacyRealm/**` | R4. `AppDatabase.migrator`에 새 마이그레이션이 있는지(배포된 것은 그대로인지), 동기화 대비 규칙(UUID PK·`updatedAt`·`deletedAt`·UNIQUE 금지)을 지켰는지, 마이그레이션 TC가 있는지 |

라벨은 **표시**일 뿐 검증을 실행하지 않는다. 린트·테스트(`lint.yml`, `test.yml`)는 라벨과 무관하게 모든 PR에서 돈다.

## 코멘트 (`.github/workflows/labeler.yml`)

`verification-change`가 붙으면 바뀐 장치 파일 목록을 PR 코멘트 하나에 갱신형으로 남긴다. 목(`seep-iosTests/Mock/*.swift`)은 목록에서 뺀다 (라벨은 그대로 붙는다).

## 경로 목록을 바꿀 때

- `.github/labeler.yml`과 `labeler.yml` 워크플로의 grep 패턴을 **같이** 바꾼다.
- 새 검증 장치(새 워크플로, 새 스크립트)를 추가하면 그 경로도 추가한다.
- 라벨은 레포에 미리 만들어져 있어야 한다 (`gh label create`). `actions/labeler`는 없는 라벨을 만들지 않는다.
