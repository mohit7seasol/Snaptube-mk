//
//  CropVideoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 20/11/25.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import Photos
import SVProgressHUD

class CropVideoVC: UIViewController {
    
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var trimVideoView: UIView!
    @IBOutlet weak var startTimeVideoLabel: UILabel!
    @IBOutlet weak var endTimeVideoLabel: UILabel!
    @IBOutlet weak var SelectVideoFrameRatioCollectionView: UICollectionView!
    @IBOutlet weak var cropVideoButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    // Video editing mode
    var isCroppedVideo = true // true for crop, false for speed
    
    // Video trimming properties
    var isPlaying = true
    var isSliderEnd = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    var exportSession: AVAssetExportSession? = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    var url: NSURL! = nil
    var videoURL: URL?
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache: NSCache<AnyObject, AnyObject>!
    var rangeSlider: RangeSlider! = nil
    
    
    
    // Frame ratio properties for crop
    let aspectRatios: [(String, Double, Double)] = [
        ("Free", 0, 0),
        ("1:1", 1, 1),
        ("2:3", 2, 3),
        ("3:2", 3, 2),
        ("4:5", 4, 5),
        ("5:4", 5, 4),
        ("16:9", 16, 9),
        ("9:16", 9, 16)
    ]
    
    // Speed properties for speed video
    let speedOptions: [(String, Float)] = [
        ("0.1x", 0.1),
        ("0.5x", 0.5),
        ("1x", 1.0),
        ("2x", 2.0),
        ("3x", 3.0),
        ("4x", 4.0)
    ]
    
    var selectedAspectRatioIndex = 0
    var selectedSpeedIndex = 2 // Default to 1x
    var imageFrameView: UIView!
    var originalAsset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVideoFromURL()
        setupProgressHUD()
        
        // Set button visibility based on mode
        updateButtonVisibility()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop playback
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        // Remove layer
        playerLayer?.removeFromSuperlayer()

        // Invalidate timer if running
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil

        // Remove notifications
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        player?.pause()
        player = nil
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        SelectVideoFrameRatioCollectionView.reloadData()
    }
    
    // MARK: - Update Button Visibility
    private func updateButtonVisibility() {
        if isCroppedVideo {
            // Crop mode: hide nextButton, unhide cropVideoButton
            self.nextButton.isHidden = true
            self.cropVideoButton.isHidden = false
        } else {
            // Speed mode: hide cropVideoButton, unhide nextButton
            self.nextButton.isHidden = false
            self.cropVideoButton.isHidden = true
        }
    }
    
    func setupUI() {
        setupCollectionView()
        setupVideoViews()
        
        let navTitle = isCroppedVideo ? "Crop Video".localized(LocalizationService.shared.language) : "Speed Video".localized(LocalizationService.shared.language)
        self.titleLabel.text = navTitle
        
        // Update button title based on mode
        let buttonTitle = isCroppedVideo ? "Crop Video".localized(LocalizationService.shared.language) : "Speed Video".localized(LocalizationService.shared.language)
        cropVideoButton.setTitle(buttonTitle, for: .normal)
        cropVideoButton.layer.cornerRadius = 5.0
        
        let setButtonIc = isCroppedVideo ? "crop_video" : "speed_ic"
        cropVideoButton.setImage(UIImage(named: setButtonIc), for: .normal)
        
        // Set initial button visibility
        updateButtonVisibility()
        
        // Style play button
        playButton.alpha = 0.0
        
        // Update labels for speed mode
        if !isCroppedVideo {
            startTimeVideoLabel.text = "Speed:".localized(LocalizationService.shared.language)
            endTimeVideoLabel.text = "1x" // Initial speed
        }
        
        // Initialize cache
        cache = NSCache()
        player = AVPlayer()
    }
    
    func setupProgressHUD() {
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(2.0)
    }
    
    // MARK: - Load Video from URL
    func loadVideoFromURL() {
        guard let videoURL = videoURL else { return }
        
        url = videoURL as NSURL
        asset = AVURLAsset(url: videoURL)
        
        thumbTime = asset.duration
        thumbtimeSeconds = Int(CMTimeGetSeconds(thumbTime))
        
        viewAfterVideoIsPicked()
        
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPreviewView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        player.actionAtItemEnd = .none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnVideoLayer))
        videoPreviewView.addGestureRecognizer(tap)
        
        videoPreviewView.layer.addSublayer(playerLayer)
        setupPlayerObservers()
        player.play()
        
        if isCroppedVideo {
            // Apply default aspect ratio for crop mode
            applyAspectRatio(aspectRatios[selectedAspectRatioIndex].1, aspectRatios[selectedAspectRatioIndex].2)
        }
    }
    
    func setupVideoViews() {
        // Create image frame view for thumbnails
        imageFrameView = UIView()
        imageFrameView.frame = CGRect(x: 0, y: 0, width: trimVideoView.frame.width, height: trimVideoView.frame.height)
        imageFrameView.layer.cornerRadius = 5.0
        imageFrameView.layer.borderWidth = 1.0
        imageFrameView.layer.borderColor = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        trimVideoView.addSubview(imageFrameView)
        
        // Hide labels initially
        startTimeVideoLabel.isHidden = true
        endTimeVideoLabel.isHidden = true
    }
    
    func setupCollectionView() {
        SelectVideoFrameRatioCollectionView.delegate = self
        SelectVideoFrameRatioCollectionView.dataSource = self
        SelectVideoFrameRatioCollectionView.register(UINib(nibName: "CropVideoFrameRatioCell", bundle: nil), forCellWithReuseIdentifier: "CropVideoFrameRatioCell")
        
        if let layout = SelectVideoFrameRatioCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 60, height: 32)
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
        }
        
        // Select first item by default
        let defaultIndexPath = IndexPath(item: isCroppedVideo ? 0 : 2, section: 0) // 0 for crop, 2 for speed (1x)
        SelectVideoFrameRatioCollectionView.selectItem(at: defaultIndexPath, animated: false, scrollPosition: .left)
    }
    
    func viewAfterVideoIsPicked() {
        // Remove player if already exists
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
        }
        
        // Always create image frames for both modes
        createImageFrames()
        
        // Unhide buttons and view after video selection
        cropVideoButton.isHidden = false
        startTimeVideoLabel.isHidden = false
        endTimeVideoLabel.isHidden = false
        trimVideoView.isHidden = false // Always show trim view
        
        isSliderEnd = true
        startTimeVideoLabel.text = formatTime(0.0)
        
        if isCroppedVideo {
            // For crop mode, show original duration and create range slider
            endTimeVideoLabel.text = formatTime(Double(thumbtimeSeconds))
            createRangeSlider()
            setupCropModeUI()
        } else {
            // For speed mode, show speed preview and setup speed UI
            let initialSpeed = speedOptions[selectedSpeedIndex].1
            applySpeedPreview(initialSpeed)
            setupSpeedModeUI()
        }
        
        // Update button visibility after video is loaded
        updateButtonVisibility()
    }
    
    private func setupSpeedModeUI() {
        // Hide range slider for speed mode
        rangeSlider?.isHidden = true
        
        // Update labels for speed mode
        startTimeVideoLabel.text = "Speed:".localized(LocalizationService.shared.language)
        
        let selectedSpeed = speedOptions[selectedSpeedIndex]
        let originalDuration = CMTimeGetSeconds(asset.duration)
        let newDuration = originalDuration / Double(selectedSpeed.1)
        
        endTimeVideoLabel.text = "\(selectedSpeed.0) (\(formatTime(newDuration)))"
        
        // Create speed indicator view instead of range slider
        createSpeedIndicatorView()
    }
    
    // MARK: - Create Speed Indicator View
    private func createSpeedIndicatorView() {
        // Remove existing speed indicator
        let subViews = trimVideoView.subviews
        for subview in subViews {
            if subview.tag == 2000 {
                subview.removeFromSuperview()
            }
        }
        
        // Create speed indicator view
        let speedIndicatorView = UIView(frame: trimVideoView.bounds)
        speedIndicatorView.tag = 2000
        speedIndicatorView.backgroundColor = .clear
        
        // Add speed info label
        let speedLabel = UILabel()
        speedLabel.text = "Speed Adjustment"
        speedLabel.textColor = .white
        speedLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        speedLabel.textAlignment = .center
        
        // Add current speed display
        let currentSpeedLabel = UILabel()
        currentSpeedLabel.text = "Current: \(speedOptions[selectedSpeedIndex].0)"
        currentSpeedLabel.textColor = .systemBlue
        currentSpeedLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        currentSpeedLabel.textAlignment = .center
        
        // Add duration info
        let durationLabel = UILabel()
        let originalDuration = CMTimeGetSeconds(asset.duration)
        let newDuration = originalDuration / Double(speedOptions[selectedSpeedIndex].1)
        durationLabel.text = "Duration: \(formatTime(newDuration))"
        durationLabel.textColor = .lightGray
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        durationLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [speedLabel, currentSpeedLabel, durationLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        
        speedIndicatorView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: speedIndicatorView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: speedIndicatorView.centerYAnchor)
        ])
        
        trimVideoView.addSubview(speedIndicatorView)
        
        // Bring image frames to front so they're visible behind the speed indicator
        trimVideoView.bringSubviewToFront(imageFrameView)
    }
    
    // MARK: - Setup UI for Different Modes
    private func setupCropModeUI() {
        // Show range slider and normal time labels for crop mode
        rangeSlider?.isHidden = false
        startTimeVideoLabel.text = "00:00"
        
        // Update labels for crop mode
        startTimeVideoLabel.text = formatTime(0.0)
        endTimeVideoLabel.text = formatTime(Double(thumbtimeSeconds))
    }
    
    // MARK: - Creating Frame Images (Only for Crop Mode)
    func createImageFrames() {
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
        
        // Loop for 6 number of frames
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
                // Set placeholder for failed image generation
                imageButton.backgroundColor = UIColor.darkGray
            }
            
            startXPosition += xPositionForEach
            startTime += thumbAvg
            imageButton.isUserInteractionEnabled = false
            imageButton.imageView?.contentMode = .scaleAspectFill
            imageFrameView.addSubview(imageButton)
        }
    }

    // MARK: - Create Range Slider (Only for Crop Mode)
    func createRangeSlider() {
        // Remove slider if already present
        let subViews = trimVideoView.subviews
        for subview in subViews {
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        rangeSlider = RangeSlider(frame: trimVideoView.bounds)
        trimVideoView.addSubview(rangeSlider)
        rangeSlider.tag = 1000
        
        // Range slider action
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        
        let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.rangeSlider.trackHighlightTintColor = UIColor.clear
            self.rangeSlider.curvaceousness = 1.0
        }
    }
    
    // MARK: - Setup Player Observers
    private func setupPlayerObservers() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(playerItemDidReachEnd(notification:)),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: player.currentItem)
        
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60),
                                      queue: .main) { [weak self] time in
            self?.handlePlaybackProgress(time: time)
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        player.seek(to: CMTime.zero)
        isPlaying = false
        updatePlayButtonVisibility()
    }

    private func handlePlaybackProgress(time: CMTime) {
        if player.rate == 0 && player.error == nil {
            isPlaying = false
            updatePlayButtonVisibility()
        }
    }
    
    // MARK: - Range Slider Delegate (Only for Crop Mode)
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        player.pause()
        
        if isSliderEnd {
            rangeSlider.minimumValue = 0.0
            rangeSlider.maximumValue = Double(thumbtimeSeconds)
            rangeSlider.upperValue = Double(thumbtimeSeconds)
            isSliderEnd = !isSliderEnd
        }
        
        startTimeVideoLabel.text = formatTime(rangeSlider.lowerValue)
        endTimeVideoLabel.text = formatTime(rangeSlider.upperValue)
        
        if rangeSlider.lowerLayerSelected {
            seekVideo(toPos: CGFloat(rangeSlider.lowerValue))
        } else {
            seekVideo(toPos: CGFloat(rangeSlider.upperValue))
        }
    }
    
    // MARK: - Format Time
    private func formatTime(_ time: Double) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "00:%02d", seconds)
        }
    }
    
    private func formatSpeedDuration(_ originalDuration: Double, speed: Float) -> String {
        let newDuration = originalDuration / Double(speed)
        return formatTime(newDuration)
    }
    
    // MARK: - Seek Video
    func seekVideo(toPos pos: CGFloat) {
        videoPlaybackPosition = pos
        let time = CMTimeMakeWithSeconds(Float64(videoPlaybackPosition), preferredTimescale: player.currentTime().timescale)
        player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if pos == CGFloat(thumbtimeSeconds) {
            player.pause()
        }
    }
    
    // MARK: - Apply Speed to Video
    func applySpeedToVideo(sourceURL1: NSURL, speed: Float, completion: ((URL?) -> Void)? = nil) {
        SVProgressHUD.show(withStatus: "Applying speed...".localized(LocalizationService.shared.language))
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true) else {
            SVProgressHUD.dismiss()
            completion?(nil)
            return
        }
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
            try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("speed_\(Date().timeIntervalSince1970).mp4")
        } catch {
            print(error)
            SVProgressHUD.dismiss()
            completion?(nil)
            return
        }
        
        // Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let composition = AVMutableComposition()
        
        // Video track
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let assetTrack = asset.tracks(withMediaType: .video).first else {
            SVProgressHUD.dismiss()
            completion?(nil)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            compositionTrack.scaleTimeRange(timeRange, toDuration: CMTimeMultiplyByFloat64(asset.duration, multiplier: Float64(1.0/speed)))
            
            // Audio track
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
               let audioCompTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try audioCompTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
                audioCompTrack.scaleTimeRange(timeRange, toDuration: CMTimeMultiplyByFloat64(asset.duration, multiplier: Float64(1.0/speed)))
            }
            
            guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                SVProgressHUD.dismiss()
                completion?(nil)
                return
            }
            
            self.exportSession = export
            export.outputURL = outputURL
            export.outputFileType = .mp4
            export.shouldOptimizeForNetworkUse = true
            
            export.exportAsynchronously {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.exportSession = nil
                    
                    switch export.status {
                    case .completed:
                        completion?(export.outputURL)
                    case .failed:
                        print("Export failed: \(String(describing: export.error))")
                        if let err = export.error {
                            self.showErrorAlert(message: "Export failed: \(err.localizedDescription)")
                        }
                        completion?(nil)
                    case .cancelled:
                        print("Export cancelled")
                        SVProgressHUD.showError(withStatus: "Export cancelled".localized(LocalizationService.shared.language))
                        completion?(nil)
                    default:
                        completion?(nil)
                    }
                }
            }
            
        } catch {
            print("Error applying speed: \(error)")
            SVProgressHUD.dismiss()
            completion?(nil)
        }
    }
    
    // MARK: - Apply Speed Preview
    private func applySpeedPreview(_ speed: Float) {
        player.rate = speed
        
        // Calculate and display the new duration based on speed
        let originalDuration = CMTimeGetSeconds(asset.duration)
        let newDuration = originalDuration / Double(speed)
        
        // Update the end time label to show speed information
        if !isCroppedVideo {
            endTimeVideoLabel.text = "\(speedOptions[selectedSpeedIndex].0) (\(formatTime(newDuration)))"
            
            // Update speed indicator if it exists
            if let speedIndicatorView = trimVideoView.viewWithTag(2000),
               let stackView = speedIndicatorView.subviews.first as? UIStackView,
               stackView.arrangedSubviews.count >= 3 {
                
                let currentSpeedLabel = stackView.arrangedSubviews[1] as! UILabel
                currentSpeedLabel.text = "Current: \(speedOptions[selectedSpeedIndex].0)"
                
                let durationLabel = stackView.arrangedSubviews[2] as! UILabel
                durationLabel.text = "Duration: \(formatTime(newDuration))"
            }
        }
    }
    // MARK: - Show Error Alert
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Update Play Button Visibility
    private func updatePlayButtonVisibility() {
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = self.isPlaying ? 0.0 : 1.0
        }
    }
    
    private func navigateToSaveVideoVC(with videoURL: URL) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let saveVideoVC = storyboard.instantiateViewController(withIdentifier: "SaveVideoVC") as? SaveVideoVC {
            saveVideoVC.videoURL = videoURL
            let title = isCroppedVideo ? "Crop Video".localized(LocalizationService.shared.language) : "Speed Video".localized(LocalizationService.shared.language)
            saveVideoVC.titleScreen = title
            self.navigationController?.pushViewController(saveVideoVC, animated: true)
        }
    }
    
    // MARK: - Tap on Video Layer
    @objc func tapOnVideoLayer(tap: UITapGestureRecognizer) {
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        isPlaying = !isPlaying
        updatePlayButtonVisibility()
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying = !isPlaying
        updatePlayButtonVisibility()
    }
    
    // MARK: - Main Action Button (Crop or Speed)
    @IBAction func cropVideoButtonAction(_ sender: UIButton) {
        if isCroppedVideo {
            // Crop Video functionality
            cropVideoButton.isEnabled = false
            
            guard let slider = rangeSlider else {
                showErrorAlert(message: "Video not properly loaded".localized(LocalizationService.shared.language))
                cropVideoButton.isEnabled = true
                return
            }
            
            let start = Float(slider.lowerValue)
            let end = Float(slider.upperValue)
            
            guard start >= 0, end > start else {
                showErrorAlert(message: "Please select a valid time range".localized(LocalizationService.shared.language))
                cropVideoButton.isEnabled = true
                return
            }
            
            SVProgressHUD.show(withStatus: "Processing video...".localized(LocalizationService.shared.language))
            
            cropVideoWithAspectRatio(sourceURL1: url, startTime: start, endTime: end) { [weak self] outputURL in
                DispatchQueue.main.async {
                    self?.cropVideoButton.isEnabled = true
                    SVProgressHUD.dismiss()
                    
                    guard let self = self, let outputURL = outputURL else {
                        self?.showErrorAlert(message: "Failed to crop video".localized(LocalizationService.shared.language))
                        return
                    }
                    
                    self.navigateToSaveVideoVC(with: outputURL)
                }
            }
        } else {
            // Speed Video functionality
            cropVideoButton.isEnabled = false
            SVProgressHUD.show(withStatus: "Applying speed...".localized(LocalizationService.shared.language))
            
            let selectedSpeed = speedOptions[selectedSpeedIndex].1
            applySpeedToVideo(sourceURL1: url, speed: selectedSpeed) { [weak self] outputURL in
                DispatchQueue.main.async {
                    self?.cropVideoButton.isEnabled = true
                    SVProgressHUD.dismiss()
                    
                    guard let self = self, let outputURL = outputURL else {
                        self?.showErrorAlert(message: "Failed to apply speed".localized(LocalizationService.shared.language))
                        return
                    }
                    
                    self.navigateToSaveVideoVC(with: outputURL)
                }
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Apply Aspect Ratio (Only for Crop Mode)
    func applyAspectRatio(_ widthRatio: Double, _ heightRatio: Double) {
        guard playerLayer != nil else { return }
        
        if widthRatio == 0 && heightRatio == 0 {
            playerLayer.videoGravity = .resizeAspect
            playerLayer.frame = videoPreviewView.bounds
        } else {
            playerLayer.videoGravity = .resizeAspectFill
            
            let aspectRatio = CGFloat(widthRatio / heightRatio)
            let containerSize = videoPreviewView.bounds.size
            
            var newWidth = containerSize.width
            var newHeight = containerSize.height
            
            if aspectRatio > containerSize.width / containerSize.height {
                newHeight = containerSize.width / aspectRatio
            } else {
                newWidth = containerSize.height * aspectRatio
            }
            
            let newSize = CGSize(width: newWidth, height: newHeight)
            let newOrigin = CGPoint(
                x: (containerSize.width - newWidth) / 2,
                y: (containerSize.height - newHeight) / 2
            )
            
            UIView.animate(withDuration: 0.3) {
                self.playerLayer.frame = CGRect(origin: newOrigin, size: newSize)
            }
        }
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        // Handle next button action for speed mode
        if !isCroppedVideo {
            cropVideoButton.isEnabled = false
            SVProgressHUD.show(withStatus: "Applying speed...".localized(LocalizationService.shared.language))
            
            let selectedSpeed = speedOptions[selectedSpeedIndex].1
            applySpeedToVideo(sourceURL1: url, speed: selectedSpeed) { [weak self] outputURL in
                DispatchQueue.main.async {
                    self?.cropVideoButton.isEnabled = true
                    SVProgressHUD.dismiss()
                    
                    guard let self = self, let outputURL = outputURL else {
                        self?.showErrorAlert(message: "Failed to apply speed".localized(LocalizationService.shared.language))
                        return
                    }
                    
                    self.navigateToSaveVideoVC(with: outputURL)
                }
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension CropVideoVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isCroppedVideo ? aspectRatios.count : speedOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CropVideoFrameRatioCell", for: indexPath) as! CropVideoFrameRatioCell
        
        if isCroppedVideo {
            // Crop mode - show aspect ratios
            let ratio = aspectRatios[indexPath.row]
            cell.ratioButton.setTitle(ratio.0, for: .normal)
        } else {
            // Speed mode - show speed options
            let speed = speedOptions[indexPath.row]
            cell.ratioButton.setTitle(speed.0, for: .normal)
        }
        
        // Apply corner radius
        cell.ratioButton.layer.cornerRadius = 16
        cell.ratioButton.layer.masksToBounds = true
        
        // Remove existing gradient layers
        cell.ratioButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        // Configure appearance based on selection
        let isSelected = isCroppedVideo ? (indexPath.row == selectedAspectRatioIndex) : (indexPath.row == selectedSpeedIndex)
        
        if isSelected {
            // Selected state - gradient border
            cell.ratioButton.layer.borderWidth = 2
            cell.ratioButton.layer.borderColor = UIColor.clear.cgColor
            
            DispatchQueue.main.async {
                let gradient = CAGradientLayer()
                gradient.frame = cell.ratioButton.bounds
                gradient.colors = [UIColor(hex: "#BDA9FF").cgColor, UIColor(hex: "#FF524E").cgColor]
                gradient.startPoint = CGPoint(x: 0, y: 0.5)
                gradient.endPoint = CGPoint(x: 1, y: 0.5)
                
                let shape = CAShapeLayer()
                shape.lineWidth = 2
                shape.path = UIBezierPath(roundedRect: cell.ratioButton.bounds.insetBy(dx: 1, dy: 1), cornerRadius: 16).cgPath
                shape.strokeColor = UIColor.black.cgColor
                shape.fillColor = UIColor.clear.cgColor
                gradient.mask = shape
                
                cell.ratioButton.layer.addSublayer(gradient)
            }
            
            cell.ratioButton.setTitleColor(.white, for: .normal)
            cell.ratioButton.backgroundColor = .clear
        } else {
            // Deselected state
            cell.ratioButton.layer.borderWidth = 1
            cell.ratioButton.layer.borderColor = UIColor.lightGray.cgColor
            cell.ratioButton.setTitleColor(.lightGray, for: .normal)
            cell.ratioButton.backgroundColor = .clear
        }
        
        cell.ratioButton.setOnClickListener { [self] in
            if isCroppedVideo {
                // Crop mode functionality
                selectedAspectRatioIndex = indexPath.row
                let ratio = aspectRatios[indexPath.row]
                applyAspectRatio(ratio.1, ratio.2)
            } else {
                // Speed mode functionality
                selectedSpeedIndex = indexPath.row
                let speed = speedOptions[indexPath.row].1
                applySpeedPreview(speed)
                
                // Update the UI for speed mode
                if !isCroppedVideo {
                    setupSpeedModeUI()
                }
                
                // Show immediate feedback
                SVProgressHUD.showInfo(withStatus: "Speed: \(speedOptions[indexPath.row].0)")
                SVProgressHUD.dismiss(withDelay: 1.0)
            }
            collectionView.reloadData()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 32)
    }
}
extension CropVideoVC {
    func cropVideoWithAspectRatio(sourceURL1: NSURL, startTime: Float, endTime: Float, completion: ((URL?) -> Void)? = nil) {
        // If an export is already running, cancel it
        if let running = self.exportSession, running.status == .exporting {
            running.cancelExport()
            self.exportSession = nil
        }
        
        // Show progress HUD
        SVProgressHUD.show(withStatus: "Processing video...".localized(LocalizationService.shared.language))
        
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true) else {
            SVProgressHUD.dismiss()
            completion?(nil)
            return
        }
        
        var outputURL = documentDirectory.appendingPathComponent("output")
        do {
            try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("cropped_\(Date().timeIntervalSince1970).mp4")
        } catch {
            print(error)
            SVProgressHUD.dismiss()
            completion?(nil)
            return
        }
        
        // Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        let startTimeCM = CMTime(seconds: Double(startTime), preferredTimescale: 1000)
        let endTimeCM = CMTime(seconds: Double(endTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTimeCM, end: endTimeCM)
        
        // Selected ratio
        let selectedRatio = aspectRatios[selectedAspectRatioIndex]
        
        // Helper to start export with a given asset
        func configureAndStartExport(for exportAsset: AVAsset, timeRange: CMTimeRange, applyingTransform transformBlock: ((AVMutableComposition) -> Void)? = nil) {
            // If we need a composition apply transformBlock before creating export session
            var assetToExport: AVAsset = exportAsset
            if let transformBlock = transformBlock {
                let composition = AVMutableComposition()
                guard let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                      let assetTrack = exportAsset.tracks(withMediaType: .video).first else {
                    SVProgressHUD.dismiss()
                    completion?(nil)
                    return
                }
                
                do {
                    try compTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
                    transformBlock(composition)
                    // add audio if present
                    if let audioAssetTrack = exportAsset.tracks(withMediaType: .audio).first,
                       let audioCompTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                        try audioCompTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
                    }
                    assetToExport = composition
                } catch {
                    print("Error applying transform: \(error)")
                    SVProgressHUD.dismiss()
                    completion?(nil)
                    return
                }
            } else {
                // simple trimming: create export from original asset and set timeRange
                assetToExport = exportAsset
            }
            
            guard let export = AVAssetExportSession(asset: assetToExport, presetName: AVAssetExportPresetHighestQuality) else {
                SVProgressHUD.dismiss()
                completion?(nil)
                return
            }
            
            self.exportSession = export
            export.outputURL = outputURL
            export.outputFileType = .mp4
            export.shouldOptimizeForNetworkUse = true
            export.timeRange = timeRange
            
            export.exportAsynchronously {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.exportSession = nil
                    
                    switch export.status {
                    case .completed:
                        completion?(export.outputURL)
                    case .failed:
                        print("Export failed: \(String(describing: export.error))")
                        if let err = export.error {
                            self.showErrorAlert(message: "Export failed: \(err.localizedDescription)")
                        }
                        completion?(nil)
                    case .cancelled:
                        print("Export cancelled")
                        SVProgressHUD.showError(withStatus: "Export cancelled")
                        completion?(nil)
                    default:
                        completion?(nil)
                    }
                }
            }
        }
        
        // If aspect ratio is a fixed one (not Free) -> build composition transform
        if selectedRatio.1 != 0 && selectedRatio.2 != 0 {
            guard let assetTrack = asset.tracks(withMediaType: .video).first else {
                SVProgressHUD.dismiss()
                completion?(nil)
                return
            }
            
            let originalSize = assetTrack.naturalSize
            let targetAspectRatio = CGFloat(selectedRatio.1 / selectedRatio.2)
            let originalAspectRatio = originalSize.width / originalSize.height
            
            configureAndStartExport(for: asset, timeRange: timeRange) { composition in
                // compute transform on the composition's video track (we only set preferredTransform on the comp track)
                var transform = assetTrack.preferredTransform
                var renderSize = originalSize
                
                if targetAspectRatio > originalAspectRatio {
                    // crop height
                    renderSize.height = originalSize.width / targetAspectRatio
                    let scale = renderSize.height / originalSize.height
                    transform = transform.scaledBy(x: 1.0, y: scale)
                    let translationY = (originalSize.height - renderSize.height) / 2
                    transform = transform.translatedBy(x: 0, y: translationY)
                } else {
                    // crop width
                    renderSize.width = originalSize.height * targetAspectRatio
                    let scale = renderSize.width / originalSize.width
                    transform = transform.scaledBy(x: scale, y: 1.0)
                    let translationX = (originalSize.width - renderSize.width) / 2
                    transform = transform.translatedBy(x: translationX, y: 0)
                }
                
                // Apply transform to the first video track of the composition
                if let compVideoTrack = composition.tracks(withMediaType: .video).first {
                    compVideoTrack.preferredTransform = transform
                }
            }
        } else {
            // Free ratio — just trim
            configureAndStartExport(for: asset, timeRange: timeRange, applyingTransform: nil)
        }
    }
}
