import UIKit

struct FeedbackUtils {
  
  static let feedbackInstance = FeedbackGenerator()
}

class FeedbackGenerator: UIImpactFeedbackGenerator {
  
  override init() {
    super.init(style: .light)
    self.prepare()
  }
}
