import XCTest

@testable import seep_ios_dev

/// 다국어 전환 1단계 — 원문 ko·String Catalog·날짜 포맷 (GH-100)
final class LocalizationFoundationTests: XCTestCase {
    private let korean = Locale(identifier: "ko_KR")
    private let english = Locale(identifier: "en_US")

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
    }

    /// 레포의 카탈로그 원본. 빌드 결과(번들)와 비교하려고 소스 파일을 직접 읽는다
    private func catalog(_ name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("seep-ios/Resources/\(name).xcstrings")
        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["sourceLanguage"] as? String, "ko")
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func isPlural(_ entry: Any) -> Bool {
        let localization = ((entry as? [String: Any])?["localizations"] as? [String: Any])?["ko"] as? [String: Any]
        return (localization?["variations"] as? [String: Any])?["plural"] != nil
    }

    private func sourceValue(_ entry: Any) -> String? {
        let localization = ((entry as? [String: Any])?["localizations"] as? [String: Any])?["ko"] as? [String: Any]
        if let unit = localization?["stringUnit"] as? [String: Any] {
            return unit["value"] as? String
        }
        let plural = (localization?["variations"] as? [String: Any])?["plural"] as? [String: Any]
        return ((plural?["other"] as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String
    }

    // MARK: GH-100 TC1

    func test_GH100_TC1_카탈로그의모든키가_번들에서원문값으로읽힌다() throws {
        // Given: 레포의 Localization.xcstrings
        let strings = try catalog("Localization")
        XCTAssertGreaterThan(strings.count, 500)

        for (key, entry) in strings {
            let source = try XCTUnwrap(sourceValue(entry), key)
            // When: 앱 번들에서 같은 테이블·키로 읽으면
            let value = Bundle.main.localizedString(forKey: key, value: "⚠️없음", table: "Localization")

            // Then: 원문(ko) 값과 같다. 복수형 키는 번들 값이 `%#@value@` 형식이라 숫자를 넣은 결과로 비교한다
            if isPlural(entry) {
                XCTAssertEqual(String(format: value, locale: korean, 7), String(format: source, locale: korean, 7), key)
            } else {
                XCTAssertEqual(value, source, key)
            }
        }
    }

    func test_GH100_TC1_SwiftGen호출부는_예전과같은한국어문구를돌려준다() {
        // Given / When / Then: 대표 문구 몇 개가 옮기기 전과 같다
        XCTAssertEqual(Strings.Settings.title, "설정")
        XCTAssertEqual(Strings.Home.EmptyTitle.wantToDo, "하고 싶은 것들을\n적어봐요!")
        XCTAssertEqual(Strings.Settings.Lock.titleFormat("Face ID"), "Face ID로 잠그기")
        XCTAssertEqual(Strings.notificationBodyFormat("제주도 가기"), "'제주도 가기' 하기로 한 것 잊지 않으셨나요?")
        XCTAssertEqual(WidgetCheckAction.caption(wish: Wish(title: "위시")), "누르면 완료")
        XCTAssertEqual(SmallRemainCopy(category: .wantToGo, count: 2).suffix, "곳 남았어요!")
    }

    // MARK: GH-100 TC4

    func test_GH100_TC4_한국어로케일_상세D_day날짜가_예전형식이다() {
        // Given: 2026-10-27 기준
        let now = date(2026, 10, 27)

        // When
        let thisYear = WishDetailSummary.ddayLine(endDate: date(2026, 12, 25), now: now, calendar: calendar, locale: korean)
        let farFuture = WishDetailSummary.ddayLine(endDate: date(2028, 1, 3), now: now, calendar: calendar, locale: korean)

        // Then
        XCTAssertEqual(thisYear.dateText, "12월 25일 (금)까지")
        XCTAssertEqual(farFuture.dateText, "2028년 1월 3일 (월)까지")
    }

    func test_GH100_TC4_한국어로케일_잠금화면위젯날짜가_예전형식이다() {
        // Given
        let now = date(2026, 10, 27)

        // When
        let soon = DdayText.make(endDate: date(2026, 12, 25), now: now, calendar: calendar, locale: korean)
        let far = DdayText.make(endDate: date(2028, 1, 3), now: now, calendar: calendar, locale: korean)

        // Then
        XCTAssertEqual(soon.dueText, "12월 25일 (금)까지")
        XCTAssertEqual(far.dueText, "2028년 1월 3일까지")
        XCTAssertEqual(far.dday, "먼훗날")
    }

    func test_GH100_TC4_한국어로케일_월일표시가_예전형식이다() {
        XCTAssertEqual(DisplayDate.monthDay(date(2026, 12, 25), locale: korean, calendar: calendar), "12월 25일")
        XCTAssertEqual(DisplayDate.numericYearMonthDay(date(2026, 12, 25), locale: korean, calendar: calendar), "2026. 12. 25.")
    }

    // MARK: GH-100 TC5

    func test_GH100_TC5_미국영어로케일_같은날짜가_그로케일형식으로보인다() {
        // Given
        let day = date(2026, 12, 25)

        // When / Then
        XCTAssertEqual(DisplayDate.monthDayWeekday(day, locale: english, calendar: calendar), "Fri, Dec 25")
        XCTAssertEqual(DisplayDate.yearMonthDay(day, locale: english, calendar: calendar), "Dec 25, 2026")
        XCTAssertEqual(DisplayDate.monthDay(day, locale: english, calendar: calendar), "Dec 25")
    }

    // MARK: GH-100 TC6

    func test_GH100_TC6_저장문자열은_기기달력과상관없이_같은날짜로읽힌다() {
        // Given: 저장 형식 문자열
        let stored = "2026-12-25T21:00:00.000"

        // When
        let parsed = DateUtils.toDate(dateString: stored)
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: parsed)

        // Then
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    func test_GH100_TC6_불교력·일본연호로케일에서도_고정숫자날짜는_그레고리력이다() {
        // Given: 불교력을 기본으로 쓰는 태국 로케일, 일본 연호
        let day = date(2026, 12, 25)

        // When
        let thai = DateUtils.toString(format: "yyyy.MM.dd", date: day, locale: Locale(identifier: "th_TH"))
        let japanese = DateUtils.toString(format: "yyyy.MM.dd", date: day, locale: Locale(identifier: "ja_JP@calendar=japanese"))

        // Then
        XCTAssertEqual(thai, "2026.12.25")
        XCTAssertEqual(japanese, "2026.12.25")
        XCTAssertEqual(DisplayDate.fixed(day, pattern: "yyyy.MM.dd", timeZone: calendar.timeZone), "2026.12.25")
    }

    // MARK: GH-100 TC7

    func test_GH100_TC7_알림시간이_한국어는시분_영어는AMPM으로보인다() {
        // Given: 오후 9시
        let time = date(2026, 12, 25, hour: 21)

        // When / Then
        XCTAssertEqual(DisplayDate.time(time, locale: korean, calendar: calendar), "오후 9시 00분")
        // 영어 시간 표기는 숫자와 AM/PM 사이에 좁은 공백(U+202F)을 쓴다
        XCTAssertEqual(DisplayDate.time(time, locale: english, calendar: calendar), "9:00\u{202F}PM")
    }

    // MARK: GH-100 TC8

    func test_GH100_TC8_숫자를넣는문구는_한국어결과가같고_복수형구조다() throws {
        // Given: 개수를 넣는 키
        let strings = try catalog("Localization")
        let pluralKeys = [
            "home.title_format.want_to_do", "home.select.count_format", "finished.headline_format",
            "wish_search.result_count_format", "widget.lock_screen.remain_format", "badge.condition.finish_format"
        ]

        // When / Then: 카탈로그에서 복수형 변형(ko other) 구조다
        for key in pluralKeys {
            let entry = try XCTUnwrap(strings[key] as? [String: Any], key)
            let ko = (entry["localizations"] as? [String: Any])?["ko"] as? [String: Any]
            let plural = (ko?["variations"] as? [String: Any])?["plural"] as? [String: Any]
            XCTAssertNotNil(plural?["other"], key)
        }

        // Then: 한국어 결과는 예전과 같다
        XCTAssertEqual(Strings.Home.TitleFormat.wantToDo(3), "하고 싶은 것들이\n3개 남았어요!")
        XCTAssertEqual(Strings.Home.Select.countFormat(1), "1개 선택됨")
        XCTAssertEqual(Strings.Finished.headlineFormat(12), "지금까지 이룬 싶이\n12개 모였어요!")
        XCTAssertEqual(LockScreenDdayPicker.remainText(count: 2), "남은 싶 2개")
    }

    // MARK: GH-100 TC9

    func test_GH100_TC9_권한요청문구가_예전과같다() {
        // Given / When
        func text(_ key: String) -> String {
            Bundle.main.localizedString(forKey: key, value: "⚠️없음", table: "InfoPlist")
        }

        // Then
        XCTAssertEqual(text("NSCalendarsUsageDescription"), "위시 날짜를 캘린더에 일정으로 추가하기 위해 캘린더 접근이 필요해요.")
        XCTAssertEqual(text("NSCalendarsWriteOnlyAccessUsageDescription"), "위시 날짜를 캘린더에 일정으로 추가하기 위해 캘린더 접근이 필요해요.")
        XCTAssertEqual(text("NSFaceIDUsageDescription"), "싶을 잠가두면 앱을 열 때 Face ID로 확인해요.")
        XCTAssertEqual(text("NSPhotoLibraryUsageDescription"), "공유할 이미지를 만들기 위해 앨범에 접근이 필요해요.")
    }

    // MARK: GH-100 TC14

    func test_GH100_TC14_금액천단위구분자는_로케일을따른다() {
        XCTAssertEqual(AmountFormatter.string(from: 769_000, locale: korean), "769,000")
        XCTAssertEqual(AmountFormatter.string(from: 769_000, locale: Locale(identifier: "de_DE")), "769.000")
        // 입력은 어떤 구분자든 숫자만 읽는다
        XCTAssertEqual(AmountFormatter.amount(from: "769.000"), 769_000)
    }
}
