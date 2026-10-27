#!/bin/sh
# R4: DB 스키마 규칙 검사 (GH-79 부터 GRDB).
#   1) 레코드(seep-ios/model/dto/*.swift)마다 updatedAt·deletedAt 이 있는지, AppDatabase 에 UNIQUE 제약이 없는지 (동기화 대비)
#   2) (BASE_REF 가 주어지면) 레코드가 바뀌었는데 AppDatabase.migrator 에 새 마이그레이션이 없으면 실패
#   3) (BASE_REF 가 주어지면) base 에 있던 마이그레이션 이름이 사라졌으면 실패 (배포된 마이그레이션은 지우지 않는다)
#   사용: scripts/check-db-schema.sh            # 1) 만
#         BASE_REF=origin/develop scripts/check-db-schema.sh   # 1) + 2) + 3)  (CI 에서 사용)
# 규칙의 이유·예외: docs/architecture/RULES.md R4

set -eu
cd "$(dirname "$0")/.."

DATABASE=seep-ios/Repository/AppDatabase.swift
RECORDS="$(git ls-files 'seep-ios/model/dto/*.swift')"
FAILED=0

for FILE in $RECORDS; do
    RECORD_COUNT="$(grep -cE '^struct [A-Za-z]+Record:' "$FILE" || true)"
    UPDATED_COUNT="$(grep -cE '^    var updatedAt: Date$' "$FILE" || true)"
    DELETED_COUNT="$(grep -cE '^    var deletedAt: Date\?$' "$FILE" || true)"
    if [ "$RECORD_COUNT" != "$UPDATED_COUNT" ] || [ "$RECORD_COUNT" != "$DELETED_COUNT" ]; then
        echo "error: R4 $FILE 의 레코드 $RECORD_COUNT 개 중 updatedAt $UPDATED_COUNT 개, deletedAt $DELETED_COUNT 개입니다. 모든 레코드에 둘 다 둡니다." >&2
        FAILED=1
    fi
done

# 주석 줄은 빼고 본다
if grep -nE '\.unique\(|unique: true|UNIQUE' "$DATABASE" | grep -vE '^[0-9]+:[[:space:]]*//' >&2; then
    echo "error: R4 AppDatabase 에 UNIQUE 제약이 있습니다. PK 외 UNIQUE 는 두지 않습니다 (동기화 대비)." >&2
    FAILED=1
fi

migration_names() {
    grep -oE 'registerMigration\("[^"]+"\)' | sed -E 's/registerMigration\("([^"]+)"\)/\1/'
}

CURRENT_NAMES="$(migration_names < "$DATABASE")"
echo "  migrations: $(echo $CURRENT_NAMES)"

if [ -n "${BASE_REF:-}" ]; then
    MERGE_BASE="$(git merge-base "$BASE_REF" HEAD)"
    if BASE_SOURCE="$(git show "$MERGE_BASE:$DATABASE" 2>/dev/null)"; then
        BASE_NAMES="$(echo "$BASE_SOURCE" | migration_names)"
        for NAME in $BASE_NAMES; do
            if ! echo "$CURRENT_NAMES" | grep -qx "$NAME"; then
                echo "error: R4 배포된 마이그레이션 \"$NAME\" 이 사라졌습니다. 마이그레이션은 지우거나 이름을 바꾸지 않습니다." >&2
                FAILED=1
            fi
        done

        CHANGED_RECORDS="$(git diff --name-only "$MERGE_BASE" HEAD -- 'seep-ios/model/dto/*.swift')"
        if [ -n "$CHANGED_RECORDS" ] && [ "$(echo "$CURRENT_NAMES" | grep -c .)" = "$(echo "$BASE_NAMES" | grep -c .)" ]; then
            echo "error: R4 레코드가 바뀌었지만 AppDatabase.migrator 에 새 마이그레이션이 없습니다:" >&2
            echo "$CHANGED_RECORDS" | sed 's/^/  - /' >&2
            echo "  → registerMigration(\"v다음\") 을 추가하세요. 배포된 마이그레이션은 고치지 않습니다." >&2
            echo "  → 주석·순서만 바꿔 스키마가 실제로 안 바뀌었으면 PR 본문에 사유를 적고 리뷰어가 승인합니다." >&2
            FAILED=1
        fi
    else
        echo "  (base 에 $DATABASE 가 없어 마이그레이션 비교를 건너뜁니다 — GH-79 전환 PR)"
    fi
fi

if [ "$FAILED" != "0" ]; then
    exit 1
fi
echo "R4 OK"
