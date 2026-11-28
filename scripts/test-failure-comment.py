#!/usr/bin/env python3
"""CI 테스트 결과로 PR 코멘트 본문을 만든다. 코멘트가 필요 없으면 아무것도 출력하지 않는다.

    사용: scripts/test-failure-comment.py <xcresult 경로> <이전 코멘트 파일> <워크플로 실행 URL>

- 모두 통과하고 직전에도 실패가 없었으면 → 출력 없음 (코멘트 안 단다. 통과 증거는 CI 체크 초록)
- 실패가 있으면 → "❌ N개 실패" + 실패한 테스트만 (이름 · 파일:줄 · 메시지 한두 줄)
- 직전 실패 중 이번에 통과한 게 있으면 → "✅ 다시 통과: …" (아직 실패한 건 ❌로 같이)
- 실패 목록이 직전과 같으면 → 출력 없음 (같은 코멘트를 푸시마다 반복하지 않는다. CI 체크는 빨강)

직전 실패 목록은 이 스크립트가 단 마지막 코멘트의 숨김 마커 `<!-- test-failures {"failed": [...]} -->`에서 읽는다.
<이전 코멘트 파일>은 github-actions[bot]이 단 마커 코멘트 본문을 한 줄에 하나씩 base64로 담는다(오래된 것 → 최신).
빌드가 깨져 xcresult가 없으면 "빌드" 가짜 케이스를 실패로 넣고, 직전 실패는 그대로 이어 간다(결과를 모르므로).
"""

import base64
import json
import os
import re
import subprocess
import sys

MARK = "<!-- test-failures "
BUILD_CASE = "빌드"
RUN_CASE = "테스트 실행 (결과 Failed인데 실패 케이스 없음 — 크래시·중단 가능)"
LOCATION = re.compile(r"^(?P<file>[^:\n]+?\.swift):(?P<line>\d+):\s*(?P<msg>.*)$", re.S)


def previous_failed(path):
    """마지막 마커 코멘트의 실패 목록. 없으면 빈 목록."""
    if not os.path.exists(path):
        return []
    failed = []
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        try:
            body = base64.b64decode(line).decode("utf-8")
        except ValueError:
            continue
        start = body.find(MARK)
        end = body.find(" -->", start)
        if start < 0 or end < 0:
            continue
        try:
            failed = list(json.loads(body[start + len(MARK):end]).get("failed", []))
        except (ValueError, AttributeError):
            continue
    return failed


def xcresult(bundle, kind):
    out = subprocess.check_output(["xcrun", "xcresulttool", "get", "test-results", kind, "--path", bundle])
    return json.loads(out)


def current_failures(bundle):
    """[(이름, 위치 또는 None, 메시지 또는 None)] — 이름은 `Suite.test`."""
    if not os.path.isdir(bundle):
        return None  # 빌드 실패
    summary = xcresult(bundle, "summary")
    tests = xcresult(bundle, "tests")

    def messages(node):
        out = []
        for child in node.get("children", []):
            if child.get("nodeType") == "Failure Message":
                out.append(child.get("name", ""))
            out += messages(child)
        return out

    fails = []

    def walk(node, suite=None):
        if node.get("nodeType") == "Test Suite":
            suite = node.get("name")
        if node.get("nodeType") == "Test Case":
            if node.get("result") == "Failed":
                name = f'{suite}.{node.get("name", "").rstrip("()")}'
                fails.append((name, messages(node)))
            return
        for child in node.get("children", []):
            walk(child, suite)

    for node in tests.get("testNodes", []):
        walk(node)

    result = []
    for name, msgs in fails:
        location, message = None, None
        if msgs:
            match = LOCATION.match(msgs[0].strip())
            if match:
                location = f'{os.path.basename(match["file"])}:{match["line"]}'
                message = match["msg"]
            else:
                message = msgs[0]
            if len(msgs) > 1:
                message = f"{message} (외 {len(msgs) - 1}건)"
        result.append((name, location, message))
    if not result and summary.get("result") != "Passed":
        result.append((RUN_CASE, None, None))
    return result


def short(message):
    lines = [l.strip() for l in (message or "").splitlines() if l.strip()][:2]
    text = " / ".join(lines)
    return text if len(text) <= 300 else text[:297] + "…"


def comment_body(previous, failures, run_url):
    """코멘트 본문. 달 필요가 없으면 None."""
    if failures is None:
        return build_failed_body(previous, run_url)
    names = [name for name, _, _ in failures]
    if set(names) == set(previous):
        return None  # 모두 통과(둘 다 빈 목록)거나, 직전과 같은 실패
    repassed = [name for name in previous if name not in names]

    lines = [marker(names)]
    if repassed:
        lines.append(f"### ✅ 다시 통과: {len(repassed)}개")
        lines += [f"- `{name}`" for name in repassed]
        lines.append("")
    if failures:
        lines.append(f"### ❌ {len(failures)}개 실패")
        for name, location, message in failures:
            lines.append(f"- `{name}`" + (f" — `{location}`" if location else ""))
            if message:
                lines.append(f"  > {short(message)}")
        lines.append("")
    lines.append(f"_[워크플로 실행]({run_url})_")
    return "\n".join(lines) + "\n"


def build_failed_body(previous, run_url):
    """빌드 실패: 테스트 결과를 모르므로 직전 실패는 목록에 그대로 이어 가고, 빌드를 실패로 더한다."""
    carried = [name for name in previous if name != BUILD_CASE]
    if BUILD_CASE in previous:
        return None  # 직전에도 빌드 실패
    lines = [marker(carried + [BUILD_CASE]), "### ❌ 빌드 실패 — 테스트를 실행하지 못함", ""]
    if carried:
        lines += [f"직전에 실패한 {len(carried)}개는 결과를 모른다 — 빌드를 고친 뒤 다시 확인한다.", ""]
    lines.append(f"_[워크플로 실행]({run_url}) 로그에서 빌드 오류를 확인하세요._")
    return "\n".join(lines) + "\n"


def marker(names):
    return f'{MARK}{json.dumps({"failed": names}, ensure_ascii=False)} -->'


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    bundle, previous_path, run_url = sys.argv[1:]
    body = comment_body(previous_failed(previous_path), current_failures(bundle), run_url)
    if body:
        sys.stdout.write(body)


if __name__ == "__main__":
    main()
