import CoreGraphics

/// 홈 화면 크기 규칙
enum HomeLayout {
    /// 넓은 화면(듀오 안쪽)에서 콘텐츠를 가두는 기둥 폭 (GH-12)
    static let maxContentWidth: CGFloat = SeepLayout.maxContentWidth
    /// 리스트·그리드 좌우 여백 (디자인 시스템 space-page)
    static let horizontalInset: CGFloat = 20
    /// 리스트 셀 높이·사이 간격
    static let listRowHeight: CGFloat = 70
    static let listSpacing: CGFloat = 10
}

/// 헤드라인 영역 (GH-10 TC7)
enum HomeHeaderLayout {
    /// 헤드라인 왼쪽 여백 (space-header)
    static let headlineLeading: CGFloat = 22
    static let illustrationSize: CGFloat = 100
    /// 일러스트는 safe area 안쪽 오른쪽에서 20pt — 듀오 바깥 화면의 센서 영역과 겹치지 않는다 (GH-10)
    static let illustrationTrailingInset: CGFloat = 20
    /// 일러스트는 10도 기울어져 있다
    static let illustrationRotationDegrees: Double = 10
}

/// 그리드 열 수·셀 크기 (GH-11). 입력은 콘텐츠 폭 - 좌우 여백(20 * 2)
enum HomeGridLayout {
    static let spacing: CGFloat = 15
    static let heightRatio: CGFloat = 1.09
    /// 한 열에 이 폭이 확보될 때마다 열을 늘린다. 셀 폭이 아이폰(약 174pt)과 비슷하게 유지되는 값.
    /// 사용 가능 폭 540pt부터 3열 — 아이폰·듀오 바깥은 2열, 듀오 안쪽(폭 600 제한 시 560)은 3열
    static let columnWidthUnit: CGFloat = 180
    static let minimumColumnCount = 2

    static func columnCount(availableWidth: CGFloat) -> Int {
        guard availableWidth > 0 else { return minimumColumnCount }
        return max(minimumColumnCount, Int(availableWidth / columnWidthUnit))
    }

    static func itemSize(availableWidth: CGFloat) -> CGSize {
        let columnCount = CGFloat(columnCount(availableWidth: availableWidth))
        let width = max(0, (availableWidth - spacing * (columnCount - 1)) / columnCount)
        return CGSize(width: width, height: width * heightRatio)
    }

    /// 사진이 있는 셀 (GH-36 R-6)
    enum Photo {
        static let height: CGFloat = 92
        static let emojiCircleSize: CGFloat = 34
        static let emojiFontSize: CGFloat = 19
        /// 사진 아래 모서리에 원의 절반쯤 걸치게 둔다
        static let emojiCircleOverlap: CGFloat = 18
        /// 세로 사진(3:4)도 aspect fill 로 흐리지 않게 셀 폭보다 조금 크게 디코딩한다 (R-8)
        static let thumbnailScale: CGFloat = 4.0 / 3.0
    }
}

/// 카테고리 탭 줄 배치 (GH-11, GH-12 TC6). 탭 줄은 최대 400pt 에 왼쪽 정렬하고,
/// 그 안에서 좌우 여백 20을 뺀 폭에 탭을 양끝 맞춰 같은 간격으로 놓는다 — 넓은 화면에서 간격이 벌어지지 않는다
enum HomeCategoryTabLayout {
    static let maxRowWidth: CGFloat = 400
    static let horizontalMargin: CGFloat = 20

    /// 각 탭의 가로 시작 위치(탭 줄 왼쪽 기준)
    static func tabOrigins(containerWidth: CGFloat, tabWidths: [CGFloat]) -> [CGFloat] {
        guard !tabWidths.isEmpty else { return [] }
        let rowWidth = min(containerWidth, maxRowWidth)
        let innerWidth = rowWidth - horizontalMargin * 2
        let totalTabWidth = tabWidths.reduce(0, +)
        let gap = tabWidths.count > 1
            ? max(0, (innerWidth - totalTabWidth) / CGFloat(tabWidths.count - 1))
            : 0

        var origins: [CGFloat] = []
        var x = horizontalMargin
        for width in tabWidths {
            origins.append(x)
            x += width + gap
        }
        return origins
    }
}
