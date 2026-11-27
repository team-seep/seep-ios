// swiftlint:disable file_length - 작성·수정 문서 하나의 블록·검증·저장 규칙(사진 파일 커밋 포함)을 한 ViewModel 에 둔다
import Foundation
import Observation

/// 위시 작성·수정 문서 (GH-64 P2, GH-70). 레거시 `WriteReactor`·`WishEditReactor`와 단계·링크·장소 섹션 ViewModel 의
/// 작성·수정 동작을 하나로 옮겼다. 저장 규칙(카테고리별로 버리는 값, 고정 해제 등)은 레거시와 같다
@Observable
// swiftlint:disable:next type_body_length - 작성·수정 문서 하나의 입력·검증·저장 규칙을 한 곳에 둔다(블록·링크·단계가 서로 상태를 공유)
final class WishFormViewModel {
    static let titleMaxLength = 18
    static let memoMaxLength = 300
    static let customHashtagMaxLength = WishTagSelection.customMaxLength
    /// 태그 시트에 보일 '전에 쓴 태그' 수
    static let recentTagLimit = 8

    private(set) var state: State
    private(set) var route: Route?

    let screenName: ScreenName
    private let config: Config
    private let dependency: Dependency
    private var hasSentLinkPreviewImpression = false
    private var linkPreviewTask: Task<Void, Never>?
    /// 고른 사진을 파일로 쓰는 중. 두 번 눌러 위시가 두 개 생기지 않게 한다
    private var isSaving = false
    /// 열었을 때의 입력값. 닫을 때 바뀐 게 있는지 본다 (GH-70 R-18)
    private var initialDraft: WishFormDraft?
    /// 이름은 있는데 이 기기에 파일이 아직 없는 사진(다른 기기에서 붙여 내려받기 전, GH-93 R-41).
    /// 화면엔 없는 것으로 보이지만, 사용자가 사진을 건드리지 않고 저장하면 이름을 그대로 둔다. 비우면 다른 기기의 사진까지 사라진다
    private var photoNotYetDownloaded: String?
    /// 사진 속 글자 읽기 차례. 사진을 빼거나 바꾸면 늘려서 앞 사진의 늦은 결과를 버린다 (GH-144 R-6)
    private var photoTextRequestId = 0
    /// 칩 줄 노출 로그는 사진마다 한 번 (GH-144 트래킹)
    private var hasSentPhotoTextImpression = false

    init(config: Config, dependency: Dependency = Dependency()) {
        self.config = config
        self.dependency = dependency
        switch config.mode {
        case .add(let category):
            screenName = .write
            // 날짜·알림은 칩으로 꺼낼 때만 켠다 (GH-70 R-7)
            state = State(
                category: category,
                isDeadlineEnabled: false,
                isNotificationEnabled: false,
                currency: dependency.defaultCurrency(),
                saveButtonState: .initial
            )
        case .edit(let wish):
            screenName = .wishEdit
            state = State(
                emoji: wish.emoji,
                category: wish.category,
                title: wish.title,
                deadline: wish.endDate,
                deadlineKind: wish.endDate == nil ? .date : wish.deadlineKind,
                isDeadlineEnabled: wish.endDate != nil,
                notifications: wish.notifications.isEmpty ? [SeepNotification()] : wish.notifications,
                isNotificationEnabled: !wish.notifications.isEmpty,
                memo: wish.memo,
                steps: wish.steps,
                targetAmount: wish.targetAmount,
                targetAmountText: AmountFormatter.inputText(from: wish.targetAmount, currency: wish.currency),
                currency: wish.currency,
                isCurrencyLocked: !wish.savings.isEmpty,
                linkText: wish.link,
                link: WishLinkInput(text: wish.link),
                place: wish.place,
                // 파일이 없으면(백업 복원 등) 사진이 없는 것으로 본다 (GH-36 R-7)
                photo: dependency.photoStorage.photoURL(fileName: wish.photoFileName) == nil
                    ? .none : .stored(fileName: wish.photoFileName),
                letter: wish.hasFutureLetter
                    ? WishFormLetter(text: wish.futureLetter, sealedAt: wish.futureLetterSealedAt) : nil,
                tagSelection: WishTagSelection(tags: wish.tags),
                saveButtonState: .active
            )
            state.saveButtonState = validatedButtonState()
            // 값이 있는 블록만 펼친 채 시작한다 (GH-70 R-15)
            var revealed: Set<WishDocumentBlock> = []
            if !wish.memo.isEmpty { revealed.insert(.memo) }
            if !wish.steps.isEmpty { revealed.insert(.steps) }
            if !wish.link.isEmpty { revealed.insert(.link) }
            if wish.targetAmount > 0 { revealed.insert(.targetAmount) }
            state.revealedBlocks = revealed
            if !wish.photoFileName.isEmpty, dependency.photoStorage.photoURL(fileName: wish.photoFileName) == nil {
                photoNotYetDownloaded = wish.photoFileName
            }
        }
        initialDraft = draft
    }

    private var isEditMode: Bool {
        if case .edit = config.mode { return true }
        return false
    }

    /// 장소는 작성 화면에서만 고른다. 수정 화면은 상세에서 바꾼다 (GH-31 R-10)
    var isPlaceVisible: Bool {
        !isEditMode && state.category == .wantToGo
    }

    var isEditing: Bool { isEditMode }

    // MARK: 문서 블록 (GH-70)

    /// 지금 카테고리·날짜에서 쓸 수 있는 칸인지 (R-6, R-8)
    func isAvailable(_ block: WishDocumentBlock) -> Bool {
        switch block {
        case .date, .memo, .steps, .photo, .letter: return true
        case .notification: return state.isDeadlineEnabled && state.deadline != nil
        case .link, .targetAmount: return state.category == .wantToGet
        case .place: return isPlaceVisible
        }
    }

    func isRevealed(_ block: WishDocumentBlock) -> Bool {
        switch block {
        case .date: return state.isDeadlineEnabled
        case .notification: return state.isNotificationEnabled
        case .place: return state.place != nil
        case .photo: return state.photo != .none
        case .letter: return state.letter != nil
        case .memo, .steps, .link, .targetAmount: return state.revealedBlocks.contains(block)
        }
    }

    /// 문서에 보이는 블록, 놓는 순서대로 (R-5)
    var visibleBlocks: [WishDocumentBlock] {
        WishDocumentBlock.documentOrder.filter { isAvailable($0) && isRevealed($0) }
    }

    /// 하단 더하기 칩. 아직 안 꺼냈고 쓸 수 있는 칸만 (R-6)
    var chips: [WishDocumentBlock] {
        WishDocumentBlock.allCases.filter { isAvailable($0) && !isRevealed($0) }
    }

    /// 사진 블록 미리보기 (GH-61 R-10)
    var photoPreview: WishFormPhotoPreview? {
        switch state.photo {
        case .none: return nil
        case .stored(let fileName): return dependency.photoStorage.photoURL(fileName: fileName).map { .file($0) }
        case .picked(let data): return .data(data)
        }
    }

    /// 봉인 카드 캡션. 이번에 봉인한 편지는 오늘 날짜로 보인다 (GH-61 R-10)
    var letterCaption: String? {
        guard let letter = state.letter else { return nil }
        return DetailLetter.sealedCaption(sealedAt: letter.sealedAt ?? dependency.now(), length: letter.text.count)
    }

    /// 언제까지 시트 항목. 오른쪽 마감은 지금 고르면 저장될 날짜다 (GH-118 R-3)
    var deadlineOptionRows: [WishDeadlineOptionRow] {
        WishDeadlineOptionRow.rows(isDeadlineEnabled: state.isDeadlineEnabled, kind: state.deadlineKind, now: dependency.now())
    }

    /// 열었을 때와 입력이 달라졌는지 (R-18)
    var hasChanges: Bool {
        draft != initialDraft
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            handleAppear()
        case .hideTooltip:
            state.isTooltipVisible = false
        case .tapEmoji:
            state.sheet = .emoji
        case .selectEmoji(let emoji):
            state.emoji = emoji
            state.sheet = nil
        case .tapRandomEmoji:
            state.emoji = dependency.randomEmoji()
        case .selectCategory(let category):
            state.category = category
            updateButtonState()
            // 갖고 싶어요로 바꾸면 금액 칩이 처음 보일 수 있다 (GH-144 R-5)
            sendPhotoTextImpressionIfNeeded()
        case .inputTitle(let title):
            inputTitle(title)
        case .tapDate:
            // 날짜가 꺼져 있으면 켜면서 연다 (GH-70 R-6 날짜 칩과 같음)
            state.isDeadlineEnabled = true
            if state.deadline == nil {
                state.deadline = dependency.now().endOfDay
                state.deadlineKind = .date
            }
            state.deadlineError = nil
            state.sheet = .date
        case .inputDeadline(let date):
            state.deadline = date.endOfDay
            state.deadlineKind = .date
            state.deadlineError = nil
        case .selectDeadlineOption(let option):
            selectDeadlineOption(option)
        case .toggleDeadline(let isEnabled):
            state.isDeadlineEnabled = isEnabled
            state.deadlineError = nil
            state.isNotificationEnabled = isEnabled
        case .toggleNotification(let isEnabled):
            toggleNotification(isEnabled)
        case .tapAddNotification:
            guard state.isNotificationEnabled else { return }
            state.sheet = .notification(NotificationEditorConfig(notifications: state.notifications, selectedIndex: nil))
        case .tapNotification(let index):
            guard state.isNotificationEnabled, state.notifications.indices.contains(index) else { return }
            state.sheet = .notification(NotificationEditorConfig(notifications: state.notifications, selectedIndex: index))
        case .saveNotification(let notification, let index):
            if let index, state.notifications.indices.contains(index) {
                state.notifications[index] = notification
            } else {
                state.notifications.append(notification)
            }
            state.sheet = nil
        case .deleteNotification(let index):
            if state.notifications.indices.contains(index) {
                state.notifications.remove(at: index)
            }
            state.sheet = nil
        case .inputMemo(let memo):
            if memo.count > Self.memoMaxLength {
                state.memo = String(memo.prefix(Self.memoMaxLength))
            } else {
                state.memo = memo
            }
            state.memoError = memo.count >= Self.memoMaxLength ? Strings.writeErrorMaxLengthMemo : nil
        case .tapAddStep:
            guard state.isAddStepEnabled else {
                route = .toast(Strings.Detail.Step.Toast.maxCount)
                return
            }
            route = .addStepAlert
        case .addStep(let title):
            addStep(title: title)
        case .deleteStep(let index):
            deleteStep(index: index)
        case .inputTargetAmount(let text):
            let input = AmountFormatter.input(text, currency: state.currency)
            state.targetAmountText = input.text
            state.targetAmount = input.amount
        case .selectCurrency(let currency):
            selectCurrency(currency)
        case .inputLink(let text):
            updateLink(text: text)
        case .pasteLink(let text):
            sendClickLog(objectType: .button, objectId: .pasteWishLink)
            updateLink(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        case .tapPlace:
            sendClickLog(objectType: .button, objectId: .addPlace)
            state.sheet = .placeSearch
        case .selectPlace(let place):
            state.place = place
            state.sheet = nil
        case .deletePlace:
            state.place = nil
        case .selectHashtag(let hashtag):
            let didChange = state.tagSelection.toggle(hashtag)
            state.tagError = didChange ? nil : Strings.WishDocument.HashtagSheet.maxCountFormat(WishTagSelection.maxCount)
        case .inputCustomHashtag(let text):
            inputCustomHashtag(text)
        case .submitCustomHashtag:
            commitCustomTagInput()
        case .removeTag(let tag):
            state.tagSelection.remove(tag)
            state.tagError = nil
        case .selectRecentTag(let tag):
            addTag(tag)
        case .tapSave:
            save()
        case .tapClose:
            guard !hasChanges else {
                route = .confirmDiscard
                return
            }
            linkPreviewTask?.cancel()
            route = .finish(nil)
        case .confirmDiscard:
            sendClickLog(objectType: .button, objectId: .discardWrite)
            linkPreviewTask?.cancel()
            route = .finish(nil)
        case .dismissSheet:
            // 태그 시트를 '확인'·끌어내리기로 닫으면 치다 만 직접 입력도 태그로 넣는다 (GH-136 R-2)
            if state.sheet == .hashtag {
                commitCustomTagInput()
            }
            state.sheet = nil
        case .routeHandled:
            route = nil
        case .tapChip(let block):
            tapChip(block)
        case .removeBlock(let block):
            removeBlock(block)
        case .tapHashtag:
            state.recentCustomTags = Array(dependency.wishRepository.fetchRecentCustomTags().prefix(Self.recentTagLimit))
            state.sheet = .hashtag
        case .pickPhoto(let data):
            state.photo = .picked(data)
            photoNotYetDownloaded = nil
            recognizePhotoText(data)
        case .pickPhotoFailed:
            route = .toast(WishPhotoStorageError.invalidImage.localizedDescription)
        case .tapPhoto:
            route = .photoPicker
        case .sealLetter(let text):
            state.letter = WishFormLetter(text: text, sealedAt: nil)
            state.sheet = nil
        case .tapLetter:
            route = .rewriteLetterAlert
        case .confirmRewriteLetter:
            presentLetterSheet()
        case .tapPhotoTextTitle(let title):
            fillTitleFromPhotoText(title)
        case .tapPhotoTextAmount:
            fillAmountFromPhotoText()
        }
    }

    // MARK: 블록 (GH-70)

    private func tapChip(_ block: WishDocumentBlock) {
        guard isAvailable(block) else { return }
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .addBlock,
            extraParameters: [.block: block.rawValue]
        ))
        switch block {
        case .date:
            send(.tapDate)
        case .notification:
            state.isNotificationEnabled = true
            if state.notifications.isEmpty {
                state.notifications = [SeepNotification()]
            }
        case .memo:
            state.revealedBlocks.insert(.memo)
            route = .focus(.memo)
        case .link:
            state.revealedBlocks.insert(.link)
            route = .focus(.link)
        case .targetAmount:
            state.revealedBlocks.insert(.targetAmount)
            route = .focus(.targetAmount)
        case .steps:
            state.revealedBlocks.insert(.steps)
            send(.tapAddStep)
        case .place:
            send(.tapPlace)
        case .photo:
            route = .photoPicker
        case .letter:
            presentLetterSheet()
        }
    }

    /// 다시 쓰기도 빈 칸에서 시작한다 (GH-61 R-4)
    private func presentLetterSheet() {
        let sheet = FutureLetterViewModel(dependency: .init(logManager: dependency.logManager))
        sheet.onSeal = { [weak self] text in
            self?.send(.sealLetter(text))
        }
        state.sheet = .letter(sheet)
    }

    private func removeBlock(_ block: WishDocumentBlock) {
        switch block {
        case .date:
            // 알림은 날짜가 있어야 한다 — 같이 끈다 (R-7)
            state.isDeadlineEnabled = false
            state.deadline = nil
            state.deadlineKind = .date
            state.deadlineError = nil
            state.isNotificationEnabled = false
            state.sheet = nil
        case .notification:
            state.isNotificationEnabled = false
            state.notifications = [SeepNotification()]
        case .memo:
            state.memo = ""
            state.memoError = nil
        case .steps:
            state.steps = []
        case .link:
            updateLink(text: "")
        case .targetAmount:
            state.targetAmount = 0
            state.targetAmountText = ""
        case .place:
            state.place = nil
        case .photo:
            state.photo = .none
            photoNotYetDownloaded = nil
            // 칩만 지우고 이미 채운 값은 그대로 둔다 (GH-144 R-6)
            clearPhotoText()
        case .letter:
            state.letter = nil
        }
        state.revealedBlocks.remove(block)
    }

    /// 저금 기록이 있으면 통화를 바꾸지 않는다. 기록 금액의 뜻이 바뀌기 때문이다 (GH-103 R-18)
    private func selectCurrency(_ currency: String) {
        guard !state.isCurrencyLocked else {
            route = .toast(Strings.Write.TargetAmount.currencyLocked)
            return
        }
        guard currency != state.currency, AmountFormatter.supportedCurrencies.contains(currency) else { return }
        state.currency = currency
        // 소수 자릿수가 달라지므로 칸의 글자를 새 통화로 다시 읽는다
        let input = AmountFormatter.input(state.targetAmountText, currency: currency)
        state.targetAmountText = input.text
        state.targetAmount = input.amount
    }

    private var draft: WishFormDraft {
        WishFormDraft(
            emoji: state.emoji,
            category: state.category,
            title: state.title,
            deadline: state.isDeadlineEnabled ? state.deadline : nil,
            deadlineKind: state.isDeadlineEnabled ? state.deadlineKind : .date,
            notifications: state.isNotificationEnabled ? state.notifications : [],
            memo: state.memo,
            steps: state.steps,
            targetAmount: state.targetAmount,
            currency: state.currency,
            linkText: state.linkText,
            place: state.place,
            photo: state.photo,
            letter: state.letter,
            tags: state.tagSelection.tags
        )
    }

    // MARK: 입력

    private func handleAppear() {
        if !isEditMode, !dependency.userDefaults.getRandomEmojiTooltipIsShow() {
            state.isTooltipVisible = true
            dependency.userDefaults.setRandomEmojiTooltipIsShow(isShown: true)
        }
        // 수정: 저장된 링크의 미리보기를 캐시에서 먼저 찾는다 (GH-29 R-5)
        if case .edit(let wish) = config.mode, let link = state.link.link {
            loadStoredPreview(wishId: wish.id, link: link)
        }
    }

    private func inputTitle(_ title: String) {
        // 18자를 넘게 들어오면 자르고, 18자에 닿으면 안내한다 (레거시 shouldChangeCharacters)
        let limited = String(title.prefix(Self.titleMaxLength))
        state.title = limited
        state.titleError = title.count >= Self.titleMaxLength ? Strings.writeErrorMaxLengthTitle : nil
        updateButtonState()
    }

    /// 기간을 고르면 그 기간의 마지막 날을 마감으로 넣고 시트를 닫는다. 날짜 정하기는 달력을 연다 (GH-118 R-2, R-3)
    private func selectDeadlineOption(_ option: WishDeadlineOption) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .selectDeadlineKind,
            extraParameters: [.type: option.rawValue]
        ))
        switch option {
        case .date:
            state.isDeadlineEnabled = true
            if state.deadline == nil {
                state.deadline = dependency.now().endOfDay
            }
            state.deadlineKind = .date
            state.deadlineError = nil
            state.sheet = .datePicker
        case .month, .year, .nextYear:
            state.isDeadlineEnabled = true
            state.deadline = option.deadlineKind.periodEnd(from: dependency.now())
            state.deadlineKind = option.deadlineKind
            state.deadlineError = nil
            state.sheet = nil
        case .someday:
            // 날짜 없애기와 같다 — 알림도 같이 꺼진다 (GH-70 R-7)
            removeBlock(.date)
        }
    }

    private func toggleNotification(_ isEnabled: Bool) {
        guard state.isDeadlineEnabled else {
            state.isNotificationEnabled = false
            route = .toast(Strings.WishForm.notificationRequiresDate)
            return
        }
        state.isNotificationEnabled = isEnabled
    }

    private func inputCustomHashtag(_ text: String) {
        state.customTagInput = String(text.prefix(Self.customHashtagMaxLength))
        state.tagError = text.count >= Self.customHashtagMaxLength ? Strings.writeErrorMaxLengthHashtag : nil
    }

    /// 친 글자를 태그 칩으로 넣는다. 최대 개수면 글자를 남기고 안내한다 (GH-136 R-2)
    private func commitCustomTagInput() {
        guard !state.customTagInput.isEmpty else { return }
        if addTag(state.customTagInput) {
            state.customTagInput = ""
        }
    }

    /// 직접 입력·추천 태그를 넣는다. 최대 개수라 못 넣었으면 false
    @discardableResult
    private func addTag(_ text: String) -> Bool {
        switch state.tagSelection.addCustom(text) {
        case .added, .duplicate, .empty:
            state.tagError = nil
            return true
        case .full:
            state.tagError = Strings.WishDocument.HashtagSheet.maxCountFormat(WishTagSelection.maxCount)
            return false
        }
    }

    // MARK: 단계 (GH-5)

    private func addStep(title: String) {
        guard state.isAddStepEnabled else {
            route = .toast(Strings.Detail.Step.Toast.maxCount)
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard trimmedTitle.count <= WishStep.maxTitleLength else {
            route = .toast(Strings.Detail.Step.Toast.maxLength)
            return
        }
        state.steps.append(WishStep(title: trimmedTitle, order: state.steps.count))
        sendClickLog(objectType: .button, objectId: .addStep)
    }

    private func deleteStep(index: Int) {
        guard state.steps.indices.contains(index) else { return }
        let removedId = state.steps[index].id
        state.steps = state.steps
            .filter { $0.id != removedId }
            .enumerated()
            .map { order, step in WishStep(id: step.id, title: step.title, isDone: step.isDone, order: order) }
    }

    // MARK: 링크 (GH-29)

    private func updateLink(text: String) {
        let previousLink = state.link.link
        let link = WishLinkInput(text: text)
        state.linkText = text
        state.link = link
        state.linkError = link == .invalid ? Strings.Write.Link.errorInvalid : nil
        updateButtonState()

        guard let validLink = link.link else {
            linkPreviewTask?.cancel()
            state.linkPreview = .hidden
            return
        }
        // 같은 링크에 공백만 붙었다 지워진 경우는 다시 부르지 않는다
        guard validLink != previousLink || state.linkPreview == .hidden else { return }
        state.linkPreview = .loading(domain: WishLinkInput.domain(of: validLink))
        schedulePreview(link: validLink)
    }

    private func schedulePreview(link: String) {
        linkPreviewTask?.cancel()
        guard let delay = dependency.linkPreviewDelay else {
            fetchPreview(link: link)
            return
        }
        linkPreviewTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, self.state.link.link == link else { return }
            self.fetchPreview(link: link)
        }
    }

    /// 수정: 캐시에 같은 링크가 있으면 네트워크 없이 보여준다 (GH-29 R-5)
    private func loadStoredPreview(wishId: String, link: String) {
        if let cached = dependency.linkPreviewCache.preview(wishId: wishId), cached.link == link {
            showPreview(.loaded(cached))
            return
        }
        state.linkPreview = .loading(domain: WishLinkInput.domain(of: link))
        fetchPreview(link: link)
    }

    private func fetchPreview(link: String) {
        dependency.linkMetadataProvider.fetchPreview(link: link) { [weak self] preview in
            guard let self else { return }
            // 응답이 오기 전에 링크가 바뀌었으면 버린다 (GH-29 R-3)
            guard self.state.link.link == link else { return }
            if let preview {
                self.showPreview(.loaded(preview))
            } else {
                self.showPreview(.failed(domain: WishLinkInput.domain(of: link)))
            }
        }
    }

    private func showPreview(_ preview: WishFormLinkPreview) {
        state.linkPreview = preview
        // 작성·수정 중 미리보기 카드가 처음 뜰 때 한 번만 (GH-29 TC-11)
        guard !hasSentLinkPreviewImpression else { return }
        hasSentLinkPreviewImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .wishLinkPreview
        ))
    }

    // MARK: 사진 속 글자 (GH-144)

    /// 새로 고른 사진만 읽는다. 저장된 사진을 열 때는 읽지 않는다 (R-1)
    private func recognizePhotoText(_ data: Data) {
        clearPhotoText()
        let requestId = photoTextRequestId
        dependency.photoTextRecognizer.recognizeText(imageData: data) { [weak self] lines in
            guard let self, self.photoTextRequestId == requestId else { return }
            let suggestion = PhotoTextSuggester.suggest(lines: lines, currentCurrency: self.state.currency)
            self.state.photoTextTitles = Self.photoTextChipTitles(suggestion.titles)
            self.state.photoTextAmount = suggestion.amount
            self.sendPhotoTextImpressionIfNeeded()
        }
    }

    /// 칩 글자 = 채울 글자. 제목 칸이 18자까지라 칩도 앞 18자로 보여 준다 (TC-12)
    private static func photoTextChipTitles(_ titles: [String]) -> [String] {
        var chips: [String] = []
        for title in titles {
            let chip = String(title.prefix(titleMaxLength)).trimmingCharacters(in: .whitespaces)
            if !chip.isEmpty, !chips.contains(chip) { chips.append(chip) }
        }
        return chips
    }

    private func clearPhotoText() {
        photoTextRequestId += 1
        hasSentPhotoTextImpression = false
        state.photoTextTitles = []
        state.photoTextAmount = nil
    }

    /// 제목이 비어 있지 않아도 바꾼다 — 사용자가 눌렀으니까 (R-4)
    private func fillTitleFromPhotoText(_ title: String) {
        guard state.photoTextTitles.contains(title) else { return }
        inputTitle(title)
        // 칩은 이미 18자 안으로 잘라 두었다 — 직접 치다 닿은 게 아니라 최대 길이 안내는 띄우지 않는다
        state.titleError = nil
        state.photoTextTitles = []
        didFillFromPhotoText(kind: "title")
    }

    /// 목표 금액 블록을 열고(열려 있으면 값만) 금액·통화를 넣는다 (R-5)
    private func fillAmountFromPhotoText() {
        guard let found = state.photoTextAmountChip else { return }
        state.revealedBlocks.insert(.targetAmount)
        state.currency = found.currency
        state.targetAmount = found.amount
        state.targetAmountText = AmountFormatter.inputText(from: found.amount, currency: found.currency)
        state.photoTextAmount = nil
        didFillFromPhotoText(kind: "amount")
    }

    private func didFillFromPhotoText(kind: String) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: .button,
            objectId: .fillFromPhotoText,
            extraParameters: [.kind: kind]
        ))
        route = .toast(Strings.WishDocument.PhotoText.filled)
    }

    private func sendPhotoTextImpressionIfNeeded() {
        guard !hasSentPhotoTextImpression, state.isPhotoTextSuggestionVisible else { return }
        hasSentPhotoTextImpression = true
        dependency.logManager.sendEvent(event: ImpressionEvent(
            screen: screenName,
            objectType: .card,
            objectId: .photoTextSuggestion,
            extraParameters: [.titleCount: state.photoTextTitles.count, .hasAmount: state.photoTextAmountChip != nil]
        ))
    }

    // MARK: 저장

    private func updateButtonState() {
        state.saveButtonState = validatedButtonState()
    }

    private func validatedButtonState() -> WishFormSaveButtonState {
        let isBlocked = state.title.isEmpty || state.link.blocksSave(category: state.category)
        guard isBlocked else { return .active }
        return isEditMode ? .more : .initial
    }

    private func save() {
        // 시트를 거치지 않고 저장해도 치다 만 태그를 잃지 않게 넣는다 (GH-136 R-2)
        commitCustomTagInput()
        var hasError = false
        if state.title.isEmpty {
            state.titleError = Strings.writeErrorTitleEmpty
            hasError = true
        }
        if state.isDeadlineEnabled && state.deadline == nil {
            state.deadlineError = Strings.writeErrorDateEmpty
            hasError = true
        }
        // 링크 형식 안내는 링크 칸이 이미 보여준다 (GH-29 R-2)
        guard !hasError, !state.link.blocksSave(category: state.category), !isSaving else { return }

        let wishId: String
        switch config.mode {
        case .add: wishId = UUID().uuidString
        case .edit(let original): wishId = original.id
        }
        switch state.photo {
        case .none:
            finishSave(wishId: wishId, photoFileName: photoNotYetDownloaded ?? "", newFileName: nil)
        case .stored(let fileName):
            finishSave(wishId: wishId, photoFileName: fileName, newFileName: nil)
        case .picked(let data):
            // 고른 사진은 파일로 먼저 쓰고 그 이름으로 위시를 저장한다 (GH-61 R-11, GH-36 R-3)
            isSaving = true
            dependency.photoStorage.savePhoto(imageData: data, wishId: wishId) { [weak self] result in
                guard let self else { return }
                isSaving = false
                switch result {
                case .success(let fileName):
                    finishSave(wishId: wishId, photoFileName: fileName, newFileName: fileName)
                case .failure(let error):
                    route = .toast(error.localizedDescription)
                }
            }
        }
    }

    private func finishSave(wishId: String, photoFileName: String, newFileName: String?) {
        let saved: Wish?
        switch config.mode {
        case .add:
            saved = addWish(id: wishId, photoFileName: photoFileName)
        case .edit(let original):
            saved = updateWish(original: original, photoFileName: photoFileName)
        }
        guard let saved else {
            // 위시에 붙이지 못한 파일은 남기지 않는다 (GH-36 R-3)
            if let newFileName { dependency.photoStorage.deletePhoto(fileName: newFileName) }
            return
        }
        if newFileName != nil {
            dependency.logManager.sendEvent(event: CustomEvent(screen: screenName, name: .savePhoto))
        }
        // 바꾸거나 지운 사진의 이전 파일은 저장이 끝난 뒤 지운다 (GH-61 R-11)
        if case .edit(let original) = config.mode,
           !original.photoFileName.isEmpty, original.photoFileName != saved.photoFileName {
            dependency.photoStorage.deletePhoto(fileName: original.photoFileName)
        }
        linkPreviewTask?.cancel()
        route = .finish(saved)
    }

    /// 편지 저장 값. 이번에 봉인한 편지는 저장 시각이 봉인일이다 (GH-61 R-11)
    private var letterToSave: (text: String, sealedAt: Date?) {
        guard let letter = state.letter else { return ("", nil) }
        return (letter.text, letter.sealedAt ?? dependency.now())
    }

    private func addWish(id: String, photoFileName: String) -> Wish? {
        let letter = letterToSave
        let wish = Wish(
            id: id,
            emoji: state.emoji.isEmpty ? dependency.randomEmoji() : state.emoji,
            category: state.category,
            title: state.title,
            endDate: state.isDeadlineEnabled ? state.deadline : nil,
            deadlineKind: state.isDeadlineEnabled ? state.deadlineKind : .date,
            notifications: state.isNotificationEnabled ? state.notifications : [],
            steps: state.steps,
            // 다른 카테고리로 바꿨으면 입력했던 목표 금액은 버린다 (GH-16 R-1)
            targetAmount: state.category == .wantToGet ? state.targetAmount : 0,
            currency: state.currency,
            memo: state.memo,
            tags: state.tagSelection.tags,
            // 다른 카테고리로 바꿨으면 링크도 버린다 (GH-29 R-1)
            link: state.link.storedLink(category: state.category),
            // 다른 카테고리로 바꿨으면 골랐던 장소는 버린다 (GH-31 R-1)
            place: state.category == .wantToGo ? state.place : nil,
            photoFileName: photoFileName,
            futureLetter: letter.text,
            futureLetterSealedAt: letter.sealedAt,
            previousWishId: config.previousWishId,
            createdAt: dependency.now()
        )

        switch dependency.wishRepository.addWish(wish) {
        case .success(let saved):
            dependency.notificationManager.reserveNotifications(wish: saved)
            dependency.logManager.sendEvent(event: ClickEvent(
                screen: .write,
                objectType: .button,
                objectId: .write,
                extraParameters: [.hasTargetAmount: saved.targetAmount > 0, .tagCount: saved.tags.count]
            ))
            if config.previousWishId != nil {
                sendClickLog(objectType: .button, objectId: .saveChainedWish)
            }
            return saved
        case .failure(let error):
            route = .toast(error.localizedDescription)
            return nil
        }
    }

    private func updateWish(original: Wish, photoFileName: String) -> Wish? {
        let letter = letterToSave
        let wish = Wish(
            id: original.id,
            emoji: state.emoji.isEmpty ? dependency.randomEmoji() : state.emoji,
            category: state.category,
            title: state.title,
            endDate: state.isDeadlineEnabled ? state.deadline : nil,
            deadlineKind: state.isDeadlineEnabled ? state.deadlineKind : .date,
            finishDate: original.finishDate,
            notifications: state.isNotificationEnabled ? state.notifications : [],
            steps: state.steps,
            // 다른 카테고리로 바꿨으면 목표 금액은 0 으로 저장하고 기록은 남긴다 (GH-16 R-1)
            targetAmount: state.category == .wantToGet ? state.targetAmount : 0,
            currency: state.currency,
            savings: original.savings,
            memo: state.memo,
            tags: state.tagSelection.tags,
            isSuccess: original.isSuccess,
            finishNote: original.finishNote,
            // 옮겨 간 카테고리의 고정 3개 제한을 넘지 않도록, 카테고리를 바꾸면 고정을 푼다 (GH-33 R-9)
            pinnedAt: state.category == original.category ? original.pinnedAt : nil,
            // 다른 카테고리로 바꿨으면 링크는 빈 문자열로 저장한다 (GH-29 R-1)
            link: state.link.storedLink(category: state.category),
            // 홈이 돌려받은 위시로 잠든 위시 카드를 다시 판단한다 (GH-30 R-2)
            lastCheckedAt: dependency.now(),
            // 수정 폼은 장소를 바꾸지 않는다 (GH-31 R-10). 사진·편지는 문서 블록 값 (GH-61 R-11)
            place: original.place,
            photoFileName: photoFileName,
            futureLetter: letter.text,
            futureLetterSealedAt: letter.sealedAt,
            previousWishId: original.previousWishId,
            // 수정 폼은 시작 상태를 바꾸지 않는다. 카테고리를 바꿔도 하는 중으로 남는다 (GH-143 R-7)
            startedAt: original.startedAt,
            createdAt: original.createdAt
        )

        switch dependency.wishRepository.updateWish(wish) {
        case .success(let saved):
            // 지운 알림까지 지우도록 수정 전 위시의 알림을 지우고 새로 예약한다
            dependency.notificationManager.cancelNotifications(wish: original)
            dependency.notificationManager.reserveNotifications(wish: saved)
            return saved
        case .failure(let error):
            route = .toast(error.localizedDescription)
            return nil
        }
    }

    private func sendClickLog(objectType: LogObjectType, objectId: LogObjectId) {
        dependency.logManager.sendEvent(event: ClickEvent(
            screen: screenName,
            objectType: objectType,
            objectId: objectId
        ))
    }
}

/// 버리기 확인에 쓰는 입력값 묶음
struct WishFormDraft: Equatable {
    let emoji: String
    let category: Category
    let title: String
    let deadline: Date?
    let deadlineKind: DeadlineKind
    let notifications: [SeepNotification]
    let memo: String
    let steps: [WishStep]
    let targetAmount: Int
    let currency: String
    let linkText: String
    let place: WishPlace?
    let photo: WishFormPhoto
    let letter: WishFormLetter?
    let tags: [String]
}
