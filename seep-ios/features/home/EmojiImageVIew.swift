import UIKit

class EmojiImageView: UIImageView {
  
  func bind(category: Category) {
    switch category {
    case .wantToDo:
      self.image = .emojiWantToDo
    case .wantToGet:
      self.image = .emojiWantToGet
    case .wantToGo:
      self.image = .emojiWantToGo
    }
  }
}
