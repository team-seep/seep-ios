import UIKit

class HomeCountCell: BaseTableViewCell {
  
  static let registerId = "\(HomeCountCell.self)"
  
  let countLabel = UILabel().then {
    let text = "home_write_count_format".localized
    let attributedString = NSMutableAttributedString(string: text)
    let colorTextRange = (text as NSString).range(of: "11")
    let boldTextRange = (text as NSString).range(of: "11개")
    
    attributedString.addAttribute(
      .font,
      value: UIFont.systemFont(ofSize: 20, weight: .bold),
      range: boldTextRange
    )
    attributedString.addAttribute(
      .foregroundColor,
      value: UIColor(r: 56, g: 202, b: 79),
      range: colorTextRange
    )
    $0.font = .systemFont(ofSize: 20, weight: .medium)
    $0.attributedText = attributedString
  }
  
  let greenLine = UIView().then {
    $0.backgroundColor = UIColor(r: 56, g: 202, b: 79)
  }
  
  let existedLabel = UILabel().then {
    let text = "home_existed_wish".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "위시리스트")
    
    attributedString.addAttribute(
      .font,
      value: UIFont.systemFont(ofSize: 20, weight: .bold),
      range: boldTextRange
    )
    
    $0.font = .systemFont(ofSize: 20, weight: .medium)
    $0.textColor = .black
    $0.attributedText = attributedString
  }
  
  
  override func setup() {
    self.backgroundColor = .clear
    self.selectionStyle = .none
    self.addSubViews(countLabel, greenLine, existedLabel)
  }
  
  override func bindConstraints() {
    self.countLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(24)
      make.top.equalToSuperview().offset(10)
    }
    
    self.greenLine.snp.makeConstraints { make in
      make.left.equalTo(self.countLabel).offset(-1)
      make.bottom.equalTo(self.countLabel)
      make.width.equalTo(44)
      make.height.equalTo(2)
    }
    
    self.existedLabel.snp.makeConstraints { make in
      make.left.equalTo(self.countLabel)
      make.top.equalTo(self.countLabel.snp.bottom).offset(10)
      make.bottom.equalToSuperview().offset(-20)
    }
  }
}
