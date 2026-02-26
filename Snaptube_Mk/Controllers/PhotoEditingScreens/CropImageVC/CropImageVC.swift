//
//  CropImageVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 18/11/25.
//

import UIKit
import Mantis
import Photos

class CropImageVC: UIViewController {
    
    @IBOutlet weak var resizeImageView: UIImageView!
    @IBOutlet weak var titleLAbel: UILabel!
    @IBOutlet weak var resizePhotoButton: UIButton!
    
    var selectedImage: UIImage?
    var originalAsset: PHAsset?
    var croppedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    func setLoca() {
        self.titleLAbel.text = "Photo Resize".localized(LocalizationService.shared.language)
        self.resizePhotoButton.setTitle("Resize Photo".localized(LocalizationService.shared.language), for: .normal)
    }
    private func setupUI() {
        // Set the selected image to imageView
        if let image = selectedImage {
            resizeImageView.image = image
            resizeImageView.contentMode = .scaleAspectFit
        }
        setLoca()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resizePhotoButtonAction(_ sender: UIButton) {
        openCropViewController()
    }
    
    private func openCropViewController() {
        guard let image = selectedImage else { return }
        
        var config = Mantis.Config()
        
        // Customize crop toolbar (optional)
        config.cropToolbarConfig.toolbarButtonOptions = [.clockwiseRotate, .reset, .ratio, .alterCropper90Degree]
        
        // Customize preset ratios (optional)
        config.presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.delegate = self
        cropViewController.modalPresentationStyle = .fullScreen
        
        present(cropViewController, animated: true)
    }
    
    private func saveCroppedImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Cropped image saved to photo library successfully!")
                    self?.showAlert(title: "Success".localized(LocalizationService.shared.language), message: "Cropped image saved to photo library".localized(LocalizationService.shared.language))
                } else {
                    print("❌ Failed to save cropped image: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CropViewControllerDelegate
extension CropImageVC: CropViewControllerDelegate {
    
    func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        // Update the image view with cropped image
        resizeImageView.image = cropped
        croppedImage = cropped
        
        print("✅ Image cropped successfully!")
        print("📐 Crop info: \(cropInfo)")
        print("🖼️ Cropped image size: \(cropped.size)")
        
        // Dismiss the crop view controller
        cropViewController.dismiss(animated: true) { [weak self] in
            // Optionally save to photo library or show save option
            self?.navigateToSavePhotoVC()
        }
    }
    
    func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true)
        print("❌ Crop cancelled")
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController, original: UIImage) {
        print("❌ Failed to crop image")
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: Mantis.CropViewController) {
        print("🔄 Begin resize")
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: Mantis.CropViewController, original: UIImage, cropInfo: CropInfo) {
        print("🔚 End resize")
    }
    func navigateToSavePhotoVC() {
        guard let croppedImage = croppedImage else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let savePhotoVC = storyboard.instantiateViewController(withIdentifier: "SavePhotoVC") as? SavePhotoVC {
            savePhotoVC.croppedImage = croppedImage
            navigationController?.pushViewController(savePhotoVC, animated: true)
        }
    }
}
