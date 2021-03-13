import UIKit

class EmojiButton: UITextField {
  
  override var textInputContextIdentifier: String? {
    return ""
  }
  
  override var canBecomeFirstResponder: Bool { return true }
  
  override var canResignFirstResponder: Bool { return true }
  
  override var textInputMode: UITextInputMode? {
    for mode in UITextInputMode.activeInputModes {
      if mode.primaryLanguage == "emoji" {
        return mode
      }
    }
    return nil
  }
}
