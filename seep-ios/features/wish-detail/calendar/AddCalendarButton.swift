import UIKit

/// 위시 상세 "날짜" 라벨 줄 오른쪽의 텍스트 버튼 (GH-28). 추가 전 `seepBlue` ＋, 추가 후 `gray4` ✓.
final class AddCalendarButton: UIButton {
    static let height: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        bind(isAdded: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(isAdded: Bool) {
        let color: UIColor = isAdded ? .gray4 : .seepBlue
        let title = isAdded ? Strings.Detail.Calendar.added : Strings.Detail.Calendar.add
        let symbolName = isAdded ? "checkmark" : "plus"

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        )
        configuration.imagePadding = 4
        configuration.baseForegroundColor = color
        // 글자는 "날짜" 라벨 줄 끝에 맞추고, 터치 영역은 버튼 높이(44)로 넓힌다
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
        var attributedTitle = AttributedString(title)
        attributedTitle.font = .appleRegular(size: 14)
        attributedTitle.foregroundColor = color
        configuration.attributedTitle = attributedTitle

        self.configuration = configuration
        accessibilityLabel = title
    }
}
