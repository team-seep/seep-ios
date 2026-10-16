#!/bin/sh
# xcresult 번들을 PR용 마크다운 요약으로 변환한다.
#   사용: scripts/test-summary.sh <path.xcresult>  > summary.md
# 출력: 전체 결과(통과/실패/스킵 수) + 실패한 테스트 목록만. 통과한 테스트는 나열하지 않는다.
# 이슈 TC 대비 커버리지는 PR 본문 "TC" 표가 원본이다 (docs/process/testing.md "PR에 남기는 것").
# 티켓 접두가 없는 레거시 메서드(test_TC{n}_)는 티켓 칸을 "—" 로 두고 클래스 단위로 표시한다.
# docs/process/testing.md 의 "PR에 남기는 것" 형식과 맞춘다.

set -eu
BUNDLE="${1:?xcresult 경로가 필요합니다}"

xcrun xcresulttool get test-results summary --path "$BUNDLE" > /tmp/xc-summary.json
xcrun xcresulttool get test-results tests   --path "$BUNDLE" > /tmp/xc-tests.json

python3 - <<'PY'
import json

summary = json.load(open("/tmp/xc-summary.json"))
tests = json.load(open("/tmp/xc-tests.json"))

cases = []  # (suite, name, result, 실패 메시지들)
def messages(node):
    out = []
    for c in node.get("children", []):
        if c.get("nodeType") == "Failure Message":
            out.append(c.get("name", ""))
        out += messages(c)
    return out
def walk(node, suite=None):
    t = node.get("nodeType")
    if t == "Test Suite":
        suite = node.get("name")
    if t == "Test Case":
        cases.append((suite, node.get("name", "").rstrip("()"), node.get("result"), messages(node)))
        return
    for c in node.get("children", []):
        walk(c, suite)
for n in tests.get("testNodes", []):
    walk(n)

passed, failed, skipped = summary.get("passedTests", 0), summary.get("failedTests", 0), summary.get("skippedTests", 0)
device = ""
for d in summary.get("devicesAndConfigurations", []):
    dev = d.get("device", {})
    device = f'{dev.get("deviceName","")} · iOS {dev.get("osVersion","")}'
    break
icon = "✅" if failed == 0 and summary.get("result") == "Passed" else "❌"

print(f"### {icon} 테스트 결과: {passed} passed / {failed} failed / {skipped} skipped")
print(f"_{device} · {summary.get('environmentDescription','')}_")
print()

fails = [c for c in cases if c[2] == "Failed"]
if fails:
    print("**실패한 테스트**")
    for suite, name, result, msgs in fails:
        print(f"- `{suite}.{name}`")
        for m in msgs:
            print(f"  - {m}")
    print()

PY
