import UIKit

class FinishedView: BaseView {
  
  let titleLabel = UILabel().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-Light", size: 22)
    $0.textColor = .black
    $0.numberOfLines = 0
  }
  
  let viewTypeButton = UIButton().then {
    $0.setImage(UIImage(named: "ic_grid"), for: .normal)
  }
  
  let backButton = UIButton().then {
    $0.setImage(UIImage(named: "ic_back"), for: .normal)
    $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
    $0.setTitle("finish_back_button".localized, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 11)
    $0.setTitleColor(.black, for: .normal)
  }
  
  let emptyView = UIView().then {
    $0.backgroundColor = .clear
  }
  
  let emptyEmojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 50)
    $0.text = "☺️"
  }
  
  let emptyLabel = UILabel().then {
    let text = "finish_description_empty".localized
    let paragraphStyle = NSMutableParagraphStyle()
    
    paragraphStyle.lineHeightMultiple = 1.31
    
    let attributedString = NSMutableAttributedString(
      string: text,
      attributes: [
        .kern: -0.42,
        .paragraphStyle: paragraphStyle,
      ])
    
    $0.textColor = .black
    $0.alpha = 0.4
    $0.numberOfLines = 0
    $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
    $0.attributedText = attributedString
    $0.textAlignment = .center
  }
  
  let emptyBackButton = UIButton().then {
    $0.setTitle("finish_empty_back_button".localized, for: .normal)
    $0.titleLabel?.font = UIFont(name: "AppleSDGothicNeoEB00", size: 17)
    $0.setTitleColor(.white, for: .normal)
    $0.layer.cornerRadius = 25
    $0.backgroundColor = .gray5
    $0.contentEdgeInsets = UIEdgeInsets(top: 14, left: 33, bottom: 16, right: 33)
  }
  
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.emptyView.addSubViews(emptyEmojiLabel, emptyLabel, emptyBackButton)
    self.addSubViews(titleLabel, viewTypeButton, backButton, emptyView)
    self.titleLabel.attributedText = self.getEmptyTitle()
  }
  
  override func bindConstraints() {
    self.titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(22)
      make.top.equalTo(safeAreaLayoutGuide).offset(34 * RatioUtils.height)
    }
    
    self.viewTypeButton.snp.makeConstraints { make in
      make.top.equalTo(self.titleLabel)
      make.right.equalToSuperview().offset(36)
    }
    
    self.backButton.snp.makeConstraints { make in
      make.left.equalTo(self.titleLabel)
      make.top.equalTo(self.titleLabel.snp.bottom).offset(14)
    }
    
    self.emptyView.snp.makeConstraints { make in
      make.left.right.bottom.equalToSuperview()
      make.top.equalTo(self.backButton.snp.bottom)
    }
    
    self.emptyBackButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview()
      make.height.equalTo(50)
    }
    
    self.emptyLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(self.emptyBackButton.snp.top).offset(-20)
    }
    
    self.emptyEmojiLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(self.emptyLabel.snp.top)
    }
  }
  
  private func getEmptyTitle() -> NSMutableAttributedString {
    let text = "finish_title_empty".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "완료된 것이 없지만")
    
    attributedString.addAttribute(
      .font,
      value: UIFont(name: "AppleSDGothicNeo-Bold", size: 22)!,
      range: boldTextRange
    )
    
    return attributedString
  }
  
  private func getCountTitle(count: Int) -> NSMutableAttributedString {
    let text = String(format: "finish_title_count".localized, count)
    let attributedString = NSMutableAttributedString(string: text)
    let underlineTextRange = (text as NSString).range(of: String(format: "home_write_category_want_to_do_unit".localized, count))
    let boldTextRange = (text as NSString).range(of: "이뤘어요!")
    
    attributedString.addAttributes([
      .foregroundColor: UIColor.tennisGreen,
      .underlineStyle: NSUnderlineStyle.thick.rawValue,
      .underlineColor: UIColor.tennisGreen,
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
