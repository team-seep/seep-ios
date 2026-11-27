import Foundation

import GRDB

/// `wish` 테이블 한 줄 (GH-79 R-2). 위시가 최상위 레코드이고 단계·저금·알림은 `wishId`로 이 줄을 가리킨다 (R-8).
/// 동기화를 붙일 수 있게 PK 는 UUID 문자열, 모든 쓰기는 `updatedAt`을 갱신하고 삭제는 `deletedAt`만 남긴다 (R-3~R-5).
/// 저장 프로퍼티를 바꾸면 `AppDatabase.migrator`에 새 마이그레이션을 추가한다 (RULES R4).
struct WishRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wish"

    var id: String
    var category: String
    var emoji: String
    var title: String
    /// 마감 기한
    var date: Date?
    var finishDate: Date?
    /// 목표 금액. 통화의 최소 단위 정수. 0 이면 저금통 없음 (GH-16)
    var targetAmount: Int
    /// 목표 금액·저금 기록의 통화(ISO 4217). 예전 위시는 KRW (GH-103, 마이그레이션 v6)
    var currency: String
    var memo: String
    var hashtag: String
    var isSuccess: Bool
    /// 완료 소감 한 줄. 비어 있으면 소감 없음 (GH-25)
    var finishNote: String
    /// 홈 맨 위에 고정한 시각. nil 이면 고정 아님 (GH-33)
    var pinnedAt: Date?
    /// 갖고 싶어요의 상품 링크. 비어 있으면 링크 없음 (GH-29)
    var link: String
    /// 마지막으로 점검한 시각. nil 이면 createdAt 기준으로 잠든 위시를 판정한다 (GH-30)
    var lastCheckedAt: Date?
    /// 붙인 장소 이름. 비어 있으면 장소 없음 (GH-31)
    var placeName: String
    var placeAddress: String
    var latitude: Double
    var longitude: Double
    /// 붙인 사진 파일 이름(`Application Support/WishPhotos/` 안). 비어 있으면 사진 없음 (GH-36)
    var photoFileName: String
    /// "미래의 나에게" 편지. 비어 있으면 편지 없음 (GH-61, 마이그레이션 v2)
    var futureLetter: String
    var futureLetterSealedAt: Date?
    /// "내가 정한 순서" 값. 카테고리 안에서 작을수록 위. UNIQUE 를 두지 않고 같으면 createdAt 으로 가른다 (GH-73, 마이그레이션 v3)
    var manualOrder: Double
    /// 이어서 적은 앞 위시 id. nil 이면 처음 싶. 동기화 대비로 FK·UNIQUE 를 두지 않는다 (GH-84, 마이그레이션 v4)
    var previousWishId: String?
    /// "시작했어요"를 누른(또는 단계 체크·저금으로 자동 시작한) 시각. nil 이면 시작 전. 이뤄도 남긴다 (GH-143, 마이그레이션 v12)
    var startedAt: Date?
    /// 기한 종류. "" · "date" = 날짜, "month" · "year" · "next_year" = 기간이고 `date`가 그 기간의 마지막 날 (GH-118, 마이그레이션 v14)
    var deadlineKind: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let category = Column(CodingKeys.category)
        static let isSuccess = Column(CodingKeys.isSuccess)
        static let finishDate = Column(CodingKeys.finishDate)
        static let manualOrder = Column(CodingKeys.manualOrder)
        static let previousWishId = Column(CodingKeys.previousWishId)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }
}

/// `wishStep` 테이블 한 줄. 위시의 단계(체크리스트 한 줄)
struct WishStepRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wishStep"

    var id: String
    var wishId: String
    var title: String
    var isDone: Bool
    /// 체크한 시각. 체크를 풀면 nil. v11 전에 체크한 단계는 nil 로 남는다 — 지난 날짜는 추정하지 않는다 (GH-146 R-2, R-7)
    var doneAt: Date?
    var order: Int
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let wishId = Column(CodingKeys.wishId)
        static let doneAt = Column(CodingKeys.doneAt)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }

    /// 체크 여부를 바꾸고 체크한 시각을 같이 맞춘다. 이미 체크된 단계를 다시 체크해도 처음 시각을 지킨다 (GH-146 R-2)
    mutating func setDone(_ isDone: Bool, at now: Date) {
        if isDone {
            if !self.isDone { doneAt = now }
        } else {
            doneAt = nil
        }
        self.isDone = isDone
    }
}

/// `wishSaving` 테이블 한 줄. "갖고 싶어요" 위시에 모은 돈 기록 한 건 (GH-16)
struct WishSavingRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wishSaving"

    var id: String
    var wishId: String
    var amount: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let wishId = Column(CodingKeys.wishId)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }
}

/// `wishJournal` 테이블 한 줄. 이루는 동안 남긴 일지 (GH-95, 마이그레이션 v5).
/// 동기화 대비로 `wishId`에 FK 를 두지 않는다 — 다른 기기의 일지가 위시보다 먼저 와도 들어갈 수 있게 (R-1)
struct WishJournalRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wishJournal"

    var id: String
    var wishId: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let wishId = Column(CodingKeys.wishId)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }
}

/// `wishTag` 테이블 한 줄. 위시에 붙인 태그 하나 (GH-136, 마이그레이션 v9).
/// 일지처럼 동기화 대비로 `wishId`에 FK 를 두지 않고, 같은 이름도 UNIQUE 로 막지 않는다 — 중복은 쓰기에서 막는다 (R4)
struct WishTagRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wishTag"

    var id: String
    var wishId: String
    /// 기본 태그는 `HashtagType` rawValue, 직접 입력은 글자 그대로
    var name: String
    /// 위시 안에서 보여 주는 순서. 첫 태그가 대표 태그다
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let wishId = Column(CodingKeys.wishId)
        static let name = Column(CodingKeys.name)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }
}

/// `wishNotification` 테이블 한 줄. id 는 예약한 로컬 알림의 identifier 와 같다 (GH-48)
struct WishNotificationRecord: Codable, Equatable, FetchableRecord, PersistableRecord, TableRecord {
    static let databaseTableName = "wishNotification"

    var id: String
    var wishId: String
    var type: String
    var time: Date
    /// 위시 안에서 보여 주는 순서. Realm List 순서를 그대로 옮긴다
    var order: Int
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let wishId = Column(CodingKeys.wishId)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }
}

extension WishRecord {
    init(wish: Wish, updatedAt: Date) {
        self.id = wish.id
        self.category = wish.category.rawValue
        self.emoji = wish.emoji
        self.title = wish.title
        self.date = wish.endDate
        self.finishDate = wish.finishDate
        self.targetAmount = wish.targetAmount
        self.currency = wish.currency
        self.memo = wish.memo
        self.hashtag = wish.hashtag
        self.isSuccess = wish.isSuccess
        self.finishNote = wish.finishNote
        self.pinnedAt = wish.pinnedAt
        self.link = wish.link
        self.lastCheckedAt = wish.lastCheckedAt
        self.placeName = wish.place?.name ?? ""
        self.placeAddress = wish.place?.address ?? ""
        self.latitude = wish.place?.latitude ?? 0
        self.longitude = wish.place?.longitude ?? 0
        self.photoFileName = wish.photoFileName
        self.futureLetter = wish.futureLetter
        self.futureLetterSealedAt = wish.futureLetterSealedAt
        self.manualOrder = wish.manualOrder
        self.previousWishId = wish.previousWishId
        self.startedAt = wish.startedAt
        self.deadlineKind = wish.deadlineKind.rawValue
        self.createdAt = wish.createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

extension WishStepRecord {
    /// - Parameter doneAt: 체크한 시각. 새 단계·이전 데이터는 nil (GH-146 R-7)
    init(step: WishStep, wishId: String, updatedAt: Date, doneAt: Date? = nil) {
        self.id = step.id
        self.wishId = wishId
        self.title = step.title
        self.isDone = step.isDone
        self.doneAt = step.isDone ? doneAt : nil
        self.order = step.order
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

extension WishSavingRecord {
    init(saving: WishSaving, wishId: String, updatedAt: Date) {
        self.id = saving.id
        self.wishId = wishId
        self.amount = saving.amount
        self.createdAt = saving.createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

extension WishJournalRecord {
    init(journal: WishJournal, wishId: String, updatedAt: Date) {
        self.id = journal.id
        self.wishId = wishId
        self.text = journal.text
        self.createdAt = journal.createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

extension WishTagRecord {
    init(name: String, wishId: String, order: Int, now: Date) {
        self.id = UUID().uuidString
        self.wishId = wishId
        self.name = name
        self.order = order
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }
}

extension WishNotificationRecord {
    init(notification: SeepNotification, wishId: String, order: Int, updatedAt: Date) {
        self.id = notification.id
        self.wishId = wishId
        self.type = notification.type.rawValue
        self.time = notification.time
        self.order = order
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

// Date 를 기준 시각부터의 초(Double)로 저장한다. 문자열(기본값)은 밀리초에서 잘려 저장 전후 값이 달라진다
extension WishRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension WishStepRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension WishSavingRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension WishJournalRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension WishTagRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension WishNotificationRecord {
    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy { .timeIntervalSinceReferenceDate }
    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy { .timeIntervalSinceReferenceDate }
}

extension Wish {
    /// 레코드에서 위시를 만든다. 하위 레코드는 이 위시의 살아 있는 줄(deletedAt == nil)만 넘긴다
    init(
        record: WishRecord,
        steps: [WishStepRecord],
        savings: [WishSavingRecord],
        notifications: [WishNotificationRecord],
        journals: [WishJournalRecord] = [],
        tags: [WishTagRecord] = []
    ) {
        // 기기 달력(Calendar.current)으로 맞춘다. 화면(SoftDeadline 등)도 실제 앱에서는 같은 달력을 쓴다
        let deadline = Self.deadline(stored: record.deadlineKind, endDate: record.date)
        self.init(
            id: record.id,
            emoji: record.emoji,
            category: Category(rawValue: record.category) ?? .wantToDo,
            title: record.title,
            endDate: deadline.endDate,
            deadlineKind: deadline.kind,
            finishDate: record.finishDate,
            notifications: notifications
                .sorted { $0.order < $1.order }
                .map { SeepNotification(id: $0.id, type: .init(rawValue: $0.type) ?? .targetDay, time: $0.time) },
            steps: steps
                .map { WishStep(id: $0.id, title: $0.title, isDone: $0.isDone, order: $0.order) }
                .sorted { $0.order < $1.order },
            targetAmount: record.targetAmount,
            currency: record.currency,
            savings: WishSaving.latestFirst(savings.map { WishSaving(id: $0.id, amount: $0.amount, createdAt: $0.createdAt) }),
            journals: WishJournal.latestFirst(journals.map { WishJournal(id: $0.id, text: $0.text, createdAt: $0.createdAt) }),
            memo: record.memo,
            // 태그는 v9 부터 wishTag 가 원본이다. wish.hashtag 컬럼은 대표 태그를 같이 적어 두기만 한다
            tags: tags.sorted { $0.order < $1.order }.map(\.name),
            isSuccess: record.isSuccess,
            finishNote: record.finishNote,
            pinnedAt: record.pinnedAt,
            link: record.link,
            lastCheckedAt: record.lastCheckedAt,
            place: WishPlace.stored(
                name: record.placeName,
                address: record.placeAddress,
                latitude: record.latitude,
                longitude: record.longitude
            ),
            photoFileName: record.photoFileName,
            futureLetter: record.futureLetter,
            futureLetterSealedAt: record.futureLetterSealedAt,
            manualOrder: record.manualOrder,
            previousWishId: record.previousWishId,
            startedAt: record.startedAt,
            createdAt: record.createdAt
        )
    }
}

extension Wish {
    /// 기간 기한은 이 기기의 기간 마지막 날로 맞추고, 기간 마지막 날이 아닌 마감은 날짜 기한으로 읽는다 (GH-118 R-11)
    fileprivate static func deadline(stored: String, endDate: Date?) -> (endDate: Date?, kind: DeadlineKind) {
        let kind = DeadlineKind(stored: stored)
        guard kind.isPeriod, let normalized = kind.normalizedEnd(endDate) else { return (endDate, .date) }
        return (normalized, kind)
    }
}
