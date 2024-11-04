import UIKit

final class TagLabel: PaddingLabel {
    init() {
        super.init(topInset: 3, bottomInset: 1, leftInset: 6, rightInset: 6)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        font = UIFont.appleBold(size: 11)
        textColor = UIColor(r: 153, g: 153, b: 153)
        backgroundColor = UIColor(r: 241, g: 241, b: 241)
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
}
