import XCTest

import ISEmojiView

@testable import seep_ios_dev

final class SharePhotoLayoutTests: XCTestCase {
    /// 공유 버튼(50) + 하단 여백(24) + 위 간격(12). 테스트 뷰는 window 밖이라 safe area가 0이다.
    private let shareButtonArea: CGFloat = 50 + 24 + 12

    private func layoutView(size: CGSize) -> SharePhotoView {
        let view = SharePhotoView(frame: CGRect(origin: .zero, size: size))
        // layoutSubviews에서 셀 크기·최소 높이 제약을 갱신하므로 두 번 배치한다.
        view.layoutIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view
    }

    // MARK: GH-13 TC6

    func test_GH13_TC6_목록폭에따라_3_4_5열정사각형셀이된다() {
        // Given
        let cases: [(width: CGFloat, columns: CGFloat)] = [(402, 3), (700, 4), (892, 5)]

        for (width, columns) in cases {
            // When
            let size = SharePhotoCell.size(containerWidth: width)

            // Then
            XCTAssertEqual(size.width, size.height, "width \(width)")
            let rowWidth = size.width * columns + SharePhotoCell.spacing * (columns - 1)
            XCTAssertLessThanOrEqual(rowWidth, width, "width \(width)")
            let oneMoreColumn = size.width * (columns + 1) + SharePhotoCell.spacing * columns
            XCTAssertGreaterThan(oneMoreColumn, width, "width \(width)")
        }
    }

    // MARK: GH-13 TC7

    func test_GH13_TC7_듀오안쪽시트에서_카드는시트안정사각형이고_사진목록이한줄이상보인다() {
        // Given
        let sheetSize = CGSize(width: 892, height: 620)

        // When
        let view = layoutView(size: sheetSize)

        // Then
        let card = view.photoContainer.frame
        XCTAssertEqual(card.width, card.height, accuracy: 0.5)
        XCTAssertGreaterThan(card.width, 0)
        XCTAssertLessThanOrEqual(card.maxX, sheetSize.width)
        XCTAssertGreaterThanOrEqual(card.minX, 0)
        XCTAssertEqual(card.midX, sheetSize.width / 2, accuracy: 0.5)

        let cellHeight = SharePhotoCell.size(containerWidth: sheetSize.width).height
        let list = view.collectionView.frame
        XCTAssertLessThanOrEqual(list.maxY, sheetSize.height + 0.5)
        XCTAssertGreaterThanOrEqual(list.height - shareButtonArea, cellHeight - 0.5)
        XCTAssertGreaterThanOrEqual(view.shareTypeSwitchButton.frame.minY, card.maxY - 0.5)
        XCTAssertLessThanOrEqual(view.shareTypeSwitchButton.frame.maxY, view.shareButton.frame.minY)
    }

    func test_GH13_TC7_큰사진을골라도_카드크기가시트를넘지않는다() {
        // Given
        let sheetSize = CGSize(width: 892, height: 620)
        let view = layoutView(size: sheetSize)
        let cardBefore = view.photoContainer.frame
        let bigImage = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1200)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
        }

        // When
        view.setCollectionViewHidden(by: .photo)
        view.imageView.image = bigImage
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Then
        XCTAssertEqual(view.photoContainer.frame, cardBefore)
    }

    // MARK: GH-13 TC8

    func test_GH13_TC8_아이폰18Pro시트에서_카드는기존처럼폭과같은정사각형이다() {
        // Given
        let sheetSize = CGSize(width: 402, height: 800)

        // When
        let view = layoutView(size: sheetSize)

        // Then
        let card = view.photoContainer.frame
        XCTAssertEqual(card.width, 402, accuracy: 0.5)
        XCTAssertEqual(card.height, 402, accuracy: 0.5)
        XCTAssertEqual(card.minX, 0, accuracy: 0.5)
    }

    // MARK: 공유 이모지 탭 키보드 (NO-ISSUE)

    func test_공유이모지탭_키보드가공유버튼위를채우고_카드는기존폭을유지한다() {
        // Given / When
        let view = layoutView(size: CGSize(width: 402, height: 780))
        let keyboard = view.emojiCollectionView.subviews.first { $0 is EmojiView }

        // Then
        XCTAssertNotNil(keyboard)
        XCTAssertEqual(view.photoContainer.frame.width, 402)
        let keyboardBottom = view.emojiCollectionView.convert(keyboard?.frame ?? .zero, to: view).maxY
        XCTAssertEqual(keyboardBottom, view.shareButton.frame.minY - 12, accuracy: 0.5)
        XCTAssertGreaterThan(keyboard?.frame.height ?? 0, 0)
    }

    func test_공유이모지탭_이모지를고르면_카드이모지가바뀐다() {
        // Given
        let view = layoutView(size: CGSize(width: 402, height: 780))
        guard let keyboard = view.emojiCollectionView.subviews.first(where: { $0 is EmojiView }) as? EmojiView else {
            return XCTFail("이모지 키보드가 없다")
        }

        // When
        view.emojiViewDidSelectEmoji("😍", emojiView: keyboard)

        // Then
        XCTAssertEqual(view.emojiLabel.text, "😍")
    }
}
