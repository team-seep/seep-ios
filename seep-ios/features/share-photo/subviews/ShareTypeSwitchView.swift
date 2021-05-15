import UIKit
import RxSwift
import RxCocoa

class ShareTypeSwitchView: BaseView {
  
  enum ShareType {
    case emoji
    case photo
  }
  
  let emojiButton = ShareTypeButton().then {
    $0.setTitle("share_photo_emoji".localized, for: .normal)
  }
  
  let buttonDividorView = UIView().then{
    $0.backgroundColor = UIColor(r: 238, g: 238, b: 238)
  }
  
  let photoButton = ShareTypeButton().then {
    $0.setTitle("share_photo_album".localized, for: .normal)
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.isUserInteractionEnabled = true
    self.addSubViews(emojiButton, buttonDividorView, photoButton)
  }
  
  override func bindConstraints() {
    self.buttonDividorView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalTo(1)
      make.height.equalTo(30)
      make.top.equalToSuperview().offset(6)
    }
    
    self.emojiButton.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.right.equalTo(self.buttonDividorView.snp.left)
      make.top.equalToSuperview()
      make.height.equalTo(42)
    }
    
    self.photoButton.snp.makeConstraints { make in
      make.left.equalTo(self.buttonDividorView.snp.right)
      make.right.equalToSuperview()
      make.top.bottom.equalTo(self.emojiButton)
    }
    
    self.snp.makeConstraints { make in
      make.left.top.bottom.equalTo(self.emojiButton)
      make.right.equalTo(self.photoButton)
    }
  }
}

extension Reactive where Base: ShareTypeSwitchView {
  
  var tapEmojiButton: ControlEvent<Void> {
    return base.emojiButton.rx.tap
  }
  
  var tapPhotoButton: ControlEvent<Void> {
    return base.photoButton.rx.tap
  }
  
  var selectType: Binder<Base.ShareType> {
    return Binder(self.base) { view, shareType in
      view.emojiButton.rx.isSelected.onNext(shareType == .emoji)
      view.photoButton.rx.isSelected.onNext(shareType == .photo)
    }
  }
}
