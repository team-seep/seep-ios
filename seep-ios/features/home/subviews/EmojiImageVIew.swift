import UIKit

final class EmojiImageView: UIImageView {
    init() {
        super.init(frame: .zero)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        transform = .init(rotationAngle: CGFloat(10 * CGFloat.pi / 180))
    }
    
    func bind(category: Category) {
        switch category {
        case .wantToDo:
            let randomIndex = Int.random(in: 1...12)
            image = UIImage(named: "img_category_do_\(randomIndex)")
        case .wantToGet:
            let randomIndex = Int.random(in: 1...10)
            image = UIImage(named: "img_category_get_\(randomIndex)")
        case .wantToGo:
            let randomIndex = Int.random(in: 1...10)
            image = UIImage(named: "img_category_go_\(randomIndex)")
        }
    }
}
