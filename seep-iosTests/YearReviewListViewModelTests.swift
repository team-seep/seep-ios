import XCTest
import Combine

@testable import seep_ios_dev

final class YearReviewListViewModelTests: XCTestCase {
    private var calendar: Calendar!
    private var repository: MockWishRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        repository = MockWishRepository()
    }

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeViewModel() -> YearReviewListViewModel {
        YearReviewListViewModel(
            config: .init(year: 2026),
            dependency: .init(wishRepository: repository, calendar: calendar)
        )
    }

    // MARK: GH-34 TC15

    func test_GH34_TC15_달내림차순으로묶고_소감이없으면완료일을보인다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "aug2", finishDate: date(2026, 8, 2), isSuccess: true),
            Wish(id: "dec3", finishDate: date(2026, 12, 3), isSuccess: true, finishNote: "드디어 겟!"),
            Wish(id: "aug31", finishDate: date(2026, 8, 31), isSuccess: true)
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.input.viewWillAppear.send(())

        // Then
        let sections = viewModel.output.sections.value
        XCTAssertEqual(viewModel.output.totalCount.value, 3)
        XCTAssertEqual(sections.map(\.month), [12, 8])
        XCTAssertEqual(sections[1].items.map(\.wish.id), ["aug31", "aug2"])
        XCTAssertEqual(sections[0].items.first?.note, "“드디어 겟!”")
        XCTAssertNil(sections[1].items.first?.note)
        XCTAssertEqual(sections[1].items.first?.finishDateText, "08.31")
        XCTAssertEqual(sections[1].items.last?.finishDateText, "08.02")
    }

    func test_GH34_TC15_셀을탭하면_그위시의상세로이동한다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "aug2", finishDate: date(2026, 8, 2), isSuccess: true),
            Wish(id: "dec3", finishDate: date(2026, 12, 3), isSuccess: true)
        ]
        let viewModel = makeViewModel()
        viewModel.input.viewWillAppear.send(())
        var pushedWishId: String?
        viewModel.output.route
            .sink { route in
                if case .pushWishDetail(let reactor) = route {
                    pushedWishId = reactor.initialState.wish.id
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapWish.send(IndexPath(item: 0, section: 1))

        // Then
        XCTAssertEqual(pushedWishId, "aug2")
    }
}
