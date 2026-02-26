//
//  SaveVideoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 21/11/25.
//

import UIKit
import AVFoundation
import Photos
import SVProgressHUD

class SaveVideoVC: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    // Video properties
    var videoURL: URL?
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var isPlaying = false
    var titleScreen = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVideoPlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPreviewView.bounds
    }
    
    deinit {
        // Clean up observers
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() {
        self.titleLabel.text = titleScreen
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Setup progress HUD
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.black)
        self.saveButton.setTitle("Save Video".localized(LocalizationService.shared.language), for: .normal)
    }
    
    func setupVideoPlayer() {
        guard let videoURL = videoURL else { return }
        
        // Create player
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPreviewView.bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.cornerRadius = 12
        playerLayer.masksToBounds = true
        
        videoPreviewView.layer.addSublayer(playerLayer)
        
        // Add tap gesture to video preview
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleVideoTap))
        videoPreviewView.addGestureRecognizer(tapGesture)
        
        // Add observer for video end
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(playerItemDidReachEnd(notification:)),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: player.currentItem)
        
        // Auto-play video when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playVideo()
        }
    }
    
    @objc private func handleVideoTap() {
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        // Reset video to beginning when it ends
        player.seek(to: CMTime.zero)
        isPlaying = false
        updatePlayButton()
    }
    
    private func playVideo() {
        player.play()
        isPlaying = true
        updatePlayButton()
    }
    
    private func pauseVideo() {
        player.pause()
        isPlaying = false
        updatePlayButton()
    }
    
    private func updatePlayButton() {
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = self.isPlaying ? 0.0 : 1.0
        }
    }
}

// MARK: - SaveVideoVC Actions
extension SaveVideoVC {
    @IBAction func backButtonAction(_ sender: UIButton) {
        // Stop video playback before going back
        player.pause()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    @IBAction func saveVideoButtonAction(_ sender: UIButton) {
        guard let videoURL = videoURL else {
            showErrorAlert(message: "No video to save")
            return
        }
        
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            saveVideoToAppAlbum(videoURL)
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            showPhotoLibraryPermissionAlert()
        @unknown default:
            showErrorAlert(message: "Unknown photo library permission status")
        }
    }
    
    private func saveVideoToAppAlbum(_ videoURL: URL) {
        SVProgressHUD.show(withStatus: "Saving...".localized(LocalizationService.shared.language))
        
        // Get or create app album first, then save video
        getOrCreateAppAlbum { [weak self] album, error in
            if let album = album {
                self?.saveVideoToAlbum(videoURL, album: album)
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self?.showErrorAlert(message: error?.localizedDescription ?? "Failed to create album")
                }
            }
        }
    }
    
    private func getOrCreateAppAlbum(completion: @escaping (PHAssetCollection?, Error?) -> Void) {
        let albumName = AppConstant.albumName // Use same album name as photo saving
        
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
    
    private func saveVideoToAlbum(_ videoURL: URL, album: PHAssetCollection) {
        var placeholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            // Create asset from video
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            placeholder = assetChangeRequest?.placeholderForCreatedAsset
            
            // Add asset to album
            if let placeholder = placeholder {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([placeholder] as NSArray)
            }
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                
                if success {
                    print("✅ Video saved to 'Photo Editor App' album successfully!")
                    self?.showSuccessAlert()
                } else {
                    print("❌ Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
                    
                    // If adding to album failed, try saving to general library as fallback
                    if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain {
                        self?.performSaveToGeneralLibrary(videoURL)
                    } else {
                        self?.showErrorAlert(message: error?.localizedDescription ?? "Failed to save video")
                    }
                }
            }
        }
    }
    
    private func performSaveToGeneralLibrary(_ videoURL: URL) {
        SVProgressHUD.show(withStatus: "Saving to Photos...".localized(LocalizationService.shared.language))
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                
                if success {
                    print("✅ Video saved to photo library successfully!".localized(LocalizationService.shared.language))
                    self?.showSuccessAlert()
                } else {
                    print("❌ Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
                    self?.showErrorAlert(message: error?.localizedDescription ?? "Failed to save video")
                }
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    if let videoURL = self?.videoURL {
                        self?.saveVideoToAppAlbum(videoURL)
                    }
                } else {
                    self?.showPhotoLibraryPermissionAlert()
                }
            }
        }
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success".localized(LocalizationService.shared.language),
                                    message: "Video saved to Photo Editor App Album successfully".localized(LocalizationService.shared.language),
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default, handler: { [weak self] _ in
            // Pop back to previous view controller when OK is pressed
//            self?.navigationController?.popViewController(animated: true)
            self?.navigationController?.popToRootViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error".localized(LocalizationService.shared.language),
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showPhotoLibraryPermissionAlert() {
        let alert = UIAlertController(
            title: "Photo Library Access Denied".localized(LocalizationService.shared.language),
            message: "Please enable photo library access in Settings to save videos".localized(LocalizationService.shared.language),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings".localized(LocalizationService.shared.language), style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}
