import UIKit

struct AlertUtils {
  
  static func show(
    viewController: UIViewController,
    title: String?,
    message: String?,
    actions: [UIAlertAction]
  ) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    for action in actions {
      controller.addAction(action)
    }
    viewController.present(controller, animated: true)
  }
  
  static func showWithAction(
    controller: UIViewController,
    title: String? = nil,
    message: String? = nil,
    onTapOk: @escaping (() -> Void)
  ) {
    let okAction = UIAlertAction(title: "확인", style: .default) { action in
      onTapOk()
    }
    
    AlertUtils.show(
      viewController: controller,
      title: title,
      message: message,
      actions: [okAction]
    )
  }
  
  static func showWithCancel(
    viewController: UIViewController,
    title: String? = nil,
    message: String? = nil,
    onTapOk: @escaping () -> Void
  ) {
    let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
      onTapOk()
    }
    let cancelAction = UIAlertAction(title: "취소", style: .cancel)
    
    AlertUtils.show(
      viewController: viewController,
      title: title,
      message: message,
      actions: [okAction, cancelAction]
    )
  }
  
  static func show(
    viewController: UIViewController,
    title: String?,
    message: String?
  ) {
    let okAction = UIAlertAction(title: "확인", style: .default)
    
    AlertUtils.show(
      viewController: viewController,
      title: title,
      message: message,
      actions: [okAction]
    )
  }
  
  static func showImagePicker(controller: UIViewController, picker: UIImagePickerController) {
    let alert = UIAlertController(title: "이미지 불러오기", message: nil, preferredStyle: .actionSheet)
    let libraryAction = UIAlertAction(title: "앨범", style: .default) { ( _) in
      picker.sourceType = .photoLibrary
      controller.present(picker, animated: true)
    }
    let cameraAction = UIAlertAction(title: "카메라", style: .default) { (_ ) in
      picker.sourceType = .camera
      controller.present(picker, animated: true)
    }
    let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
    
    alert.addAction(libraryAction)
    alert.addAction(cameraAction)
    alert.addAction(cancelAction)
    controller.present(alert, animated: true)
  }
}


