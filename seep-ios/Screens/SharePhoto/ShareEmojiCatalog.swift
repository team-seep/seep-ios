import Foundation

/// 사진 공유 이모지 탭에서 고르는 이모지 목록. 앱 번들 데이터 없이 유니코드 범위에서 이모지로 보이는 글자만 모은다.
/// 공유 이미지에만 쓰고 위시의 이모지는 바꾸지 않는다 (기존 ISEmojiView 키보드 대체)
enum ShareEmojiCatalog {
    struct Section: Identifiable, Equatable {
        let id: String
        /// 탭에 그릴 대표 이모지
        let symbol: String
        let emojis: [String]
    }

    static let sections: [Section] = [
        Section(id: "smileys", symbol: "😀", emojis: scalars([
            0x1F600...0x1F637, 0x1F641...0x1F644, 0x1F910...0x1F915, 0x1F920...0x1F92F,
            0x1F970...0x1F97A, 0x1FAE0...0x1FAE8
        ])),
        Section(id: "people", symbol: "👋", emojis: scalars([
            0x1F44A...0x1F450, 0x1F466...0x1F487, 0x1F645...0x1F64F, 0x1F918...0x1F91F,
            0x1F932...0x1F93E, 0x1F9D0...0x1F9DF
        ])),
        Section(id: "nature", symbol: "🐶", emojis: scalars([
            0x1F400...0x1F43F, 0x1F980...0x1F9AE, 0x1F331...0x1F344, 0x1F490...0x1F490
        ])),
        Section(id: "food", symbol: "🍔", emojis: scalars([
            0x1F345...0x1F37F, 0x1F950...0x1F96F, 0x1F9C0...0x1F9CB
        ])),
        Section(id: "activity", symbol: "⚽️", emojis: scalars([
            0x1F380...0x1F3CF, 0x26BD...0x26BE, 0x1F93A...0x1F94F
        ])),
        Section(id: "travel", symbol: "✈️", emojis: scalars([
            0x1F680...0x1F6FF, 0x1F3D4...0x1F3F0
        ])),
        Section(id: "objects", symbol: "💡", emojis: scalars([
            0x1F4A1...0x1F4FF, 0x1F500...0x1F53D, 0x1F9E0...0x1F9FF, 0x1FA70...0x1FAFF
        ])),
        Section(id: "symbols", symbol: "❤️", emojis: scalars([
            0x1F493...0x1F49F, 0x2600...0x26FF, 0x2700...0x27BF
        ])),
        Section(id: "flags", symbol: "🏳️", emojis: flags())
    ]

    /// 이모지로 그려지는 글자만 남긴다(기본 표시가 텍스트인 기호는 뺀다)
    private static func scalars(_ ranges: [ClosedRange<UInt32>]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for range in ranges {
            for value in range {
                guard let scalar = Unicode.Scalar(value),
                      scalar.properties.isEmojiPresentation else { continue }
                let emoji = String(scalar)
                if seen.insert(emoji).inserted {
                    result.append(emoji)
                }
            }
        }
        return result
    }

    /// 지역 코드 두 글자를 국기 이모지로 바꾼다
    private static func flags() -> [String] {
        Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            .sorted()
            .compactMap(flag(regionCode:))
    }

    static func flag(regionCode: String) -> String? {
        let base: UInt32 = 0x1F1E6 - 65 // "A"
        var result = ""
        for character in regionCode.uppercased().unicodeScalars {
            guard (65...90).contains(character.value),
                  let indicator = Unicode.Scalar(base + character.value) else { return nil }
            result.unicodeScalars.append(indicator)
        }
        return result.isEmpty ? nil : result
    }
}
