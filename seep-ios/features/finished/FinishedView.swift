import UIKit

class FinishedView: BaseView {
  
  let titleLabel = UILabel().then {
    $0.text = String(format: "home_write_count_format1".localized, 24)
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
  
  let emojiLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 50)
  }
  
  let emptyLabel = UILabel().then {
    $0.textColor = .black
    $0.alpha = 0.4
    $0.numberOfLines = 0
    $0.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 14)
  }
  
  
  override func setup() {
    self.backgroundColor = UIColor(r: 246, g: 246, b: 246)
    self.addSubViews(titleLabel, viewTypeButton, backButton)
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
  }
  
  private func getEmptyTitle() -> NSMutableAttributedString {
    let text = "finish_title_empty".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "완료된 것이 없네요!")
    
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
