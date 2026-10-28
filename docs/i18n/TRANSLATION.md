# 번역 가이드 (GH-100)

싶의 원문은 **한국어(ko)** 다. 번역은 String Catalog(`seep-ios/Resources/*.xcstrings`)에 언어를 추가해 채운다.
번역하는 사람(사람이든 에이전트든)은 이 문서와 키마다 달린 **comment**(어느 화면 어느 자리, 자리표시자 뜻)를 보고 옮긴다.

## 파일

| 카탈로그 | 들어 있는 것 | 키 |
|---|---|---|
| `Localization.xcstrings` | 앱·위젯 화면 문구 거의 전부. 코드에서는 `Strings.xxx`(SwiftGen)로 쓴다 | `home.title_format.want_to_do` 같은 의미 키 |
| `Localizable.xcstrings` | 위젯 고르기 화면 이름·설명, 제어 센터 컨트롤, 단축어 동작 이름·매개변수 | 원문 그대로 |
| `AppShortcuts.xcstrings` | Siri·단축어에서 말해서 실행하는 문장 | 원문 그대로, `${applicationName}` 포함 |
| `InfoPlist.xcstrings` | 권한 팝업 문구(캘린더·Face ID·사진) | Info.plist 키 |

- 지원 언어: ko(원문), en(GH-103). 번역이 없는 기기 언어는 원문(ko)으로 보인다.
- 금액 문구(`detail.saving.*`)의 `%@`는 통화 기호까지 붙은 금액이다(`AmountFormatter.money`). 번역에 "원"·"$"를 넣지 않는다.
- 앱 이름(`CFBundleDisplayName`)은 빌드 설정 `DISPLAY_NAME`을 쓴다. 다른 언어 스토어 이름은 "Seep – Wishlist & Bucket List"처럼 이름 뒤에 일반 명사를 붙인다(5단계에서 확정).

## 용어집

| 원문 | 뜻 | 옮길 때 |
|---|---|---|
| 싶 | 앱 이름이자 "위시 하나"를 부르는 말("남은 싶 3개", "이룬 싶") | 앱 이름일 때는 번역하지 않는다(Seep). 위시 하나를 가리킬 때는 그 언어의 wish 에 해당하는 말 |
| 위시 | 사용자가 적은 하고·갖고·가고 싶은 것 하나 | wish / ウィッシュ(やりたいこと) / 心愿 |
| 이룬 싶 · 이뤘어요 | 위시를 완료함 | "완료(done)"보다 "이룸(achieved, came true)" 쪽 |
| 카테고리 3종 | 하고 싶어요 / 갖고 싶어요 / 가고 싶어요 | **직역하지 않는다.** 탭(짧은 말): en Do / Get / Go, ja やりたい / ほしい / 行きたい, zh 想做 / 想要 / 想去. 문장: things to do / things to get / places to go, やりたいこと / ほしいもの / 行きたい場所, 想做的事 / 想要的东西(東西) / 想去的地方 (GH-103) |
| D-day | 마감일까지 남은 날. "D-3", "D-Day", "D+5" | 기호 표기는 그대로 둔다 |
| 먼훗날 | 1년 넘게 남은 날짜 | "someday" 같은 말 |
| 일정없음 | 날짜를 정하지 않음 | "no date" |
| 미래의 나에게 | 봉인했다가 정한 날 열리는 편지 | "To future me" |
| 일지 | 위시에 남기는 짧은 기록 | journal |

## 어조

- 한국어: 존댓말 해요체. 짧고 다정하게("적어봐요!", "이뤘어요!").
- 영어: 친구에게 말하듯 casual. 느낌표는 원문보다 아껴 쓴다. 문장 첫 글자만 대문자(Sentence case).
- 일본어: です・ます. 
- 중국어: 간체·번체 모두 친근한 구어체.

## 지켜야 할 것

- **자리표시자**(`%@`, `%d`, `%lld`)의 개수·종류를 바꾸지 않는다. 어순을 바꿔야 하면 `%1$@`, `%2$d`처럼 위치를 적는다.
- **복수형 변형**이 있는 키(개수를 넣는 문구)는 그 언어의 규칙(영어 one/other)을 모두 채운다.
- **굵게 칠할 부분** 키(`…_bold`, `…_highlight_format`, `home.title_format.bold` 등)는 같은 화면의 긴 문장 안에 **글자 그대로** 들어 있어야 한다. 코드가 긴 문장에서 그 부분을 찾아 굵게 칠한다.
- 문장을 조각으로 나눈 키(위젯 "하고 싶은 것들이" + 숫자 + "개 남았어요!")는 화면에서 이어 읽히는 순서가 고정이다. 어순이 안 맞으면 키를 합치자고 이슈에 남긴다.
- 날짜 패턴 키(`detail.journal.row_date_format` 등)는 `DateFormatter` 패턴이다. 그 언어에서 자연스러운 패턴으로 바꾼다(예: 영어 `MMM d (E)`).
- 한국어 조사는 원문에 이미 붙어 있다("%@이었어요", "%@로 잠그기"). 번역은 문장 전체를 그 언어로 다시 쓴다.

## 확인

- 스킴 **seep-ios-i18n-check**: 번역이 빠진 문구를 대문자로 보여 준다(`-NSShowNonLocalizedStrings YES`).
- 의사 언어(Double-Length·Accented)로 긴 문구에서 잘리는 곳을 본다: `docs/process/e2e-and-manual-tests.md` "다국어" 절.
- 기계 번역 뒤에는 출시 전에 원어민 검수를 받는다(언어 단계마다).
