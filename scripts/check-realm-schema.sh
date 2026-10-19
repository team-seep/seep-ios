#!/bin/sh
# R4: Realm 스키마 규칙 검사.
#   1) 공용 설정(RealmConfiguration)·앱(AppDelegate)·위젯 Provider 중 schemaVersion 을 직접 쓴 곳이 모두 같은 값인지
#      (GH-48 부터 앱과 기존 위젯 Provider 는 RealmConfiguration.shared 를 쓴다. 직접 설정을 만드는 Provider 가 있으면 그 값도 본다)
#   2) (BASE_REF 가 주어지면) Realm 모델(seep-ios/model/dto/*.swift)이 바뀌었는데 schemaVersion 이 그대로면 실패
#   사용: scripts/check-realm-schema.sh            # 1) 만
#         BASE_REF=origin/develop scripts/check-realm-schema.sh   # 1) + 2)  (CI 에서 사용)
# 규칙의 이유·예외: docs/architecture/RULES.md R4

set -eu
cd "$(dirname "$0")/.."

FILES="seep-ios/Repository/RealmConfiguration.swift seep-ios/AppDelegate.swift $(git ls-files 'widget/*Provider.swift')"
VERSIONS="$(grep -HoE 'schemaVersion = [0-9]+' $FILES)"

echo "$VERSIONS" | sed 's/^/  /'
UNIQUE="$(echo "$VERSIONS" | grep -oE '[0-9]+$' | sort -u)"
if [ "$(echo "$UNIQUE" | wc -l | tr -d ' ')" != "1" ]; then
    echo "error: R4 schemaVersion 이 앱/위젯 사이에 다릅니다. 위 파일들을 같은 값으로 맞추세요." >&2
    exit 1
fi
CURRENT="$UNIQUE"

if [ -n "${BASE_REF:-}" ]; then
    MERGE_BASE="$(git merge-base "$BASE_REF" HEAD)"
    CHANGED_DTO="$(git diff --name-only "$MERGE_BASE" HEAD -- 'seep-ios/model/dto/*.swift')"
    if [ -n "$CHANGED_DTO" ]; then
        # GH-48 이전 커밋에는 RealmConfiguration.swift 가 없어 AppDelegate 에서 읽는다
        BASE_VERSION="$( (git show "$MERGE_BASE:seep-ios/Repository/RealmConfiguration.swift" 2>/dev/null || git show "$MERGE_BASE:seep-ios/AppDelegate.swift") | grep -oE 'schemaVersion = [0-9]+' | grep -oE '[0-9]+$')"
        if [ "$CURRENT" = "$BASE_VERSION" ]; then
            echo "error: R4 Realm 모델이 바뀌었지만 schemaVersion($CURRENT) 이 그대로입니다:" >&2
            echo "$CHANGED_DTO" | sed 's/^/  - /' >&2
            echo "  → schemaVersion 을 올리고(앱+위젯 전부) AppDelegate migrationBlock 에 분기를 추가하세요." >&2
            echo "  → 프로퍼티 순서·주석만 바꾼 경우 등 스키마가 실제로 안 바뀌었으면 PR 본문에 사유를 적고 리뷰어가 승인합니다." >&2
            exit 1
        fi
    fi
fi

echo "R4 OK (schemaVersion $CURRENT)"
