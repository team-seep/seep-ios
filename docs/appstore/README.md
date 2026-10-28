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
- [ ] 언어별 스크린샷(없으면 ko 스크린샷이 쓰인다)
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
2. 장면별로 찍어 작업 폴더 `raw/{pad|duo-in|duo-out}-{home|detail|write|edit|finished|widget}.png`로 둔다. 쓰기 장면은 편집 화면(노이즈캔슬링 헤드폰)으로 찍는다.
3. `swiftc scripts/pdf2png.swift -o pdf2png` 후 오브젝트 PDF를 `obj/{car,tent,piano,books,plant,palette,chair,airplane,cake}.png`(1500px)로 뽑는다. 지금 아이폰 스크린샷은 `iphone/01.png`(로고를 여기서 잘라 쓴다).
4. `STORE_WORKDIR=<작업 폴더> python3 scripts/compose.py pad|duo-in|duo-out`, `python3 scripts/banner.py` (Pillow 필요).
