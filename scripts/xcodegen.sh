#!/usr/bin/env bash
# 고정한 버전의 XcodeGen 으로 project.yml → seep-ios.xcodeproj 를 만든다 (GH-112 R-6).
# 버전이 다르면 같은 project.yml 에서도 다른 프로젝트가 나와 CI 드리프트 검사가 깨지므로, 설치된 것을 쓰지 않고 이 버전을 받아 쓴다.
# 사용: scripts/xcodegen.sh            (make project 가 부른다)
#       scripts/xcodegen.sh --check    (만든 결과가 커밋된 것과 다르면 실패 — CI)
set -euo pipefail

VERSION="2.46.0"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL_DIR="$ROOT/.build/xcodegen/$VERSION"
BIN="$TOOL_DIR/xcodegen/bin/xcodegen"

if [ ! -x "$BIN" ]; then
  echo "XcodeGen $VERSION 받는 중…"
  mkdir -p "$TOOL_DIR"
  curl -fsSL "https://github.com/yonaskolb/XcodeGen/releases/download/$VERSION/xcodegen.zip" -o "$TOOL_DIR/xcodegen.zip"
  unzip -q -o "$TOOL_DIR/xcodegen.zip" -d "$TOOL_DIR"
  rm "$TOOL_DIR/xcodegen.zip"
fi

cd "$ROOT"
"$BIN" generate --quiet --spec project.yml

if [ "${1:-}" = "--check" ]; then
  # 커밋(또는 git add)해 둔 것과 비교한다. CI 에서는 커밋된 것과 같다
  if ! git diff --quiet -- seep-ios.xcodeproj || [ -n "$(git ls-files --others --exclude-standard -- seep-ios.xcodeproj)" ]; then
    echo "::error::project.yml 과 seep-ios.xcodeproj 가 다릅니다. 'make project' 로 다시 만들고 둘 다 커밋하세요." >&2
    git diff --stat -- seep-ios.xcodeproj >&2
    exit 1
  fi
  echo "project.yml 과 seep-ios.xcodeproj 가 같다"
fi
