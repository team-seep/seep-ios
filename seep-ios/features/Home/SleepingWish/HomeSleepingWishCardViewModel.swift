import Foundation
import Combine

extension HomeSleepingWishCardViewModel {
    struct Input {
        let didTapKeep = PassthroughSubject<Void, Never>()
        let didTapRelease = PassthroughSubject<Void, Never>()
    }

    struct Output {
        let wish: Wish
        /// "{n}일째 그대로예요"
        let caption: String
        /// "아직 {하고/갖고/가고} 싶어요?"
        let question: String
        /// "여전히 {하고/갖고/가고} 싶어요"
        let keepTitle: String
        let releaseTitle: String = Strings.Home.SleepingWish.release
        let didTapKeep = PassthroughSubject<Wish, Never>()
        let didTapRelease = PassthroughSubject<Wish, Never>()
    }

    struct Config {
        let wish: Wish
        let daysSinceTouched: Int
    }
}

/// 홈 리스트 맨 위의 잠든 위시 카드 (GH-30 R-6)
final class HomeSleepingWishCardViewModel {
    let input = Input()
    let output: Output
    var cancellables = Set<AnyCancellable>()

    init(config: Config) {
        self.output = Output(
            wish: config.wish,
            caption: Strings.Home.SleepingWish.captionFormat(config.daysSinceTouched),
            question: Self.question(category: config.wish.category),
            keepTitle: Self.keepTitle(category: config.wish.category)
        )

        bind()
    }

    private static func question(category: Category) -> String {
        switch category {
        case .wantToDo:
            return Strings.Home.SleepingWish.Question.wantToDo
        case .wantToGet:
            return Strings.Home.SleepingWish.Question.wantToGet
        case .wantToGo:
            return Strings.Home.SleepingWish.Question.wantToGo
        }
    }

    private static func keepTitle(category: Category) -> String {
        switch category {
        case .wantToDo:
            return Strings.Home.SleepingWish.Keep.wantToDo
        case .wantToGet:
            return Strings.Home.SleepingWish.Keep.wantToGet
        case .wantToGo:
            return Strings.Home.SleepingWish.Keep.wantToGo
        }
    }

    private func bind() {
        input.didTapKeep
            .withUnretained(self)
            .sink { (owner: HomeSleepingWishCardViewModel, _) in
                owner.output.didTapKeep.send(owner.output.wish)
            }
            .store(in: &cancellables)

        input.didTapRelease
            .withUnretained(self)
            .sink { (owner: HomeSleepingWishCardViewModel, _) in
                owner.output.didTapRelease.send(owner.output.wish)
            }
            .store(in: &cancellables)
    }
}

extension HomeSleepingWishCardViewModel: Hashable {
    static func == (lhs: HomeSleepingWishCardViewModel, rhs: HomeSleepingWishCardViewModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(output.wish)
        hasher.combine(output.caption)
        hasher.combine(output.question)
    }
}
