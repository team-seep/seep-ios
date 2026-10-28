#!/usr/bin/env python3
"""String Catalog(.xcstrings) → SwiftGen `Strings.swift` (GH-100 R-5).

SwiftGen 은 .xcstrings 를 읽지 못한다. 그래서 카탈로그의 원문(ko) 값으로 임시 .strings 를 만들어 SwiftGen 에 넘긴다.
테이블 이름(`Localization`)과 키가 그대로라 호출부 `Strings.xxx` 는 바뀌지 않는다.
복수형 변형(plural)은 원문의 `other` 값을 쓴다. 실제 화면 문구는 실행할 때 카탈로그에서 다시 읽는다.

사용: scripts/generate-strings.py   (make swiftgen 이 부른다)
"""
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "seep-ios/Resources/Localization.xcstrings")
OUTPUT = os.path.join(ROOT, "seep-ios/Generated/Strings.swift")


def source_value(key, entry, language):
    localization = entry.get("localizations", {}).get(language)
    if localization is None:
        sys.exit(f"error: {key} 에 원문({language}) 값이 없습니다")
    if "stringUnit" in localization:
        return localization["stringUnit"]["value"]
    plural = localization.get("variations", {}).get("plural", {})
    if "other" in plural:
        return plural["other"]["stringUnit"]["value"]
    sys.exit(f"error: {key} 의 원문 값을 읽지 못했습니다 (stringUnit 이나 plural.other 가 필요)")


def escape(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def main():
    with open(CATALOG, encoding="utf-8") as file:
        catalog = json.load(file)
    language = catalog["sourceLanguage"]
    lines = [
        f'"{escape(key)}" = "{escape(source_value(key, entry, language))}";'
        for key, entry in sorted(catalog["strings"].items())
    ]
    with tempfile.TemporaryDirectory() as directory:
        # 파일 이름이 곧 테이블 이름이다
        strings_path = os.path.join(directory, "Localization.strings")
        with open(strings_path, "w", encoding="utf-8") as file:
            file.write("\n".join(lines) + "\n")
        subprocess.run(
            [
                "swiftgen", "run", "strings", strings_path,
                "--templateName", "structured-swift5",
                "--param", "enumName=Strings",
                "--output", OUTPUT,
            ],
            check=True,
        )


if __name__ == "__main__":
    main()
