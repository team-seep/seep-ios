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
    /// 목표 금액(원). 0 이면 저금통 없음 (GH-16)
    var targetAmount: Int
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
    var order: Int
    var updatedAt: Date
    var deletedAt: Date?

    enum Columns {
        static let wishId = Column(CodingKeys.wishId)
        static let deletedAt = Column(CodingKeys.deletedAt)
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
        self.createdAt = wish.createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
    }
}

extension WishStepRecord {
    init(step: WishStep, wishId: String, updatedAt: Date) {
        self.id = step.id
        self.wishId = wishId
        self.title = step.title
        self.isDone = step.isDone
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
        journals: [WishJournalRecord] = []
    ) {
        self.init(
            id: record.id,
            emoji: record.emoji,
            category: Category(rawValue: record.category) ?? .wantToDo,
            title: record.title,
            endDate: record.date,
            finishDate: record.finishDate,
            notifications: notifications
                .sorted { $0.order < $1.order }
                .map { SeepNotification(id: $0.id, type: .init(rawValue: $0.type) ?? .targetDay, time: $0.time) },
            steps: steps
                .map { WishStep(id: $0.id, title: $0.title, isDone: $0.isDone, order: $0.order) }
                .sorted { $0.order < $1.order },
            targetAmount: record.targetAmount,
            savings: WishSaving.latestFirst(savings.map { WishSaving(id: $0.id, amount: $0.amount, createdAt: $0.createdAt) }),
            journals: WishJournal.latestFirst(journals.map { WishJournal(id: $0.id, text: $0.text, createdAt: $0.createdAt) }),
            memo: record.memo,
            hashtag: record.hashtag,
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
            createdAt: record.createdAt
        )
    }
}
