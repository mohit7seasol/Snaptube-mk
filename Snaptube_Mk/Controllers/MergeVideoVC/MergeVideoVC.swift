//
//  MergeVideoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 21/11/25.
//

import UIKit
import Photos
import AVFoundation

class MergeVideoVC: UIViewController {
    
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var mergeVideoPreView: UIView!
    @IBOutlet weak var startTimeVideoLabel: UILabel!
    @IBOutlet weak var endTimeVideoLabel: UILabel!
    @IBOutlet weak var mergeVideoButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!

    var selectedVideoURLs: [URL] = []
    var selectedVideoAssets: [PHAsset] = []
    
    // Video player properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var rangeSlider: RangeSlider!
    var isPlaying = false
    var currentPlaybackTime: CMTime = .zero
    
    // Composition properties
    var composition: AVMutableComposition?
    var asset: AVAsset?
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    // Thumbnail preview
    var imageFrameView: UIView!
    var cache: NSCache<AnyObject, AnyObject>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupThumbnailView()
        loadAndMergeVideos()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPreviewView.bounds
        rangeSlider?.frame = mergeVideoPreView.bounds
        imageFrameView?.frame = mergeVideoPreView.bounds
    }
    
    private func setupUI() {
        mergeVideoButton.layer.cornerRadius = 8
        playButton.layer.cornerRadius = 8
        
        // Setup video preview layer
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoPreviewView.bounds
        videoPreviewView.layer.addSublayer(playerLayer!)
        
        // Initialize cache
        cache = NSCache()
        self.titleLabel.text = "Merge Video".localized(LocalizationService.shared.language)
        self.mergeVideoButton.setTitle("Next".localized(LocalizationService.shared.language), for: .normal)
        
    }
    
    private func setupThumbnailView() {
        // Create image frame view for thumbnails - SAME AS CropVideoVC
        imageFrameView = UIView()
        imageFrameView.frame = CGRect(x: 0, y: 0, width: mergeVideoPreView.frame.width, height: mergeVideoPreView.frame.height)
        imageFrameView.layer.cornerRadius = 5.0
        imageFrameView.layer.borderWidth = 1.0
        imageFrameView.layer.borderColor = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        mergeVideoPreView.addSubview(imageFrameView)
    }
    
    private func setupRangeSlider() {
        // Remove existing slider
        let subViews = mergeVideoPreView.subviews
        for subview in subViews {
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        rangeSlider = RangeSlider(frame: mergeVideoPreView.bounds)
        mergeVideoPreView.addSubview(rangeSlider)
        rangeSlider.tag = 1000
        
        // Range slider styling - SAME AS CropVideoVC
        rangeSlider.trackTintColor = UIColor.clear
        rangeSlider.trackHighlightTintColor = UIColor.clear
        rangeSlider.thumbTintColor = UIColor.white
        rangeSlider.thumbBorderColor = UIColor.systemBlue
        rangeSlider.thumbBorderWidth = 2.0
        rangeSlider.curvaceousness = 1.0
        
        rangeSlider.minimumValue = 0.0
        rangeSlider.maximumValue = 100.0
        rangeSlider.lowerValue = 0.0
        rangeSlider.upperValue = 100.0
        
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        
        // Bring imageFrameView to front so thumbnails are visible behind slider
        mergeVideoPreView.bringSubviewToFront(imageFrameView)
        mergeVideoPreView.bringSubviewToFront(rangeSlider)
    }
    
    private func loadAndMergeVideos() {
        // If we have URLs, use them directly
        if !selectedVideoURLs.isEmpty {
            mergeVideoURLs(selectedVideoURLs)
        }
        // If we have PHAssets, load them first
        else if !selectedVideoAssets.isEmpty {
            loadAssetsAndMerge()
        }
    }
    
    private func loadAssetsAndMerge() {
        let dispatchGroup = DispatchGroup()
        var videoAssets: [AVAsset] = []
        
        for asset in selectedVideoAssets {
            dispatchGroup.enter()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let avAsset = avAsset {
                    videoAssets.append(avAsset)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.createMergedComposition(from: videoAssets)
        }
    }
    
    private func mergeVideoURLs(_ videoURLs: [URL]) {
        let assets = videoURLs.map { AVURLAsset(url: $0) }
        createMergedComposition(from: assets)
    }
    
    private func createMergedComposition(from assets: [AVAsset]) {
        composition = AVMutableComposition()
        
        guard let composition = composition else { return }
        
        var currentTime = CMTime.zero
        var totalDuration = CMTime.zero
        
        // Calculate total duration first
        for asset in assets {
            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
        
        self.asset = composition
        thumbTime = totalDuration
        thumbtimeSeconds = Int(CMTimeGetSeconds(totalDuration))
        
        // Create tracks
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }
        
        // Insert each video
        for asset in assets {
            do {
                // Get video track
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                            of: videoTrack,
                                                            at: currentTime)
                }
                
                // Get audio track
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                            of: audioTrack,
                                                            at: currentTime)
                }
                
                currentTime = CMTimeAdd(currentTime, asset.duration)
                
            } catch {
                print("Error inserting track: \(error.localizedDescription)")
            }
        }
        
        // Setup UI after composition is ready
        setupAfterComposition()
    }
    
    private func setupAfterComposition() {
        guard let composition = composition else { return }
        
        // Create player item
        let playerItem = AVPlayerItem(asset: composition)
        player = AVPlayer(playerItem: playerItem)
        playerLayer?.player = player
        
        // Setup range slider
        setupRangeSlider()
        
        // Create thumbnail frames - SAME AS CropVideoVC
        createImageFrames()
        
        // Setup time labels and slider
        let totalDuration = composition.duration.seconds
        rangeSlider.maximumValue = totalDuration
        rangeSlider.upperValue = totalDuration
        
        updateTimeLabels()
        setupPlaybackObserver()
        
        // Show UI elements
        startTimeVideoLabel.isHidden = false
        endTimeVideoLabel.isHidden = false
        mergeVideoButton.isHidden = false
    }
    
    // MARK: - Creating Frame Images - SAME AS CropVideoVC
    func createImageFrames() {
        guard let asset = asset else { return }
        
        // Remove existing image frames
        for subview in imageFrameView.subviews {
            subview.removeFromSuperview()
        }
        
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero
        
        thumbTime = asset.duration
        thumbtimeSeconds = Int(CMTimeGetSeconds(thumbTime))
        let maxLength = "\(thumbtimeSeconds)" as NSString
        
        let thumbAvg = thumbtimeSeconds / 6
        var startTime = 1
        var startXPosition: CGFloat = 0.0
        
        // Loop for 6 number of frames - SAME AS CropVideoVC
        for _ in 0...5 {
            let imageButton = UIButton()
            let xPositionForEach = CGFloat(imageFrameView.frame.width) / 6
            imageButton.frame = CGRect(x: startXPosition, y: 0, width: xPositionForEach, height: imageFrameView.frame.height)
            
            do {
                let time = CMTimeMakeWithSeconds(Float64(startTime), preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                imageButton.setImage(image, for: .normal)
            } catch {
                print("Image generation failed with error \(error)")
                // Set placeholder if image generation fails
                imageButton.backgroundColor = UIColor.darkGray
            }
            
            startXPosition += xPositionForEach
            startTime += thumbAvg
            imageButton.isUserInteractionEnabled = false
            imageButton.imageView?.contentMode = .scaleAspectFill
            imageFrameView.addSubview(imageButton)
        }
    }
    
    private func setupPlaybackObserver() {
        player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentPlaybackTime = time
            
            // Loop within selected range
            if time.seconds >= self.rangeSlider.upperValue {
                self.pauseVideo()
                self.seekToTime(CMTime(seconds: self.rangeSlider.lowerValue, preferredTimescale: 600))
            }
        }
    }
    
    @objc private func rangeSliderValueChanged(_ slider: RangeSlider) {
        updateTimeLabels()
        
        // If video is playing, seek to new start time
        if isPlaying {
            seekToTime(CMTime(seconds: slider.lowerValue, preferredTimescale: 600))
        }
    }
    
    private func updateTimeLabels() {
        let startTime = formatTime(seconds: rangeSlider.lowerValue)
        let endTime = formatTime(seconds: rangeSlider.upperValue)
        
        startTimeVideoLabel.text = startTime
        endTimeVideoLabel.text = endTime
    }
    
    private func formatTime(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func seekToTime(_ time: CMTime) {
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func playVideo() {
        player?.play()
        isPlaying = true
        playButton.setTitle("Pause", for: .normal)
        playButton.alpha = 0.0 // Hide play button when playing
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
        playButton.setTitle("Play", for: .normal)
        playButton.alpha = 1.0 // Show play button when paused
    }
    
    // MARK: - Export and Save
    private func exportMergedVideo() {
        guard let composition = composition else {
            showAlert(message: "No video to export")
            return
        }
        
        let startTime = CMTime(seconds: rangeSlider.lowerValue, preferredTimescale: 600)
        let endTime = CMTime(seconds: rangeSlider.upperValue, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: composition,
                                                     presetName: AVAssetExportPresetHighestQuality) else {
            showAlert(message: "Failed to create export session")
            return
        }
        
        // Create output URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("merged_video_\(Int(Date().timeIntervalSince1970)).mp4")
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        
        // Show loading
        showLoadingIndicator()
        mergeVideoButton.isEnabled = false
        
        // Export
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                self?.mergeVideoButton.isEnabled = true
                self?.hideLoadingIndicator()
                
                switch exportSession.status {
                case .completed:
                    // Pass to SaveVideoVC instead of saving directly
                    self?.navigateToSaveVideoVC(with: outputURL)
                case .failed:
                    self?.showAlert(message: "Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                    // Clean up failed export file
                    try? FileManager.default.removeItem(at: outputURL)
                case .cancelled:
                    self?.showAlert(message: "Export cancelled")
                    // Clean up cancelled export file
                    try? FileManager.default.removeItem(at: outputURL)
                default:
                    break
                }
            }
        }
    }
    
    private func navigateToSaveVideoVC(with videoURL: URL) {
        guard let navigationController = self.navigationController else {
            print("Navigation controller is nil")
            showAlert(message: "Navigation unavailable")
            return
        }
        
        print("Navigating to SaveVideoVC with URL: \(videoURL)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let saveVideoVC = storyboard.instantiateViewController(withIdentifier: "SaveVideoVC") as? SaveVideoVC else {
            print("Failed to instantiate SaveVideoVC")
            showAlert(message: "Failed to load save screen")
            return
        }
        
        saveVideoVC.videoURL = videoURL
        saveVideoVC.titleScreen = "Merge Video".localized(LocalizationService.shared.language)
        
        // Push to navigation controller
        navigationController.pushViewController(saveVideoVC, animated: true)
    }
    
    private func saveVideoToPhotos(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self?.showSuccessAlert()
                            // Cleanup temp file
                            try? FileManager.default.removeItem(at: videoURL)
                        } else {
                            self?.showAlert(message: "Save failed: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self?.showAlert(message: "Please enable photo library access in Settings".localized(LocalizationService.shared.language))
                }
            default:
                break
            }
        }
    }
    
    private func showLoadingIndicator() {
        let alert = UIAlertController(title: nil, message: "Merging Videos...".localized(LocalizationService.shared.language), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    private func hideLoadingIndicator() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success".localized(LocalizationService.shared.language),
                                    message: "Video merged and saved to Photos!".localized(LocalizationService.shared.language),
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error".localized(LocalizationService.shared.language), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Button Actions
extension MergeVideoVC {
    @IBAction func backButtonAction(_ sender: UIButton) {
        player?.pause()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func mergeVideoButtonAction(_ sender: UIButton) {
        exportMergedVideo()
    }
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlaying {
            pauseVideo()
        } else {
            // If at the end, seek to start of range
            if currentPlaybackTime.seconds >= rangeSlider.upperValue {
                seekToTime(CMTime(seconds: rangeSlider.lowerValue, preferredTimescale: 600))
            }
            playVideo()
        }
    }
    
    @IBAction func tapOnVideoLayer(_ sender: UITapGestureRecognizer) {
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }
}
