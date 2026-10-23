import Foundation
import CoreGraphics

/// 사진 공유 화면 배치 규칙 (GH-13 TC6~TC8). 화면 크기가 아니라 화면이 받은 컨테이너 크기로 계산한다
enum SharePhotoLayout {
    /// 사진 칸 사이 간격
    static let gridSpacing: CGFloat = 1
    static let emojiFontSize: CGFloat = 150
    /// 기존 아이폰 카드(375pt)에서 이모지 150pt 비율. 카드가 줄어들 때 이모지가 D-day·제목을 덮지 않게 같이 줄인다
    static let emojiFontRatio: CGFloat = 150 / 375
    static let shareButtonHeight: CGFloat = 50
    static let shareButtonBottomOffset: CGFloat = 24
    static let shareButtonTopSpacing: CGFloat = 12
    /// 카드 위 여백 10. 제목·닫기는 시스템 내비게이션 바라 컨테이너 크기에 들어가지 않는다 (GH-64 P4)
    static let headerHeight: CGFloat = 10
    static let switchHeight: CGFloat = 42

    /// 공유 버튼이 가리는 아래 영역. 사진·이모지 목록 아래 여백으로 쓴다
    static func shareButtonArea(bottomSafeArea: CGFloat) -> CGFloat {
        shareButtonHeight + shareButtonBottomOffset + shareButtonTopSpacing + bottomSafeArea
    }

    /// 목록 폭에 따라 3·4·5열 정사각형 칸. 넓은 화면(듀오 안쪽 등)에서는 열을 늘려 칸이 과하게 커지지 않게 한다
    static func columnCount(containerWidth: CGFloat) -> Int {
        switch containerWidth {
        case ..<600: return 3
        case ..<800: return 4
        default: return 5
        }
    }

    static func cellSide(containerWidth: CGFloat) -> CGFloat {
        let columns = CGFloat(columnCount(containerWidth: containerWidth))
        return max(0, floor((containerWidth - gridSpacing * (columns - 1)) / columns))
    }

    /// 카드는 폭 기준 정사각형. 높이가 낮으면(듀오 안쪽 등) 공유 버튼에 가리지 않는 사진 목록이 한 줄은 남게 줄어든다
    static func cardSide(containerSize: CGSize, bottomSafeArea: CGFloat = 0) -> CGFloat {
        let listMinHeight = cellSide(containerWidth: containerSize.width) + shareButtonArea(bottomSafeArea: bottomSafeArea)
        let availableHeight = containerSize.height - headerHeight - switchHeight - listMinHeight
        return max(0, min(containerSize.width, availableHeight))
    }

    static func emojiFontSize(cardSide: CGFloat) -> CGFloat {
        min(emojiFontSize, floor(cardSide * emojiFontRatio))
    }
}
