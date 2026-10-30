# App Store 현지화 (GH-106)

`metadata.json`은 언어별 App Store 정보의 원본이다. App Store Connect(ASC)에 넣은 값과 같게 유지한다.

| 필드 | ASC 위치 | 제한 |
|---|---|---|
| `name` | 앱 정보 › 이름 | 30자 |
| `subtitle` | 앱 정보 › 부제 | 30자 |
| `keywords` | 버전 › 키워드 (쉼표 구분, 공백 없이) | 100자 |
| `promotionalText` | 버전 › 홍보 문구 (심사 없이 바꿀 수 있다) | 170자 |
| `description` | 버전 › 설명 | 4000자 |

- 원문 언어(ko)는 ASC에 있는 값을 그대로 쓴다(이 파일에 없다).
- 이름은 "Seep – {일반 명사}" 방식이다(#100 결정 4). 같은 이름이 스토어에 있으면 ASC가 거부하므로 그때 바꾼다.
- 지원 언어 표기는 바이너리의 `.lproj`(String Catalog의 언어)로 정해진다. 따로 설정하지 않는다.
- 글자 수 제한은 `AppStoreMetadataTests`가 확인한다.

## 사람이 하는 것
- [x] 언어별 스크린샷·헤더·검색 결과 이미지 (GH-117)
- [ ] 심사 제출(버전 2.7.0 초안)
- [ ] 출시 국가 확대(가격 및 사용 가능 여부)

## 스크린샷·헤더·검색 결과 이미지 (GH-113)

`assets/`는 GH-113에서 만든 이미지의 원본이다. 2.7.0 한국어에는 `ipad-13/`·`duo-inner/`만 올렸다. 헤더·검색 결과는 10월 23일에 올린 기존 이미지를 유지하고(`banner/`는 후보), 듀오 바깥 화면은 듀오 세트(최대 10장)에 자리가 없어 올리지 않았다. 아이폰 7장(2.6.0)과 같은 장면·카피 순서로 기기 크기만 바꿨다.

| 폴더 | ASC 자리 | 크기 |
|---|---|---|
| `ipad-13/` | iPad 13″ 스크린샷 7장 | 2064×2752 |
| `duo-inner/` | iPhone Duo 펼친 화면 7장 (가로) | 2853×2007 |
| `duo-outer/` | iPhone Duo 바깥 화면 7장 | 1398×2034 |
| `banner/header-3840x1646.png` | 제품 페이지 헤더 (21:9) | 3840×1646 |
| `banner/search-2400x1600.png` | 검색 결과 이미지 (3:2) | 2400×1600 |

1·2번은 초록 배경이 두 장에 이어지는 첫 화면이다. 3D 오브젝트는 앱 에셋(`Images.xcassets/category_*`)의 PDF 원본을 그대로 쓴다.

**다시 만들 때** (`scripts/`)
1. 시뮬레이터(iPad Pro 13″, iPhone Duo)에 Debug 앱을 설치하고 한 번 실행한 뒤 `seed.py <App Group dev.sqlite>`로 예시 위시를 넣는다. 상태 바는 `xcrun simctl status_bar <udid> override --time 9:41 …`.
2. 장면별로 찍어 작업 폴더 `raw/{phone|pad|duo-in|duo-out}-{언어}-{home|detail|write|edit|finished|widget}.png`로 둔다. 쓰기 장면은 편집 화면(노이즈캔슬링 헤드폰)으로 찍는다.
3. `swiftc scripts/pdf2png.swift -o pdf2png` 후 오브젝트 PDF를 `obj/{car,tent,piano,books,plant,palette,chair,airplane,cake}.png`(1500px)로 뽑는다. 지금 아이폰 스크린샷은 `iphone/01.png`(로고를 여기서 잘라 쓴다).
4. `STORE_WORKDIR=<작업 폴더> STORE_LANG=<언어> python3 scripts/compose.py phone|pad|duo-in|duo-out`, 같은 환경 변수로 `python3 scripts/banner.py` (Pillow 필요). 결과는 `out/{언어}/…`.

## 언어별 이미지 (GH-117)

`assets/{en-US,ja,zh-Hans,zh-Hant}/`에 한국어 2.7.0에 올라간 크기만 언어별로 만들어 2.7.0 각 언어에 올렸다(한국어·라이브 2.6.0은 그대로).

| 폴더 | ASC 자리 | 크기 |
|---|---|---|
| `iphone-69/` | iPhone 6.9″ 7장 | 1320×2868 |
| `iphone-61/` | iPhone 6.1″ 7장 (6.9″를 줄임) | 1206×2622 |
| `ipad-13/` | iPad 13″ 7장 | 2064×2752 |
| `duo-inner/` | iPhone Duo 펼친 화면 7장 | 2853×2007 |
| `banner/` | 제품 페이지 헤더·검색 결과 이미지 | 3840×1646, 2400×1600 |

- 카피와 예시 위시는 `assets/l10n/copy.json`(언어별 `hero`·`scenes`·`seed`·`memo`·`steps`). 번역은 별도 검수 에이전트가 19건을 짚어 모두 반영했다(용어·어조는 `docs/i18n/TRANSLATION.md`).
- `seed.py <dev.sqlite> <언어>`가 언어별 예시 위시·통화(USD·JPY·CNY·TWD)를 넣는다. 지명은 언어권에 맞췄다(서핑: 샌디에이고·쇼난·싼야·컨딩).
- 시뮬레이터 언어는 `simctl spawn <udid> defaults write -g AppleLanguages -array <언어>` 후 재부팅. 듀오는 재부팅하면 접히므로 `launchctl kill SIGKILL system/com.apple.SpringBoard`로 홈 화면만 다시 띄운다.
- 위젯 장면은 앱 안 위젯 안내 이미지가 한국어로만 그려져 있어, 시스템 위젯 고르기 화면을 그 언어로 찍었다. 개발 빌드 이름 "싶Dev"의 "Dev"는 `scripts/undev.py`로 지운다.
- 번역이 길면 `compose.py`가 제목을 줄이고 부제를 두 줄로 나눈다(한중일은 글자 사이, 문장부호 앞은 피한다).
