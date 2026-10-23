# 싶 브랜드 자산 (GH-74)

- 앱 아이콘: `seep-ios/Resources/AppIcon.icon` (Icon Composer). 심볼은 위·아래 두 SVG 레이어, 바탕은 tennis-green 자동 그라데이션, 다크에서는 심볼을 초록으로 바꾼다.
  - 미리보기: `ictool AppIcon.icon --export-image --output-file out.png --platform iOS --rendition Default --width 1024 --height 1024 --scale 1` (`ictool`은 `Icon Composer.app/Contents/Executables/`)
- 로고: `ic_logo_black`·`ic_logo_white` SVG (아이콘 심볼과 같은 도형).
- App Store 이미지(스크린샷 7장 1320×2868, 헤더 3840×1646, 검색결과 3840×2560): 용량 때문에 레포에 넣지 않고 GitHub Release `design-previews`의 `brand74-final-*.png`에 둔다.
  - 다시 만들 때: `store_images.py`. `src/`에 시뮬레이터 캡처(9:41 상태 표시줄)와 카테고리 일러스트 PNG를 두고 실행하면 Chrome headless로 `out/`에 렌더링한다.
