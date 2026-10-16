#!/bin/sh
# 유닛 테스트 실행 + 요약.  사용: scripts/run-tests.sh [시뮬레이터 UDID]
# 서명은 ad-hoc(-) — CODE_SIGNING_ALLOWED=NO 면 App Group 엔타이틀먼트가 빠져 AppDelegate 에서 크래시한다.
# UDID 를 생략하면 설치된 iPhone 시뮬레이터 중 첫 번째를 쓴다. 결과: build/tests.xcresult, build/summary.md
set -eu
cd "$(dirname "$0")/.."

UDID="${1:-$(xcrun simctl list devices available -j | python3 -c '
import json,sys
for rt, devs in json.load(sys.stdin)["devices"].items():
    if "iOS" not in rt: continue
    for d in devs:
        if d["name"].startswith("iPhone"):
            print(d["udid"]); sys.exit()
')}"

mkdir -p build
rm -rf build/tests.xcresult
set +e
xcodebuild test \
  -project seep-ios.xcodeproj \
  -scheme seep-ios \
  -destination "platform=iOS Simulator,id=$UDID" \
  -resultBundlePath build/tests.xcresult \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  -quiet 2>&1 | tee build/xcodebuild.log | grep -E "error:|Executed|BUILD|TEST" 
set -e

if [ ! -d build/tests.xcresult ]; then
    echo "테스트가 실행되지 않았습니다 (빌드 실패). build/xcodebuild.log 확인" >&2
    exit 1
fi
scripts/test-summary.sh build/tests.xcresult | tee build/summary.md
