import CoreGraphics

/// 화면 공통 크기 규칙 (GH-12 넓은 화면)
/// 화면 폭이 `maxContentWidth` 이하면(아이폰 전 기종) 화면 전체를 쓰고,
/// 넘으면 콘텐츠를 `maxContentWidth` 기둥으로 가운데 둔다. 기둥 안 좌우 여백(20pt)은 각 화면 그대로.
enum SeepLayout {
    /// 넓은 화면(듀오 안쪽·아이패드)에서 콘텐츠를 가두는 기둥 폭
    static let maxContentWidth: CGFloat = 600

    /// 카테고리 탭 줄 최대 폭. 가장 넓은 아이폰(Pro Max 440pt) 탭 줄 폭(440 - 40)에 맞춰
    /// 아이폰에서는 그대로 두고, 그보다 넓으면 탭 간격이 더 벌어지지 않게 한다
    static let maxCategoryTabWidth: CGFloat = 400

    static func contentWidth(containerWidth: CGFloat) -> CGFloat {
        min(max(containerWidth, 0), maxContentWidth)
    }

    static func horizontalInset(containerWidth: CGFloat) -> CGFloat {
        max(0, (containerWidth - maxContentWidth) / 2)
    }
}
