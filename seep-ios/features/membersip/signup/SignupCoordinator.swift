import UIKit

protocol SignupCoordinator: AnyObject, BaseCoordinator {
    func showImagePicker(isPhotoNil: Bool, picker: UIImagePickerController)
}

extension SignupCoordinator where Self: SignupViewController {
    func showImagePicker(isPhotoNil: Bool, picker: UIImagePickerController) {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        let cameraAction = UIAlertAction(
            title: "common_camera_action".localized,
            style: .default
        ) { (_ ) in
            picker.sourceType = .camera
            self.present(picker, animated: true)
        }
        let libraryAction = UIAlertAction(
            title: "common_album_action".localized,
            style: .default
        ) { ( _) in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        }
        let cancelAction = UIAlertAction(
            title: "common_cancel".localized,
            style: .cancel,
            handler: nil
        )
        
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        if isPhotoNil {
            let deletePhotoAction = UIAlertAction(
                title: "common_delete_photo_action".localized,
                style: .destructive
            ) { _ in
                self.reactor?.action.onNext(.inputPhoto(nil))
            }
            
            alert.addAction(deletePhotoAction)
        }
        
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}
