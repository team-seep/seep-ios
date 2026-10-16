---
name: seep-idea-scout
description: seep(싶) 위시리스트 앱의 새 기능 기획안을 1개 조사·작성해 GitHub Issue(라벨 idea)로 올린다. 경쟁 앱 분석 / 이종 분야 융합 / 멀티소스 리서치 중 하나를 순환하며, 서버 없이(서버리스) 구현 가능한 기획만 낸다. "기획 추천해줘", "아이디어 하나 뽑아줘", "seep 기획안", 격일 스케줄 실행에서 사용.
---

# seep 기획 추천

한 번 실행에 **기획안 1개**를 만든다. 사람이 승인(`approved` 라벨)하기 전까지는 기획안일 뿐이며, 이 스킬은 코드를 건드리지 않는다.
프로세스 전체는 `docs/process/planning.md`.

## 0. 준비

```bash
cd /Users/hyunsikyoo/Documents/Github/seep-ios
git fetch -q origin
```
사용자의 작업 트리·브랜치는 건드리지 않는다(checkout 금지). 코드는 `git show origin/develop:{경로}` / `git ls-tree -r --name-only origin/develop`로 읽는다.

## 1. 이번 회차 방식 고르기 (순환)

직전 기획 이슈의 출처 라벨을 보고 다음 방식으로 넘어간다: `src:competitor` → `src:fusion` → `src:research` → 다시 `src:competitor`.

```bash
gh issue list -R team-seep/seep-ios --label idea --state all --limit 1 --json number,labels --jq '.[0].labels[].name'
```
기획 이슈가 하나도 없으면 `src:competitor`부터 시작한다.

## 2. 현재 앱 파악 (중복 방지)

- `CLAUDE.md`의 "디렉터리 구조"와 `seep-ios/features/*`를 훑어 **이미 있는 기능**을 목록으로 만든다 (카테고리 3종, D-day·알림, 해시태그·메모·이모지, 완료/완료 취소, 정렬·완료만 보기·리스트/그리드, 사진 공유, 위젯 4종 등).
- 기존 기획을 전부 읽는다. 열린 것, 승인된 것, 닫힌 것 모두. **반려 사유(닫힌 이슈의 마지막 코멘트)는 다음 추천의 제약으로 쓴다.**
  ```bash
  gh issue list -R team-seep/seep-ios --label idea --state all --limit 100 --json number,title,state,labels,comments
  ```
- 이미 있는 기능, 기존 기획과 같거나 거의 같은 아이디어는 버린다.

## 3. 방식별 조사

웹 검색과 페이지 읽기로 조사한다. 출처 링크를 2개 이상 남긴다.

### src:competitor — 경쟁 앱 분석
- 대상: 위시리스트·버킷리스트·D-day·할 일·목표 앱 (국내외 앱스토어 상위권). 매 회차 다른 앱 1~2개를 고른다.
- 앱스토어 설명, 스크린샷 설명, 최근 업데이트 노트, 리뷰에서 반복되는 칭찬을 본다.
- **seep에 없는 기능** 중 seep의 정체성("진짜 나를 위해 하고 싶은 것")에 맞는 것 하나를 고른다.

### src:fusion — 이종 분야 융합
- 위시리스트와 접점이 없는 분야 하나를 고른다. 예: 게임(퀘스트·업적·스킬트리), 피트니스(스트릭·링), 가계부(저축 목표), 여행(지도 핀·스탬프), 다이어리(회고), 수집(도감·카드), 음악(플레이리스트), 요리(레시피 단계).
- 그 분야의 **메커니즘** 하나를 뽑아 위시에 접목한다. 표면 기능을 그대로 베끼지 않는다.
- 예: "도감" → 완료한 위시가 카테고리별 도감 칸을 채움 / "스트릭" → 위시 진행 체크인 연속일

### src:research — 멀티소스 리서치
- 커뮤니티(레딧, 국내 커뮤니티), 트렌드 글, 앱스토어 리뷰, 블로그에서 "버킷리스트·위시리스트를 어떻게 관리하는지 / 무엇이 불편한지"를 3곳 이상 조사한다.
- 공통으로 나오는 니즈 하나를 기획으로 만든다.

## 4. 서버리스 조건 (반드시 통과)

seep은 서버가 없다. 아래 **허용 수단만으로** 구현되는 기획만 낸다.

| 허용 | 불가 |
|---|---|
| 로컬 Realm, UserDefaults, App Group 공유 | 자체 서버·DB·API |
| WidgetKit, App Intents, 단축어(Shortcuts), Live Activity(로컬 업데이트) | 원격 푸시(APNs 서버 발송) |
| 로컬 알림(UNUserNotificationCenter) | 사용자 간 소셜·공유 피드·친구 |
| 사진·카메라·공유 시트(UIActivityViewController) | 로그인·계정 |
| CloudKit(사용자 본인 iCloud) — 크기 L로 표시 | 외부 유료 API, 서버가 필요한 AI 호출 |
| 기기 내 프레임워크(Vision, NaturalLanguage, MapKit, EventKit, Core ML) | 서버 측 크롤링·추천 |
| Firebase Remote Config·Analytics (이미 연동됨) | |

통과하지 못하면 아이디어를 버리고 다시 고른다. 기획안에 **"서버리스 근거"** 를 한 줄로 적는다.

## 5. 크기 판단

코드를 읽고 판단한다.
- **S**: 화면 하나 안의 UI·로직, Realm 모델 변경 없음
- **M**: 화면 2개 이상 또는 Realm 모델 변경(R4 마이그레이션)
- **L**: 새 프레임워크·새 타깃(위젯 추가, App Intents, CloudKit)

사이드 프로젝트이므로 **S·M을 우선**한다. L은 다른 후보가 없을 때만.

## 6. 트래킹 이벤트 정하기

가슴속 3천원과 같은 형식(`seep-ios/log/`)으로 **기능을 실제로 쓰는지** 볼 수 있는 이벤트를 필요한 만큼(보통 1~3개) 정한다.
- 클릭: `ClickEvent(screen: .xxx, objectType: .button, objectId: .새케이스)` → GA 이벤트 `click`, 파라미터 `screen` / `object_type` / `object_id`
- 노출: `ImpressionEvent(...)` → `impression`
- 그 외: `CustomEvent(screen:, name: .새이름)` (EventName에 추가)
- 새 `objectId`·`screen` 값은 snake_case. 기존 값(`LogObjectId`, `ScreenName`)과 겹치지 않게 한다.

## 7. 이슈 작성

`.github/ISSUE_TEMPLATE/idea.yml` 형식을 따른다. 본문을 파일로 만들고 올린다.

```bash
gh issue create -R team-seep/seep-ios \
  --title "[기획] {한 줄 제목}" \
  --label idea --label "src:{competitor|fusion|research}" --label "size:{S|M|L}" \
  --body-file /tmp/seep-idea.md
```

본문:
```markdown
## 한 줄 요약
...

## 어디서 왔나
- 방식: 경쟁 앱 분석 / 이종 융합(분야: …) / 멀티소스 리서치
- 출처: [링크1](…), [링크2](…)

## 왜 seep에 어울리나
2~3줄

## 서버리스 근거
예: 로컬 Realm 필드 추가 + 로컬 알림만 사용

## 크기 · 영향 영역
- 크기: S / M / L
- 영향: [ ] Realm 스키마(R4) [ ] 위젯 [ ] 로컬 알림 [ ] 딥링크 [ ] UI

## 요구사항
- ...

## 테스트 케이스 (TC) 초안
- TC-1: Given … When … Then …
- TC-2: …

## 트래킹 이벤트
| 이벤트 | screen | object_type | object_id / name | 언제 |
|---|---|---|---|---|
| click | home | button | pin_wish | 위시 고정 버튼 탭 |

## 승인 방법
`approved` 라벨을 달면 자동 개발이 시작됩니다. 조정할 점은 코멘트로 남겨주세요. 반려하려면 사유 한 줄과 함께 닫아주세요.
```

## 8. 결과

마지막 메시지에 이슈 링크와 한 줄 요약만 남긴다. 실패하면(조사 실패, 서버리스 후보 없음) 이슈를 만들지 말고 이유를 보고한다.
