//
//  SavePhotoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 18/11/25.
//

import UIKit
import Photos
import SVProgressHUD

class SavePhotoVC: UIViewController {

    @IBOutlet weak var editingImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var savePhotoButton: UIButton!
    var croppedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Display the cropped image
        if let image = croppedImage {
            editingImageView.image = image
            editingImageView.contentMode = .scaleAspectFit
        }
        setLoca()
    }
    
    func setLoca() {
        self.titleLabel.text = "Photo Resize".localized(LocalizationService.shared.language)
        self.savePhotoButton.setTitle("Save Photo".localized(LocalizationService.shared.language), for: .normal)
    }
    
    @IBAction func savedPhotoButtonAction(_ sender: UIButton) {
        saveImageToPhotoLibrary()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func saveImageToPhotoLibrary() {
        guard let image = croppedImage else {
            showErrorAlert(message: "No image to save".localized(LocalizationService.shared.language))
            return
        }
        
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            saveImageToAppAlbum(image)
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            showPermissionAlert()
        @unknown default:
            showErrorAlert(message: "Unknown photo library permission status".localized(LocalizationService.shared.language))
        }
    }
    
    private func saveImageToAppAlbum(_ image: UIImage) {
        SVProgressHUD.show(withStatus: "Saving...".localized(LocalizationService.shared.language))
        
        // Get or create app album first, then save image
        getOrCreateAppAlbum { [weak self] album, error in
            if let album = album {
                self?.saveImageToAlbum(image, album: album)
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    print("Failed to create album")
                }
            }
        }
    }
    
    private func getOrCreateAppAlbum(completion: @escaping (PHAssetCollection?, Error?) -> Void) {
        let albumName = AppConstant.albumName // Change this to your app name
        
        // Check if album already exists
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = collections.firstObject {
            // Album already exists
            completion(existingAlbum, nil)
            return
        }
        
        // Create new album
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }) { success, error in
            if success {
                // Fetch the newly created album
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                completion(collections.firstObject, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func saveImageToAlbum(_ image: UIImage, album: PHAssetCollection) {
        var placeholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            // Create asset from image
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeholder = assetChangeRequest.placeholderForCreatedAsset
            
            // Add asset to album
            if let placeholder = placeholder {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([placeholder] as NSArray)
            }
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                
                if success {
                    print("✅ Cropped image saved to 'Photo Editor App' album successfully!")
                    self?.showSuccessMessage()
                } else {
                    print("❌ Failed to save cropped image: \(error?.localizedDescription ?? "Unknown error")")
                    
                    // If adding to album failed, try saving to general library as fallback
                    if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain {
                        self?.performSaveToGeneralLibrary(image)
                    } else {
                        self?.showErrorAlert(message: error?.localizedDescription ?? "Failed to save image")
                    }
                }
            }
        }
    }
    
    private func performSaveToGeneralLibrary(_ image: UIImage) {
        SVProgressHUD.show(withStatus: "Saving to Photos...")
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                
                if success {
                    print("✅ Cropped image saved to photo library successfully!")
                    self?.showSuccessMessage()
                } else {
                    print("❌ Failed to save cropped image: \(error?.localizedDescription ?? "Unknown error")")
                    self?.showErrorAlert(message: error?.localizedDescription ?? "Failed to save image")
                }
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    if let image = self?.croppedImage {
                        self?.saveImageToAppAlbum(image)
                    }
                } else {
                    self?.showPermissionAlert()
                }
            }
        }
    }
    
    private func showSuccessMessage() {
        SVProgressHUD.showSuccess(withStatus: "Saved to Photo Editor App Album!".localized(LocalizationService.shared.language))
        
        // Optionally pop back after success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            SVProgressHUD.dismiss()
            // Navigate back to PhotoVideoListVC or wherever appropriate
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permission Required".localized(LocalizationService.shared.language),
            message: "Please allow photo library access to save images to your Photos.".localized(LocalizationService.shared.language),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings".localized(LocalizationService.shared.language), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error".localized(LocalizationService.shared.language),
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - API's Calling
extension SavePhotoVC {
    
}
