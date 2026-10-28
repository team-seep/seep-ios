# 자동화·수동 테스트 체크리스트

유닛 테스트 코드가 못 덮는 범위를 **에이전트가 시뮬레이터로 할 것(자동화)** 과 **사람이 실기기로 할 것(수동)** 으로 가른다.
계층 정의는 `docs/process/testing.md`("테스트의 세 계층"). PR 본문 **TC 섹션** 체크리스트의 출처다.

## 1. 유닛 코드로 덮지 않는 것의 분류

경계는 하나다: **시뮬레이터로 그 상황을 만들 수 있으면 자동화, 없으면 수동.**

| 범주 | 예 | 계층 | 확인 방법 |
|---|---|---|---|
| 화면 진입·전환 | 위시 탭 → 상세, 작성 → 홈 갱신 | **자동화** | 스크린샷 |
| 애니메이션·제스처 | 스와이프 삭제, 바텀시트(PanModal), 카테고리 페이지 스와이프 | **자동화** | 영상 |
| 위젯 | 위젯 렌더링, 위젯 탭 → `widget://` 딥링크 진입 | **자동화** | 홈 화면 위젯 추가 후 스크린샷 / `simctl openurl` |
| OS 권한 팝업 | 알림·사진 권한 | **자동화** | `simctl privacy reset` 후 재현 |
| DB 마이그레이션 | 구버전 데이터 → 신버전 실행 | **자동화** | 구버전 빌드 설치·데이터 작성 → 신버전 덮어 설치 |
| 로컬 알림 실제 수신 | D-day 알림이 예정 시각에 울림 | **수동** | 실기기 (시간 경과 필요) |
| 외부 앱 공유 | 사진 공유(인스타 스토리 등) | **수동** | 실기기 |
| 스토어 | 앱스토어 이동, 리뷰 요청 | **수동** | 실기기 |

자동화로 분류했는데 `BLOCKED`/`UNCLEAR`로 끝나면, 그 TC만 수동으로 내리고 **이유를 PR에 한 줄 남긴다.**

## 2. 화면 변경 PR 공통 체크 항목

**diff에 UI 파일이 있을 때만** PR TC 섹션에 붙인다.
UI 파일 판정: `*View.swift`, `*ViewController.swift`, `*VC.swift`, `*Cell.swift`, `*BottomSheet*.swift`, `seep-ios/DesignSystem/**`, `seep-ios/AppShell/**`, `seep-ios/Screens/**`, `seep-ios/Resources/**`, `widget/**`.

전부 **자동화 계층**이다.

```markdown
- [ ] 공통 — 다크모드에서 색·아이콘 깨짐 없음
- [ ] 공통 — 작은 화면(iPhone SE급)·큰 화면(Pro Max)에서 레이아웃 깨짐 없음
- [ ] 공통 — 긴 제목·긴 메모·이모지·해시태그 많음에서 레이아웃 유지
- [ ] 공통 — 위시 0건(빈 상태)·완료만 있는 상태에서 레이아웃 유지
```

필요 없는 항목은 지우되, 지운 이유를 한 단어로 남긴다 (예: `~~다크모드~~ 색 변경 없음`).

## 3. 영역별 추가 항목

diff가 아래 경로/키워드를 건드리면 해당 블록을 추가한다.

| 트리거 (경로·키워드) | 추가 항목 |
|---|---|
| `seep-ios/model/dto/**`, `Repository/AppDatabase.swift`(migrator) | 구버전(직전 릴리즈) 데이터가 있는 상태에서 업데이트 설치 → 기존 위시·알림 유지, 위젯 정상 표시 |
| `widget/**`, `Bundle.realmName`, App Group | 위젯 3종(small/medium 가로·세로) 렌더링, 위젯 탭 딥링크 콜드 스타트/백그라운드 |
| `SceneDelegate`, `handleDeepLink`, `reservedDeepLink` | 콜드 스타트/백그라운드 두 경우 모두에서 딥링크 진입 |
| `NotificationManager`, `UNUserNotificationCenter`, `notification/**` | 알림 예약·수정·완료·삭제 시 예약 목록 갱신, 권한 거부 상태 |
| `write/**`, `wish-edit/**` | 작성 중 이탈 후 복귀, 필수값 누락 시 버튼 비활성, 이모지 입력 |
| `share-photo/**` | 사진 권한 거부 상태, 공유 시트 표시 |
| `Home/**` | 카테고리 전환·정렬·완료만 보기 필터 조합, 리스트/그리드 전환 |
| `*.xcstrings`, `Strings.swift`, `DisplayDate`, `Info.plist` 권한 문구 (다국어, GH-100) | 아래 "다국어 점검" |

### 다국어 점검 (GH-100 R-15)

시뮬레이터 실행 인자로 상황을 만든다. 스킴 **seep-ios-i18n-check**는 1번을 켜 둔 스킴이다.
```bash
xcrun simctl launch <UDID> macgongmon.seep-ios.dev -NSShowNonLocalizedStrings YES      # 1. 번역 빠진 문구가 대문자로
xcrun simctl launch <UDID> macgongmon.seep-ios.dev -NSDoubleLocalizedStrings YES       # 2. Double-Length 의사 언어
xcrun simctl launch <UDID> macgongmon.seep-ios.dev -NSAccentenateLocalizedStrings YES  # 3. Accented 의사 언어
xcrun simctl launch <UDID> macgongmon.seep-ios.dev -AppleLanguages "(en)" -AppleLocale en_US  # 4. 다른 기기 언어
```
- 주요 화면: 홈(빈 상태·개수 제목)·상세(D-day 줄·저금·일지)·적기·설정·이룬 싶, 위젯 4종, 잠금화면 위젯 2종, 제어 센터 컨트롤
- 1: 사용자에게 보이는 문구에 대문자 경고가 없다
- 2·3: 버튼·탭·CTA·위젯 문구가 잘리거나 겹치지 않는다(Tall 의사 언어는 Xcode 스킴 옵션에서만 켤 수 있어 2단계 실기기 점검으로 미룬다). RTL은 대상 언어가 아니라 보지 않는다
- 4: 번역이 없는 언어는 한국어 원문으로 보이고, 빈 문자열이나 키 이름이 보이지 않는다

## 4. PR 본문에 적는 법

```markdown
## TC
커버리지 3/3

| TC | 내용 | 계층 | 테스트 / 증거 | 결과 |
|---|---|---|---|---|
| TC-1 | 완료 시 알림 취소 | 유닛 | `test_GH12_TC1_…` | ✅ |
| TC-2 | 위젯 탭 진입 | 자동화 | widget.mp4 | ✅ PASS |
| TC-3 | 예정 시각 알림 수신 | 수동 | 아래 체크 | ☐ |

- [ ] TC-3 — 예정 시각 알림 수신 (수동, 실기기)
- [x] 공통 — 다크모드 … (자동화) → 증거 dark.png
- [ ] 위젯 — 위젯 3종 렌더링 … (자동화)
```

- **자동화 TC**는 결과 칸에 PASS와 증거 링크가 함께 있어야 커버다. 증거 없는 PASS는 PASS가 아니다.
- 리뷰어는 표에 `⚠️ 미커버`·`FAIL`이 있거나 체크되지 않은 항목이 있으면 머지하지 않는다.
