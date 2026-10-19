import XCTest
import Combine

@testable import seep_ios_dev

final class YearReviewViewModelTests: XCTestCase {
    private var calendar: Calendar!
    private var repository: MockWishRepository!
    private var logManager: MockLogManager!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        repository = MockWishRepository()
        logManager = MockLogManager()
    }

    override func tearDown() {
        cancellables = []
        super.tearDown()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeViewModel(year: Int = 2026) -> YearReviewViewModel {
        YearReviewViewModel(
            config: .init(year: year),
            dependency: .init(wishRepository: repository, logManager: logManager, calendar: calendar)
        )
    }

    // MARK: GH-34 TC6 (화면 집계)

    func test_GH34_TC6_화면이나타나면_대상연도구간의완료위시로집계한다() {
        // Given
        repository.fetchFinishedWishesResult = [
            Wish(id: "do", category: .wantToDo, finishDate: date(2026, 2, 1), isSuccess: true),
            Wish(id: "get", category: .wantToGet, finishDate: date(2026, 9, 1), isSuccess: true),
            Wish(id: "old", category: .wantToGo, finishDate: date(2025, 9, 1), isSuccess: true)
        ]
        let viewModel = makeViewModel()

        // When
        viewModel.input.viewWillAppear.send(())

        // Then
        let summary = viewModel.output.summary.value
        XCTAssertEqual(summary?.totalCount, 2)
        XCTAssertEqual(summary?.count(of: .wantToGo), 0)
        XCTAssertEqual(repository.fetchFinishedWishesCalls.first?.from, date(2026, 1, 1))
        XCTAssertEqual(repository.fetchFinishedWishesCalls.first?.to, date(2027, 1, 1))
    }

    // MARK: GH-34 TC10

    func test_GH34_TC10_이미지로공유하기를탭하면_이미지1장과공유시트route가나오고_공유로그가1회전송된다() {
        // Given
        let viewModel = makeViewModel()
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        var sharedImages: [Data] = []
        viewModel.output.route
            .sink { route in
                if case .presentShareSheet(let data) = route {
                    sharedImages.append(data)
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapShare.send(imageData)

        // Then
        XCTAssertEqual(sharedImages, [imageData])
        XCTAssertEqual(logManager.sentEvents.count, 1)
        let event = logManager.sentEvents.first
        XCTAssertEqual(event?.name, .click)
        XCTAssertEqual(event?.screen, .yearReview)
        XCTAssertEqual(event?.extraParameters?[.objectType] as? LogObjectType, .button)
        XCTAssertEqual(event?.extraParameters?[.objectId] as? LogObjectId, .shareYearReview)
        XCTAssertEqual(event?.extraParameters?[.year] as? Int, 2026)
    }

    // MARK: GH-34 TC15 (모두 보기 이동)

    func test_GH34_TC15_모두보기를탭하면_같은연도목록화면으로이동한다() {
        // Given
        let viewModel = makeViewModel()
        var listViewModel: YearReviewListViewModel?
        viewModel.output.route
            .sink { route in
                if case .pushYearReviewList(let pushed) = route {
                    listViewModel = pushed
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapShowAll.send(())

        // Then
        XCTAssertEqual(listViewModel?.output.year, 2026)
    }

    // MARK: GH-34 TC16

    func test_GH34_TC16_완료취소한위시는_다시나타날때집계에서빠진다() {
        // Given
        let kept = Wish(id: "kept", finishDate: date(2026, 4, 1), isSuccess: true)
        let cancelled = Wish(id: "cancelled", finishDate: date(2026, 5, 1), isSuccess: true)
        repository.fetchFinishedWishesResult = [kept, cancelled]
        let viewModel = makeViewModel()
        viewModel.input.viewWillAppear.send(())
        XCTAssertEqual(viewModel.output.summary.value?.totalCount, 2)

        // When: 목록 → 상세에서 완료 취소하고 돌아온다
        var reverted = cancelled
        reverted.isSuccess = false
        reverted.finishDate = nil
        repository.fetchFinishedWishesResult = [kept, reverted]
        viewModel.input.viewWillAppear.send(())

        // Then
        XCTAssertEqual(viewModel.output.summary.value?.totalCount, 1)
        XCTAssertEqual(viewModel.output.summary.value?.wishes.map(\.id), ["kept"])
    }

    func test_GH34_TC16_닫기를탭하면_dismiss와닫힘이벤트가나온다() {
        // Given
        let viewModel = makeViewModel()
        var didDismiss = false
        var didNotify = false
        viewModel.output.route
            .sink { route in
                if case .dismiss = route { didDismiss = true }
            }
            .store(in: &cancellables)
        viewModel.output.dismissed
            .sink { didNotify = true }
            .store(in: &cancellables)

        // When
        viewModel.input.didTapClose.send(())

        // Then
        XCTAssertTrue(didDismiss)
        XCTAssertTrue(didNotify)
    }
}
