import UIKit

extension UIImage {
  static let icClose = UIImage(named: "ic_close")
  static let icGrid = UIImage(named: "ic_grid")
  static let icList = UIImage(named: "ic_list")
  static let icMore = UIImage(named: "ic_more")
  static let emojiWantToDo = UIImage(named: "img_category_want_to_do")
  static let emojiWantToGet = UIImage(named: "img_category_want_to_get")
  static let emojiWantToGo = UIImage(named: "img_category_want_to_go")
  static let imgEmojiEmpty = UIImage(named: "img_emoji_empty")
  static let icCheckOff20 = UIImage(named: "ic_check_off_20")
  static let icCheckOff = UIImage(named: "ic_check_off")
  static let icCheckOn20 = UIImage(named: "ic_check_on_20")
  static let icCheckOn = UIImage(named: "ic_check_on")
  static let icLogoBlack = UIImage(named: "ic_logo_black")
  static let icLogoWhite = UIImage(named: "ic_logo_white")
  
  var averageColor: UIColor? {
    let offset: CGFloat = 100.0
    guard let inputImage = CIImage(image: self) else { return nil }
    let extentVector = CIVector(
      x: inputImage.extent.origin.x,
      y: inputImage.extent.origin.y,
      z: inputImage.extent.size.width,
      w: inputImage.extent.size.height
    )
    
    guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
    guard let outputImage = filter.outputImage else { return nil }
    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: [.workingColorSpace: kCFNull])
    
    context.render(
      outputImage,
      toBitmap: &bitmap,
      rowBytes: 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: nil
    )
    
    return UIColor(
      red: ((CGFloat(bitmap[0]) + (offset)) / 255),
      green: ((CGFloat(bitmap[1]) + (offset)) / 255),
      blue: ((CGFloat(bitmap[2]) + (offset)) / 255),
      alpha: (CGFloat(bitmap[3]) / 255)
    )
  }
}
