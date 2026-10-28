import XCTest

@testable import seep_ios_dev

/// 번역 언어 전체 검사 — 모든 키가 번역됐고, 자리표시자·굵게 칠할 부분이 원문과 맞는다 (GH-104·GH-105 TC-2·TC-3)
/// 언어를 더하면 카탈로그만 채우면 된다. 이 테스트가 그 언어도 같이 본다
final class TranslationCatalogTests: XCTestCase {
    private static let tables = ["Localization", "Localizable", "AppShortcuts", "InfoPlist"]
    /// 굵게 칠할 부분 → 그 부분이 들어 있어야 하는 긴 문장 키들
    private static let boldPairs: [(bold: String, sentences: [String])] = [
        ("home.title_format.bold", ["home.title_format.want_to_do", "home.title_format.want_to_get", "home.title_format.want_to_go"]),
        ("home.empty_title.bold", ["home.empty_title.want_to_do", "home.empty_title.want_to_get", "home.empty_title.want_to_go"]),
        ("home.year_review.count_format", ["home.year_review.title_format"]),
        ("finished.headline_count_format", ["finished.headline_format"]),
        ("year_review.headline_bold_format", ["year_review.headline_format"]),
        ("badge.collection.title_highlight_format", ["badge.collection.title_format"]),
        ("wish_search.result_count_highlight_format", ["wish_search.result_count_format"])
    ]

    private func catalog(_ name: String) throws -> [String: [String: Any]] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("seep-ios/Resources/\(name).xcstrings")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: [String: Any]])
    }

    /// stringUnit 이면 [other: 값], 복수형이면 [one: …, other: …]
    private func forms(_ entry: [String: Any], language: String) -> [String: String]? {
        guard let localization = (entry["localizations"] as? [String: Any])?[language] as? [String: Any] else { return nil }
        if let unit = localization["stringUnit"] as? [String: Any], let value = unit["value"] as? String {
            return ["other": value]
        }
        let plural = (localization["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]]
        return plural?.compactMapValues { ($0["stringUnit"] as? [String: Any])?["value"] as? String }
    }

    private func placeholders(_ text: String) -> [String] {
        let pattern = try? NSRegularExpression(pattern: #"%(?:\d+\$)?(@|lld|ld|d|%)|\$\{[A-Za-z]+\}"#)
        let range = NSRange(text.startIndex..., in: text)
        return (pattern?.matches(in: text, range: range) ?? []).map { match in
            let token = (text as NSString).substring(with: match.range)
            return token.replacingOccurrences(of: #"\d+\$"#, with: "", options: .regularExpression)
        }.sorted()
    }

    private func languages(in strings: [String: [String: Any]]) -> Set<String> {
        Set(strings.values.flatMap { (($0["localizations"] as? [String: Any]) ?? [:]).keys }).subtracting(["ko"])
    }

    // MARK: GH-104·GH-105 TC2

    func test_GH104_TC2_번역언어마다_모든키가번역되고_자리표시자가원문과같다() throws {
        let localization = try catalog("Localization")
        let languages = languages(in: localization)
        XCTAssertTrue(languages.isSuperset(of: ["en", "ja"]), "\(languages)")

        for table in Self.tables {
            for (key, entry) in try catalog(table) {
                let source = try XCTUnwrap(forms(entry, language: "ko")?["other"], key)
                for language in languages {
                    // Given / When: 그 언어 값
                    guard let translated = forms(entry, language: language), !translated.isEmpty else {
                        XCTFail("\(language) 번역 없음: \(table) \(key)")
                        continue
                    }
                    // Then
                    for (form, text) in translated {
                        XCTAssertFalse(text.isEmpty, "\(language) \(key) [\(form)]")
                        XCTAssertEqual(placeholders(text), placeholders(source), "\(language) \(key) [\(form)]")
                    }
                }
            }
        }
    }

    // MARK: GH-104·GH-105 TC3

    func test_GH104_TC3_번역언어마다_굵게칠할부분이긴문장안에있다() throws {
        let strings = try catalog("Localization")
        for language in languages(in: strings) {
            for pair in Self.boldPairs {
                // Given: 굵게 칠할 부분(숫자를 넣어 만든다)
                let boldForms = try XCTUnwrap(forms(try XCTUnwrap(strings[pair.bold]), language: language), "\(language) \(pair.bold)")
                for sentenceKey in pair.sentences {
                    let sentenceForms = try XCTUnwrap(forms(try XCTUnwrap(strings[sentenceKey]), language: language))
                    for (form, sentence) in sentenceForms {
                        // When: 같은 숫자를 넣으면
                        let bold = String(format: boldForms[form] ?? boldForms["other"] ?? "", 3)
                        let text = String(format: sentence, 3)
                        // Then: 긴 문장 안에 그대로 있다
                        XCTAssertTrue(text.contains(bold), "\(language) \(sentenceKey) [\(form)]: \(bold) ⊄ \(text)")
                    }
                }
            }
        }
    }
}
