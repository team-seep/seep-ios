import UIKit

class HomeView: BaseView {
  
  let titleLabel = UILabel().then {
    $0.font = .appleLight(size: 22)
    $0.textColor = .black
    $0.numberOfLines = 0
  }
  
  let greenLine = UIView().then {
    $0.backgroundColor = .tennisGreen
  }
  
  let emojiView = EmojiImageView()
  
  let successCountButton = UIButton().then {
    $0.titleLabel?.font = .appleSemiBold(size: 12)
    $0.setTitleColor(.black, for: .normal)
    $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 4, right: 15)
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOffset = CGSize(width: 0, height: 1)
    $0.layer.shadowOpacity = 0.05
  }
  
  let categoryView = CategoryView()
  
  let viewTypeButton = UIButton().then {
    $0.setImage(.icGrid, for: .normal)
  }
  
  let containerView = UIView().then {
    $0.isUserInteractionEnabled = true
    $0.backgroundColor = .clear
  }
  
  let writeButton = UIButton().then {
    $0.titleLabel?.font = .appleExtraBold(size: 17)
    $0.backgroundColor = .tennisGreen
    $0.layer.cornerRadius = 25
    $0.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
  }
  
  let toast = ToastView(frame: CGRect(x: 20, y: -58, width: UIScreen.main.bounds.width - 40, height: 58))
  
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.addSubViews(
      titleLabel, greenLine, emojiView, successCountButton,
      categoryView, viewTypeButton, containerView,
      writeButton
    )
  }
  
  override func bindConstraints() {
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(22)
      make.top.equalTo(safeAreaLayoutGuide).offset(34 * RatioUtils.height)
    }
    
    self.greenLine.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.bottom.equalTo(self.titleLabel)
      make.width.equalTo(44)
      make.height.equalTo(2)
    }
    
    self.emojiView.snp.makeConstraints { make in
      make.top.equalTo(safeAreaLayoutGuide)
      make.right.equalToSuperview().offset(-20)
    }
    
    self.successCountButton.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(22)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(20 * RatioUtils.height)
    }
    
    self.categoryView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.top.equalTo(self.successCountButton.snp.bottom).offset(50 * RatioUtils.height)
    }
    
    self.viewTypeButton.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-24)
      make.centerY.equalTo(self.categoryView)
    }
    
    self.containerView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.categoryView.snp.bottom).offset(16)
    }
    
    self.writeButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.height.equalTo(50)
      make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
    }
  }
  
  func showWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 1.0
      self.writeButton.transform = .identity
    }
  }
  
  func hideWriteButton() {
    UIView.transition(with: self.writeButton, duration: 0.3, options: .curveEaseInOut) {
      self.writeButton.alpha = 0.0
      self.writeButton.transform = .init(translationX: 0, y: 100)
    }
  }
  
  func showFinishToast() {
    let window = UIApplication.shared.windows[0]
    let topPadding = window.safeAreaInsets.top
    
    self.addSubViews(toast)
    
    UIView.transition(with: toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
      self?.toast.transform = .init(translationX: 0, y: topPadding + 10 + 58)
    } completion: { isComplete in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        guard let self = self else { return }
        UIView.transition(with: self.toast, duration: 0.5, options: .curveEaseInOut) { [weak self] in
          self?.toast.transform = .identity
        } completion: { [weak self] isCompleteRemove in
          if isCompleteRemove {
            self?.toast.removeFromSuperview()
          }
        }
      }
    }
  }
  
  func setWishCount(category: Category, count: Int) {
    self.greenLine.isHidden = count == 0
    if count == 0 {
      self.titleLabel.attributedText = self.getEmptyTitle(by: category, count: count)
    } else{
      self.titleLabel.attributedText = self.getCountTitle(by: category, count: count)
    }
  }
  
  func startEmojiAnimation() {
    UIView.transition(
      with: self.emojiView,
      duration: 2,
      options: [.autoreverse,.repeat]
    ) { [weak self] in
      self?.emojiView.transform = .init(translationX: 0, y: 10)
    } completion: { [weak self] _ in
      self?.emojiView.transform = .identity
    }
  }
  
  func setSuccessCount(category: Category, count: Int) {
    let text = count != 0 ? String(format: "home_finish_count_\(category.rawValue)_format".localized, count) : String(format: "home_finish_count_\(category.rawValue)_format_empty".localized, count)
    let attributedString = NSMutableAttributedString(string: text)
    let underlineTextRange = (text as NSString).range(of: category == .wantToGo ? "\(count)곳" : "\(count)개")
    
    attributedString.addAttribute(
      .foregroundColor,
      value: UIColor.seepBlue,
      range: underlineTextRange
    )
    self.successCountButton.setAttributedTitle(attributedString, for: .normal)
  }
  
  func changeViewType(to viewType: ViewType) {
    self.viewTypeButton.setImage(UIImage(named: viewType.toggle().imageName), for: .normal)
  }
  
  private func getEmptyTitle(by category: Category, count: Int) -> NSMutableAttributedString {
    let text = "home_write_\(category.rawValue)_count_empty".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "적어봐요!")
    
    attributedString.addAttribute(
      .font,
      value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!,
      range: boldTextRange
    )
    
    return attributedString
  }
  
  private func getCountTitle(by category: Category, count: Int) -> NSMutableAttributedString {
    let text = String(format: "home_write_\(category.rawValue)_count_format".localized, count)
    let attributedString = NSMutableAttributedString(string: text)
    let underlineTextRange = (text as NSString).range(of: String(format: "common_\(category.rawValue)_unit".localized, count))
    let boldTextRange = (text as NSString).range(of: "남았어요!")
    
    attributedString.addAttributes([
      .foregroundColor: UIColor.tennisGreen,
      .font: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!
    ], range: underlineTextRange)
    
    attributedString.addAttribute(
      .font,
      value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!,
      range: boldTextRange
    )
    
    return attributedString
  }
}
