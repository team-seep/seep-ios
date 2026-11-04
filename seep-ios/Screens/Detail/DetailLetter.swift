import Foundation

/// 상세 "미래의 나에게" 섹션 모양 (GH-61 R-6, R-9). 판정은 `isSuccess` 하나 — 완료 취소하면 다시 봉인된다.
/// 쓰기·다시 쓰기·지우기는 작성/수정 문서에서 한다
enum DetailLetter: Equatable {
    /// 미완료 + 편지 있음: 자물쇠 + "이루는 날 열려요" + 봉인일·글자 수. 본문은 어디에도 없다 (TC-5)
    case sealed(caption: String)
    /// 완료 + 편지 있음: 본문 보기 전용 (R-6)
    case opened(body: String, writtenAt: String)
    /// 편지 없음: 섹션을 그리지 않는다 (R-9)
    case hidden

    init(wish: Wish) {
        guard wish.hasFutureLetter else {
            self = .hidden
            return
        }
        let sealedDate = Self.sealedDateText(wish.futureLetterSealedAt)
        if wish.isSuccess {
            self = .opened(body: wish.futureLetter, writtenAt: Strings.Detail.Letter.writtenFormat(sealedDate))
        } else {
            self = .sealed(caption: Self.sealedCaption(sealedAt: wish.futureLetterSealedAt, length: wish.futureLetter.count))
        }
    }

    /// "{M월 d일}에 봉인했어요 · {n}자" — 상세 섹션과 문서 블록이 같이 쓴다
    static func sealedCaption(sealedAt: Date?, length: Int) -> String {
        Strings.Detail.Letter.sealedCaptionFormat(sealedDateText(sealedAt), length)
    }

    private static func sealedDateText(_ date: Date?) -> String {
        date.map { DisplayDate.monthDay($0) } ?? ""
    }
}
