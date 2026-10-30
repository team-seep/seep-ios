#!/usr/bin/env python3
"""String Catalog(.xcstrings) → SwiftGen `Strings.swift` (GH-100 R-5).

SwiftGen 은 .xcstrings 를 읽지 못한다. 그래서 카탈로그의 원문(ko) 값으로 임시 .strings 를 만들어 SwiftGen 에 넘긴다.
테이블 이름(`Localization`)과 키가 그대로라 호출부 `Strings.xxx` 는 바뀌지 않는다.
복수형 변형(plural)은 원문의 `other` 값을 쓴다. 실제 화면 문구는 실행할 때 카탈로그에서 다시 읽는다.
실행할 때 읽는 번들·로케일은 앱 안에서 고른 언어(`AppLanguage`, GH-103 R-21)로 바꿔 끼운다.

사용: scripts/generate-strings.py   (make swiftgen 이 부른다)
"""
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "seep-ios/Resources/Localization.xcstrings")
OUTPUT = os.path.join(ROOT, "seep-ios/Generated/Strings.swift")
# SwiftGen 템플릿은 기기 언어 번들만 읽는다. 앱 안 언어를 따르도록 조회 부분만 바꾼다
REPLACEMENTS = [
    ("BundleToken.bundle.localizedString(", "AppLanguage.shared.bundle.localizedString("),
    ("locale: Locale.current, arguments: args", "locale: AppLanguage.shared.locale, arguments: args"),
]


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
    with open(OUTPUT, encoding="utf-8") as file:
        generated = file.read()
    for old, new in REPLACEMENTS:
        if old not in generated:
            sys.exit(f"error: Strings.swift 에서 {old!r} 를 찾지 못했습니다 (SwiftGen 템플릿이 바뀌었나요?)")
        generated = generated.replace(old, new)
    # `static let` 은 처음 한 번만 읽혀 언어를 바꿔도 그대로다. 읽을 때마다 고른 언어로 찾게 한다
    generated, count = re.subn(
        r"^(\s*)internal static let (\w+) = (Strings\.tr\(.*\))$",
        r"\1internal static var \2: String { \3 }",
        generated,
        flags=re.MULTILINE,
    )
    if count == 0:
        sys.exit("error: Strings.swift 에서 static let 문구를 찾지 못했습니다")
    with open(OUTPUT, "w", encoding="utf-8") as file:
        file.write(generated)


if __name__ == "__main__":
    main()
