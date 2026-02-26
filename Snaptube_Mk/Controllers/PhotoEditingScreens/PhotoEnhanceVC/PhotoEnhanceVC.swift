//
//  PhotoEnhanceVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit
import SVProgressHUD

class PhotoEnhanceVC: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var enhancePhotoButton: UIButton!
    
    var image: UIImage?
    var maxRetries = 15
    var currentRetry = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.text = "Enhance Photo".localized(LocalizationService.shared.language)
        self.enhancePhotoButton.setTitle("Enhance Photo".localized(LocalizationService.shared.language), for: .normal)
         imageView.image = image
     }
     
     // MARK: - Upload Image using NetworkManager
     func uploadImage(_ image: UIImage) {
         NetworkManager.shared.uploadImage(image) { [weak self] result in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 switch result {
                 case .success(let (id, uid)):
                     print("✅ Upload Success: id=\(id), uid=\(uid)")
                     self.currentRetry = 0
                     self.pollForResult(id: id, uid: uid)
                     
                 case .failure(let error):
                     SVProgressHUD.dismiss()
                     print("❌ Upload Error: \(error.localizedDescription)")
                 }
             }
         }
     }
     
     // MARK: - Polling for Result
     func pollForResult(id: String, uid: String) {
         guard currentRetry < maxRetries else {
             print("❌ Max retries reached")
             SVProgressHUD.dismiss()
             self.showErrorAlert(message: "Processing timeout. Please try again.".localized(LocalizationService.shared.language))
             return
         }
         
         print("⚡ FAST Polling #\(currentRetry + 1)/\(maxRetries)")
         
         NetworkManager.shared.checkImageProcessingStatus(id: id, uid: uid) { [weak self] result in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 switch result {
                 case .success(let (status, imageUrl, outputUrl)):
                     self.handleProcessingResponse(status: status, imageUrl: imageUrl, outputUrl: outputUrl, id: id, uid: uid)
                     
                 case .failure(let error):
                     print("❌ Status Check Error: \(error.localizedDescription)")
                     self.retryPolling(id: id, uid: uid)
                 }
             }
         }
     }
     
     private func handleProcessingResponse(status: String, imageUrl: String, outputUrl: String, id: String, uid: String) {
         print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
         print("⚡ FAST POLL #\(self.currentRetry + 1) - Status: \(status)")
         print("🖼️ Enhanced URL: '\(outputUrl)'")
         print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
         
         if status == "2" {
             print("🚀 PROCESS COMPLETED IN \(self.currentRetry + 1) POLLS! ⚡")
             self.handleProcessCompletion(imageUrl: imageUrl, outputUrl: outputUrl)
         } else {
             self.retryPolling(id: id, uid: uid)
         }
     }
     
     private func handleProcessCompletion(imageUrl: String, outputUrl: String) {
         SVProgressHUD.dismiss()
         let imageUrlToDownload = !outputUrl.isEmpty ? outputUrl : imageUrl
         let isEnhanced = !outputUrl.isEmpty
         
         if !imageUrlToDownload.isEmpty, let url = URL(string: imageUrlToDownload) {
             print("✅ DOWNLOADING \(isEnhanced ? "ENHANCED" : "INPUT") IMAGE: \(imageUrlToDownload)")
             self.downloadImage(from: url, isEnhanced: isEnhanced)
         } else {
             self.showErrorAlert(message: "No image URL found")
         }
     }
     
     private func retryPolling(id: String, uid: String) {
         print("⏳ Waiting 2s...")
         self.currentRetry += 1
         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
             self.pollForResult(id: id, uid: uid)
         }
     }
     
     // MARK: - Download Image
     func downloadImage(from url: URL, isEnhanced: Bool) {
         NetworkManager.shared.downloadImage(from: url.absoluteString) { [weak self] result in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 switch result {
                 case .success(let downloadedImage):
                     print("✅ Download completed: \(downloadedImage.size)")
                     self.navigateToPreview(with: downloadedImage)
                     
                 case .failure(let error):
                     print("❌ Download failed: \(error.localizedDescription)")
                 }
             }
         }
     }
     
     private func navigateToPreview(with image: UIImage) {
         self.showInterAdClick()
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         if let savePhotoVC = storyboard.instantiateViewController(withIdentifier: "SavePhotoVC") as? SavePhotoVC {
             savePhotoVC.croppedImage = image
             navigationController?.pushViewController(savePhotoVC, animated: true)
         }
     }
     
     private func showErrorAlert(message: String) {
         let alert = UIAlertController(title: "Error".localized(LocalizationService.shared.language), message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default) { _ in
             self.navigationController?.popViewController(animated: true)
         })
         present(alert, animated: true)
     }
     
     @IBAction func btnBack(_ sender: UIButton) {
         self.navigationController?.popViewController(animated: true)
     }
    
    @IBAction func enhancePhotoButtonAction(_ sender: UIButton) {
        // First check internet connectivity using ReachabilityManager
        if !ReachabilityManager.shared.isConnectedToNetwork() {
            ReachabilityManager.shared.showNoInternetAlert(on: self)
            return
        }
        if let image = image {
            SVProgressHUD.show()
            uploadImage(image)
        }
    }
    
}
