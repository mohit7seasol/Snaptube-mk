//
//  ReverseVideoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 22/11/25.
//

import UIKit
import Photos
import AVFoundation
import Lottie

class ReverseVideoVC: UIViewController {
    
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var reverseVideoPreView: UIView!
    @IBOutlet weak var startTimeVideoLabel: UILabel!
    @IBOutlet weak var endTimeVideoLabel: UILabel!
    @IBOutlet weak var reverseVideoButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lottieAnimationView: UIView!
    @IBOutlet weak var lottieView: UIView!
    
    var videoURL: URL?
    var originalAsset: PHAsset?
    
    // Video player properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlaying = false
    var asset: AVAsset?
    
    // Thumbnail preview
    var imageFrameView: UIView!
    var rangeSlider: RangeSlider!
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    // Lottie animation
    var loadingAnimation: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupThumbnailView()
        loadVideo()
        
        // Initially hide the lottieView
        lottieView.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPreviewView.bounds
        rangeSlider?.frame = reverseVideoPreView.bounds
        imageFrameView?.frame = reverseVideoPreView.bounds
    }
    
    deinit {
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        reverseVideoButton.layer.cornerRadius = 8
        playButton.layer.cornerRadius = 8
        
        // Setup video preview layer
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoPreviewView.bounds
        videoPreviewView.layer.addSublayer(playerLayer!)
        
        titleLabel.text = "Reverse Video".localized(LocalizationService.shared.language)
        self.reverseVideoButton.setTitle("Reverse Video".localized(LocalizationService.shared.language), for: .normal)
        
        // Setup Lottie view
        lottieView.isHidden = true
        lottieView.layer.cornerRadius = 8
        lottieView.layer.masksToBounds = true
    }
    
    private func setupThumbnailView() {
        // Create image frame view for thumbnails
        imageFrameView = UIView()
        imageFrameView.frame = CGRect(x: 0, y: 0, width: reverseVideoPreView.frame.width, height: reverseVideoPreView.frame.height)
        imageFrameView.layer.cornerRadius = 5.0
        imageFrameView.layer.borderWidth = 1.0
        imageFrameView.layer.borderColor = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        reverseVideoPreView.addSubview(imageFrameView)
        
        setupRangeSlider()
    }
    
    private func setupRangeSlider() {
        // Remove existing slider
        let subViews = reverseVideoPreView.subviews
        for subview in subViews {
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        rangeSlider = RangeSlider(frame: reverseVideoPreView.bounds)
        reverseVideoPreView.addSubview(rangeSlider)
        rangeSlider.tag = 1000
        
        // Range slider styling
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
        reverseVideoPreView.bringSubviewToFront(imageFrameView)
        reverseVideoPreView.bringSubviewToFront(rangeSlider)
    }
    
    private func loadVideo() {
        if let videoURL = videoURL {
            // Load from URL
            asset = AVURLAsset(url: videoURL)
            setupVideoPlayer()
        } else if let originalAsset = originalAsset {
            // Load from PHAsset
            loadAsset(originalAsset)
        }
    }
    
    private func loadAsset(_ asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
            DispatchQueue.main.async {
                if let avAsset = avAsset {
                    self?.asset = avAsset
                    self?.setupVideoPlayer()
                } else {
                    self?.showAlert(message: "Failed to load video")
                }
            }
        }
    }
    
    private func setupVideoPlayer() {
        guard let asset = asset else { return }
        
        thumbTime = asset.duration
        thumbtimeSeconds = Int(CMTimeGetSeconds(thumbTime))
        
        // Create player item
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer?.player = player
        
        // Setup range slider
        let totalDuration = asset.duration.seconds
        rangeSlider.maximumValue = totalDuration
        rangeSlider.upperValue = totalDuration
        
        // Create thumbnail frames
        createImageFrames()
        
        updateTimeLabels()
        setupPlaybackObserver()
        
        // Show UI elements
        startTimeVideoLabel.isHidden = false
        endTimeVideoLabel.isHidden = false
        reverseVideoButton.isHidden = false
    }
    
    // MARK: - Creating Frame Images
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
    
    private func setupPlaybackObserver() {
        player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self = self else { return }
            
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
        playButton.alpha = 0.0
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
        playButton.setTitle("Play", for: .normal)
        playButton.alpha = 1.0
    }
    
    // MARK: - Reverse Video Functionality
    private func reverseVideo() {
        guard let asset = asset else {
            showAlert(message: "No video to reverse")
            return
        }
        
        let startTime = CMTime(seconds: rangeSlider.lowerValue, preferredTimescale: 600)
        let endTime = CMTime(seconds: rangeSlider.upperValue, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // Show loading animation
        showLoadingAnimation()
        reverseVideoButton.isEnabled = false
        
        // Perform reverse operation on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.createReversedVideo(asset: asset, timeRange: timeRange) { reversedURL in
                DispatchQueue.main.async {
                    self?.hideLoadingAnimation()
                    self?.reverseVideoButton.isEnabled = true
                    
                    if let reversedURL = reversedURL {
                        self?.navigateToSaveVideoVC(with: reversedURL)
                    } else {
                        self?.showAlert(message: "Failed to reverse video")
                    }
                }
            }
        }
    }
    
    func createReversedVideo(asset: AVAsset, timeRange: CMTimeRange, completion: @escaping (URL?) -> Void) {

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }

        let readerSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerSettings)
        readerOutput.alwaysCopiesSampleData = true

        guard let reader = try? AVAssetReader(asset: asset) else {
            completion(nil)
            return
        }

        reader.timeRange = timeRange
        reader.add(readerOutput)
        reader.startReading()

        var samples: [CMSampleBuffer] = []

        while let sample = readerOutput.copyNextSampleBuffer() {
            var copied: CMSampleBuffer?
            if CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sample, sampleBufferOut: &copied) == noErr,
               let cp = copied {
                samples.append(cp)
            }
        }

        reader.cancelReading()

        samples.reverse()

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("reversed_segment.mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(nil)
            return
        }

        let writerSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoHeightKey: videoTrack.naturalSize.height
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: writerSettings)
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: nil
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))
        var currentTime = CMTime.zero

        DispatchQueue.global(qos: .userInitiated).async {
            for sample in samples {
                if let pixelBuffer = CMSampleBufferGetImageBuffer(sample) {
                    while !writerInput.isReadyForMoreMediaData {
                        usleep(1000)
                    }
                    adaptor.append(pixelBuffer, withPresentationTime: currentTime)
                    currentTime = currentTime + frameDuration
                }
            }

            writerInput.markAsFinished()
            writer.finishWriting {
                completion(writer.status == .completed ? outputURL : nil)
            }
        }
    }

    private func generateFrame(asset: AVAsset, time: CMTime) throws -> CGImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.videoComposition = nil
        return try generator.copyCGImage(at: time, actualTime: nil)
    }

    private func pixelBuffer(from image: CGImage, size: CGSize) -> CVPixelBuffer {
        var pxBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(size.width),
                            Int(size.height),
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pxBuffer)

        let buffer = pxBuffer!
        CVPixelBufferLockBaseAddress(buffer, [])

        let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        ctx?.draw(image, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
    
    private func createOutputURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("reversed_video_\(Int(Date().timeIntervalSince1970)).mp4")
    }
    
    // MARK: - Lottie Animation
    private func showLoadingAnimation() {
        // First unhide the lottieView
        lottieView.isHidden = false
        
        // Create and configure Lottie animation
        loadingAnimation = LottieAnimationView(name: "please wait gif")
        loadingAnimation?.frame = CGRect(x: 0, y: 0, width: lottieView.bounds.width, height: lottieView.bounds.height)
        loadingAnimation?.center = CGPoint(x: lottieView.bounds.midX, y: lottieView.bounds.midY)
        loadingAnimation?.contentMode = .scaleAspectFit
        loadingAnimation?.loopMode = .loop
        loadingAnimation?.animationSpeed = 1.0
        
        if let animationView = loadingAnimation {
            lottieView.addSubview(animationView)
            animationView.play()
        }
        
        // Disable user interaction during processing
        view.isUserInteractionEnabled = false
        
        // Bring lottieView to front
        view.bringSubviewToFront(lottieView)
    }
    
    private func hideLoadingAnimation() {
        // Stop and remove animation
        loadingAnimation?.stop()
        loadingAnimation?.removeFromSuperview()
        loadingAnimation = nil
        
        // Hide the lottieView when animation finishes
        lottieView.isHidden = true
        
        // Re-enable user interaction
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - Navigation
    private func navigateToSaveVideoVC(with videoURL: URL) {
        guard let navigationController = self.navigationController else {
            showAlert(message: "Navigation unavailable")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let saveVideoVC = storyboard.instantiateViewController(withIdentifier: "SaveVideoVC") as? SaveVideoVC else {
            showAlert(message: "Failed to load save screen")
            return
        }
        
        saveVideoVC.videoURL = videoURL
        saveVideoVC.titleScreen = "Reverse Video".localized(LocalizationService.shared.language)
        
        navigationController.pushViewController(saveVideoVC, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error".localized(LocalizationService.shared.language), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Button Actions
extension ReverseVideoVC {
    @IBAction func reverseVideoButtomAction(_ sender: UIButton) {
        reverseVideo()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        player?.pause()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlaying {
            pauseVideo()
        } else {
            // If at the end, seek to start of range
            if let currentTime = player?.currentTime(), currentTime.seconds >= rangeSlider.upperValue {
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
