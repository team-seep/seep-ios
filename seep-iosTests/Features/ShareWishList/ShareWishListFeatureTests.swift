import XCTest

@testable import seep_ios

/// 골라서 보내기 미리보기 — 카드·글·토글·보내기 로그 (GH-125 R-3 ~ R-7)
final class ShareWishListFeatureTests: ViewModelTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    /// 2026-11-04 12:00 KST
    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 12))!
    }

    private func days(_ value: Int) -> Date {
        calendar.date(byAdding: .day, value: value, to: today)!
    }

    private func makeSut(category: seep_ios.Category = .wantToGet, wishes: [Wish]) -> ShareWishListViewModel {
        ShareWishListViewModel(
            config: .init(category: category, wishes: wishes),
            dependency: .init(logManager: logManager, now: { self.today }, calendar: calendar)
        )
    }

    private let airpods = Wish(
        id: "a", emoji: "🎧", category: .wantToGet, title: "에어팟 프로 3",
        link: "https://www.apple.com/kr/airpods-pro/"
    )
    private let shoes = Wish(id: "b", emoji: "👟", category: .wantToGet, title: "러닝화 새로 하나")

    // MARK: GH-125 TC3

    func test_GH125_TC3_링크있는싶과없는싶이면_도메인은링크있는줄에만_글에는링크1줄() {
        // Given
        let wishes = [airpods, shoes]

        // When
        let sut = makeSut(wishes: wishes)

        // Then
        XCTAssertEqual(sut.state.card.rows.map(\.domain), ["apple.com", nil])
        let linkLines = sut.state.text.split(separator: "\n").filter { $0.hasPrefix("http") }
        XCTAssertEqual(linkLines, ["https://www.apple.com/kr/airpods-pro/"])
    }

    func test_GH125_TC3_링크토글을끄면_글의링크와카드의도메인이빠진다() {
        // Given
        let sut = makeSut(wishes: [airpods, shoes])

        // When
        sut.send(.setIncludesLink(false))

        // Then
        XCTAssertEqual(sut.state.card.rows.map(\.domain), [nil, nil])
        XCTAssertFalse(sut.state.text.contains("http"))
    }

    // MARK: GH-125 TC4

    func test_GH125_TC4_링크있는싶이없으면_링크토글이안보인다() {
        // Given
        let wishes = [shoes, Wish(id: "c", emoji: "📷", category: .wantToGet, title: "필름 카메라")]

        // When
        let sut = makeSut(wishes: wishes)

        // Then
        XCTAssertFalse(sut.state.isLinkToggleVisible)
    }

    func test_GH125_TC4_링크있는싶이하나라도있으면_링크토글이켜진채로보인다() {
        // Given / When
        let sut = makeSut(wishes: [shoes, airpods])

        // Then
        XCTAssertTrue(sut.state.isLinkToggleVisible)
        XCTAssertTrue(sut.state.includesLink)
    }

    // MARK: GH-125 TC5

    func test_GH125_TC5_Dday토글을끄면_카드와글어디에도Dday가없다() {
        // Given
        let wishes = [
            Wish(id: "a", emoji: "🎧", category: .wantToGet, title: "에어팟 프로 3", endDate: days(23)),
            Wish(id: "b", emoji: "📷", category: .wantToGet, title: "필름 카메라", endDate: days(400)),
            Wish(id: "c", emoji: "🪴", category: .wantToGet, title: "몬스테라", endDate: days(-2)),
            shoes
        ]
        let sut = makeSut(wishes: wishes)
        let before = sut.state.text

        // When
        sut.send(.setIncludesDday(false))

        // Then
        XCTAssertTrue(before.contains("(D-23)"))
        XCTAssertTrue(sut.state.card.rows.allSatisfy { $0.dday == nil })
        for word in ["D-", "D+", Strings.homeInFarFurture, Strings.homeNoDeanline] {
            XCTAssertFalse(sut.state.text.contains(word), word)
        }
    }

    func test_GH125_TC5_Dday가켜져있으면_카드는뱃지를_글은날짜있는싶만괄호로붙인다() {
        // Given
        let wishes = [
            Wish(id: "a", emoji: "🎧", category: .wantToGet, title: "에어팟 프로 3", endDate: days(23)),
            shoes
        ]

        // When
        let sut = makeSut(wishes: wishes)

        // Then
        XCTAssertEqual(sut.state.card.rows.map(\.dday), [
            DdayBadgeStyle(endDate: days(23), today: today, calendar: calendar),
            DdayBadgeStyle(endDate: nil, today: today, calendar: calendar)
        ])
        XCTAssertEqual(sut.state.text, "갖고 싶어요 2개\n🎧 에어팟 프로 3 (D-23)\n👟 러닝화 새로 하나")
    }

    // MARK: GH-125 TC6

    func test_GH125_TC6_12개를고르면_카드는9줄과외3개_글은12개전부() {
        // Given
        let wishes = (1...12).map { Wish(id: "\($0)", emoji: "⭐️", category: .wantToGet, title: "싶 \($0)") }

        // When
        let sut = makeSut(wishes: wishes)

        // Then
        XCTAssertEqual(sut.state.card.rows.count, 9)
        XCTAssertEqual(sut.state.card.moreCount, 3)
        XCTAssertEqual(Strings.ShareWishList.Card.moreFormat(sut.state.card.moreCount), "외 3개")
        XCTAssertEqual(sut.state.card.count, 12)
        XCTAssertEqual(sut.state.text.split(separator: "\n").count, 1 + 12)
        XCTAssertTrue(sut.state.text.contains("싶 12"))
    }

    func test_GH125_TC6_딱10개면_외n개없이10줄() {
        // Given
        let wishes = (1...10).map { Wish(id: "\($0)", emoji: "⭐️", category: .wantToGet, title: "싶 \($0)") }

        // When
        let sut = makeSut(wishes: wishes)

        // Then
        XCTAssertEqual(sut.state.card.rows.count, 10)
        XCTAssertEqual(sut.state.card.moreCount, 0)
    }

    // MARK: GH-125 TC7

    func test_GH125_TC7_메모해시태그사진이있어도_카드와글에들어가지않는다() {
        // Given
        let wish = Wish(
            id: "a", emoji: "🎧", category: .wantToGet, title: "에어팟 프로 3",
            memo: "비밀 메모 내용", tags: ["생일선물"], photoFileName: "secret-photo.jpg"
        )

        // When
        let sut = makeSut(wishes: [wish])

        // Then
        XCTAssertEqual(sut.state.card.rows, [
            ShareWishListCard.Row(id: "a", emoji: "🎧", title: "에어팟 프로 3", domain: nil, dday: sut.state.card.rows.first?.dday)
        ])
        for secret in ["비밀 메모", "생일선물", "#", "secret-photo"] {
            XCTAssertFalse(sut.state.text.contains(secret), secret)
        }
    }

    // MARK: GH-125 TC10

    func test_GH125_TC10_보내기를누르면_send_wish_list로그가count와토글조합으로1번간다() {
        // Given
        let sut = makeSut(wishes: [airpods, shoes])

        // When
        sut.send(.didTapSend)

        // Then
        let events = clickEvents(objectId: .sendWishList)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.screen, .shareWishList)
        XCTAssertEqual(events.first?.extraParameters?[.count] as? Int, 2)
        XCTAssertEqual(events.first?.extraParameters?[.type] as? String, "dday_link")
    }

    func test_GH125_TC10_토글조합에따라_type이dday_link_dday_link_none이다() {
        // Given
        let sut = makeSut(wishes: [airpods])

        // When
        sut.send(.setIncludesLink(false))
        sut.send(.didTapSend)
        sut.send(.setIncludesDday(false))
        sut.send(.didTapSend)
        sut.send(.setIncludesLink(true))
        sut.send(.didTapSend)

        // Then
        let types = clickEvents(objectId: .sendWishList).compactMap { $0.extraParameters?[.type] as? String }
        XCTAssertEqual(types, ["dday", "none", "link"])
    }

    func test_GH125_TC10_링크토글이숨어있으면_type에link가없다() {
        // Given
        let sut = makeSut(wishes: [shoes])

        // When
        sut.send(.didTapSend)

        // Then
        XCTAssertEqual(clickEvents(objectId: .sendWishList).first?.extraParameters?[.type] as? String, "dday")
    }

    // MARK: GH-125 TC13

    func test_GH125_TC13_카드제목은카테고리와개수_날짜는오늘_글첫줄은카테고리n개() {
        // Given
        let wishes = [airpods, shoes, Wish(id: "c", emoji: "📷", category: .wantToGet, title: "필름 카메라")]

        // When
        let sut = makeSut(category: .wantToGet, wishes: wishes)

        // Then
        XCTAssertEqual(sut.state.card.categoryTitle, "갖고 싶어요")
        XCTAssertEqual(sut.state.card.count, 3)
        XCTAssertEqual(sut.state.card.dateText, "2026.11.04")
        XCTAssertEqual(sut.state.text.split(separator: "\n").first, "갖고 싶어요 3개")
    }

    func test_GH125_TC8_닫기를누르면_dismiss로간다() {
        // Given
        let sut = makeSut(wishes: [shoes])

        // When
        sut.send(.tapClose)

        // Then
        XCTAssertEqual(sut.route, .dismiss)
        sut.send(.routeHandled)
        XCTAssertNil(sut.route)
    }
}
