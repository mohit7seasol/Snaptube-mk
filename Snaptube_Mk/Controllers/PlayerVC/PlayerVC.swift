//
//  PlayerVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 24/11/25.
//

import UIKit
import AVFoundation
import Photos

class PlayerVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var videoAccessView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var startDurationLabel: UILabel!
    @IBOutlet weak var endDurationLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // Video properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlaying = false
    var timeObserver: Any?
    
    // Data properties
    var mediaAssets: [PHAsset] = []
    var currentAssetIndex: Int = 0
    var currentAsset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupVideoPlayer()
        loadCurrentAsset()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = previewView.bounds
    }
    
    deinit {
        // Cleanup
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUI() {
        titleLabel.text = "Media Player".localized(LocalizationService.shared.language)
        titleLabel.textColor = .white
        
        // Setup video slider
        setupVideoSlider()
        
        // Initially hide video controls until we know media type
        videoAccessView.isHidden = true
        previewImageView.isHidden = true
        
        // Setup buttons with custom images
        playButton.setImage(UIImage(named: "play_local"), for: .normal)
        nextButton.setImage(UIImage(named: "next"), for: .normal)
        previousButton.setImage(UIImage(named: "previous"), for: .normal)
        
        // Update navigation buttons state
        updateNavigationButtons()
        setLoca()
    }
    
    func setLoca() {
        self.titleLabel.text = "Photo".localized(LocalizationService.shared.language)
    }
    private func setupVideoSlider() {
        videoSlider.minimumValue = 0
        videoSlider.maximumValue = 1
        videoSlider.value = 0
        videoSlider.setThumbImage(createThumbImage(), for: .normal)
        
        // Set gradient tint color for slider - matching the uploaded image
        if let gradientImage = createGradientImage(size: CGSize(width: 300, height: 4)) {
            videoSlider.minimumTrackTintColor = UIColor(patternImage: gradientImage)
        }

        videoSlider.maximumTrackTintColor = UIColor.darkGray
    }
    
    private func createThumbImage() -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createGradientImage(size: CGSize) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        
        // Gradient colors matching the uploaded image (blue to purple gradient)
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor,    // Blue
            UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0).cgColor   // Purple
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.cornerRadius = 2
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        gradientLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func setupVideoPlayer() {
        // Remove existing player layer
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        
        // Create new player
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = previewView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            previewView.layer.addSublayer(playerLayer)
        }
        
        // Add observer for video end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    private func loadCurrentAsset() {
        guard currentAssetIndex < mediaAssets.count else { return }
        
        currentAsset = mediaAssets[currentAssetIndex]
        
        if let asset = currentAsset {
            if asset.mediaType == .video {
                loadVideoAsset(asset)
            } else if asset.mediaType == .image {
                loadImageAsset(asset)
            }
        }
    }
    
    private func loadVideoAsset(_ asset: PHAsset) {
        self.titleLabel.text = "Video".localized(LocalizationService.shared.language)
        videoAccessView.isHidden = false
        previewImageView.isHidden = true
        
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (avAsset, _, _) in
            DispatchQueue.main.async {
                if let avAsset = avAsset {
                    self?.setupVideoPlayback(avAsset)

                    // 🔥 Extract first frame and apply gradient color
                    if let thumbnail = self?.getThumbnail(from: avAsset) {
                        self?.setSliderColorUsing(image: thumbnail)
                    }
                }
            }
        }
    }
    
    func getThumbnail(from asset: AVAsset) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    private func loadImageAsset(_ asset: PHAsset) {
        self.titleLabel.text = "Photo".localized(LocalizationService.shared.language)
        videoAccessView.isHidden = true
        previewImageView.isHidden = false
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        let targetSize = CGSize(
            width: previewImageView.bounds.width * UIScreen.main.scale,
            height: previewImageView.bounds.height * UIScreen.main.scale
        )
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] (image, _) in
            DispatchQueue.main.async {
                if let image = image {
                    self?.previewImageView.image = image
                    // 🔥 Update slider gradient using uploaded image
                    self?.setSliderColorUsing(image: image)
                }
            }
        }
    }
    
    private func setupVideoPlayback(_ avAsset: AVAsset) {
        guard let player = player else { return }
        
        // Remove previous time observer
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        let playerItem = AVPlayerItem(asset: avAsset)
        player.replaceCurrentItem(with: playerItem)
        
        // Setup time observer for slider
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1, timescale: 30),
            queue: .main
        ) { [weak self] time in
            self?.updateVideoProgress(time: time, duration: avAsset.duration)
        }
        
        // Setup duration labels
        let duration = avAsset.duration.seconds
        endDurationLabel.text = formatTime(duration)
        startDurationLabel.text = "00:00"
        
        // Reset slider
        videoSlider.value = 0
        
        // Auto-play video
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playVideo()
        }
    }
    
    private func updateVideoProgress(time: CMTime, duration: CMTime) {
        let currentTime = time.seconds
        let totalDuration = duration.seconds
        
        guard totalDuration.isFinite && !totalDuration.isNaN && totalDuration > 0 else { return }
        
        let progress = Float(currentTime / totalDuration)
        videoSlider.value = progress
        startDurationLabel.text = formatTime(currentTime)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN else { return "00:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateNavigationButtons() {
        previousButton.isEnabled = true
        nextButton.isEnabled = true
        
        previousButton.alpha = 1.0
        nextButton.alpha = 1.0
    }
    
    private func playVideo() {
        player?.play()
        isPlaying = true
        playButton.setImage(UIImage(named: "pause_local"), for: .normal)
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
        playButton.setImage(UIImage(named: "play_local"), for: .normal)
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        // Reset video to beginning when it ends
        player?.seek(to: CMTime.zero)
        isPlaying = false
        playButton.setImage(UIImage(named: "play_local"), for: .normal)
        videoSlider.value = 0
        startDurationLabel.text = "00:00"
    }
    
    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        present(alert, animated: true)
    }
    
    private func shareMedia() {
        guard let asset = currentAsset else { return }
        
        if asset.mediaType == .image {
            // Share image
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] (image, _) in
                DispatchQueue.main.async {
                    if let image = image {
                        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                        self?.present(activityVC, animated: true)
                    }
                }
            }
        } else if asset.mediaType == .video {
            // Share video
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: options
            ) { [weak self] (avAsset, _, _) in
                DispatchQueue.main.async {
                    if let urlAsset = avAsset as? AVURLAsset {
                        let activityVC = UIActivityViewController(activityItems: [urlAsset.url], applicationActivities: nil)
                        self?.present(activityVC, animated: true)
                    }
                }
            }
        }
    }
    
    private func deleteCurrentAsset() {
        guard let asset = currentAsset else { return }
        
        let alert = UIAlertController(
            title: "Delete Media".localized(LocalizationService.shared.language),
            message: "Are you sure you want to delete this media?".localized(LocalizationService.shared.language),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete".localized(LocalizationService.shared.language), style: .destructive) { [weak self] _ in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.mediaAssets.remove(at: self?.currentAssetIndex ?? 0)
                        self?.navigateAfterDeletion()
                    } else {
                        self?.showMessage("Failed to delete media: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func navigateAfterDeletion() {
        if mediaAssets.isEmpty {
            // No more assets, go back
            self.navigationController?.popViewController(animated: true)
        } else {
            // Adjust current index and load next asset
            if currentAssetIndex >= mediaAssets.count {
                currentAssetIndex = mediaAssets.count - 1
            }
            loadCurrentAsset()
            updateNavigationButtons()
        }
    }
    func dominantColors(from image: UIImage) -> [UIColor] {
        guard let inputImage = CIImage(image: image) else { return [.white, .white] }

        let parameters: [String : Any] = [
            kCIInputImageKey: inputImage,
            "inputExtent": CIVector(cgRect: inputImage.extent),
            "inputCount": 2,
            "inputScale": 1.0,
            "inputIgnoreBlack": false
        ]

        guard let filter = CIFilter(name: "CIAreaMaximumChromaticity", parameters: parameters),
              let outputImage = filter.outputImage else {
            return [.white, .white]
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        let color1 = UIColor(red: CGFloat(bitmap[0]) / 255,
                             green: CGFloat(bitmap[1]) / 255,
                             blue: CGFloat(bitmap[2]) / 255,
                             alpha: 1)

        return [
            color1,
            color1.withAlphaComponent(0.4)
        ]
    }
    func setSliderColorUsing(image: UIImage) {

        videoSlider.layoutIfNeeded()   // ensures correct frame size

        let sliderWidth = videoSlider.bounds.width
        let sliderHeight: CGFloat = 4

        let colors = dominantColors(from: image)

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: sliderWidth, height: sliderHeight)
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        UIGraphicsBeginImageContextWithOptions(gradient.frame.size, false, 0.0)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let gradientImg = gradientImg {
            videoSlider.minimumTrackTintColor = UIColor(patternImage: gradientImg)
        }
    }

}

// MARK: - Button Action's
extension PlayerVC {
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        let nextIndex = currentAssetIndex + 1
        
        guard nextIndex < mediaAssets.count else {
            showMessage("No next video available".localized(LocalizationService.shared.language))
            return
        }

        let nextAsset = mediaAssets[nextIndex]

        // Check if asset is video
        if nextAsset.mediaType != .video {
            showMessage("Next media is not a video".localized(LocalizationService.shared.language))
            return
        }

        currentAssetIndex = nextIndex
        loadCurrentAsset()
        updateNavigationButtons()
    }
    
    @IBAction func previousButtonAction(_ sender: UIButton) {
        let previousIndex = currentAssetIndex - 1
        
        guard previousIndex >= 0 else {
            showMessage("No previous video available".localized(LocalizationService.shared.language))
            return
        }

        let previousAsset = mediaAssets[previousIndex]

        if previousAsset.mediaType != .video {
            showMessage("Previous media is not a video".localized(LocalizationService.shared.language))
            return
        }

        currentAssetIndex = previousIndex
        loadCurrentAsset()
        updateNavigationButtons()
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton) {
        shareMedia()
    }
    
    @IBAction func deleteButtonAction(_ sender: UIButton) {
        deleteCurrentAsset()
    }
    
    @IBAction func videoSliderValueChanged(_ sender: UISlider) {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        let duration = currentItem.duration.seconds
        let seekTime = Double(sender.value) * duration
        
        player.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1000))
    }
}
