import UIKit

extension UIView {
  
  func addSubViews(_ views: UIView...) {
    for view in views {
      addSubview(view)
    }
  }
  
  func asImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    
    return renderer.image { rendererContext in
      layer.render(in: rendererContext.cgContext)
    }
  }
}
