import XCTest

/// App Store 언어별 정보가 글자 수 제한을 지킨다 (GH-106 TC-1)
final class AppStoreMetadataTests: XCTestCase {
    private static let limits = ["name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170, "description": 4000]

    // MARK: GH-106 TC1

    func test_GH106_TC1_언어별스토어정보가_글자수제한을지킨다() throws {
        // Given: 레포의 metadata.json
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("docs/appstore/metadata.json")
        let metadata = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: [String: String]])

        // When / Then
        XCTAssertEqual(Set(metadata.keys), ["en-US", "ja", "zh-Hans", "zh-Hant"])
        for (locale, fields) in metadata {
            for (field, limit) in Self.limits {
                let value = try XCTUnwrap(fields[field], "\(locale) \(field)")
                XCTAssertFalse(value.isEmpty, "\(locale) \(field)")
                XCTAssertLessThanOrEqual(value.count, limit, "\(locale) \(field)")
            }
            XCTAssertFalse(fields["keywords"]?.contains(", ") ?? true, "\(locale) keywords 는 쉼표 뒤 공백 없이")
        }
    }
}
