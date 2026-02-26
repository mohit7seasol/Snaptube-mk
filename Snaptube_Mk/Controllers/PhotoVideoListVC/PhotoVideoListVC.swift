//
//  PhotoVideoListVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 18/11/25.
//

import UIKit
import Photos

enum PhotoVideoViewType {
    case normal
    case favourite
    case recentlyAdded
}

class PhotoVideoListVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "PhotosCollectionCell", bundle: nil), forCellWithReuseIdentifier: "PhotosCollectionCell")
            collectionView.register(UINib(nibName: "VideosCollectionCell", bundle: nil), forCellWithReuseIdentifier: "VideosCollectionCell")
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectMultipleVideoCountButton: UIButton!
    
    // MARK: - Variables
    var mediaType: MediaType = .all
    var albumName: String?
    var albumAssets: PHFetchResult<PHAsset>?
    var allAssets: [PHAsset] = []
    var photoEditingFeature: PhotoEditingFeatures?
    var videoEditingFeature: VideoEditingFeatures?
    var selectedVideoAssets: [PHAsset] = [] {
        didSet {
            updateVideoSelectionView()
        }
    }
    
    // NEW: Add this property to handle favorite mode
    var shouldShowFavorites: Bool = false
    var shouldShowRecentlyAdded: Bool = false
    var collectionViewType: PhotoVideoViewType = .normal
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        setupUIForVideoMerge()
        setLoca()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Reload data to reflect any favorite changes
        if collectionViewType == .favourite {
            // If we're in favorite mode, reload favorite data
            loadFavoriteAssets()
        } else {
            collectionView.reloadData()
        }
    }
    func setLoca() {
        self.selectMultipleVideoCountButton.setTitle("Select".localized(LocalizationService.shared.language), for: .normal)
    }
    func initView() {
        // Set title first
        self.titleLabel.text = albumName
        
        if collectionViewType == .favourite {
            // If showing favorites, load favorite assets
            loadFavoriteAssets()
        } else if collectionViewType == .recentlyAdded {
            // If showing recently added, load recently added assets
            loadRecentlyAddedAssets()
        } else {
            // Normal mode - load from album assets
            if let assets = albumAssets {
                for i in 0..<assets.count {
                    allAssets.append(assets[i])
                }
                allAssets = allAssets.reversed()
            }
        }
        
        setUpCollectionView()
    }
    
    // MARK: - Load Favorite Assets
    private func loadFavoriteAssets() {
        allAssets.removeAll()
        
        print("Loading favorite assets...")
        
        // If we have albumAssets, use them
        if let assets = albumAssets {
            print("Using provided albumAssets")
            // Convert to array and filter favorites
            var tempAssets: [PHAsset] = []
            for i in 0..<assets.count {
                tempAssets.append(assets[i])
            }
            tempAssets = tempAssets.reversed()
            
            // Filter only favorite assets
            allAssets = tempAssets.filter { asset in
                FavoritesManager.shared.isFavorite(asset: asset)
            }
        } else {
            // If no albumAssets provided, fetch all photos from the photo library
            print("No albumAssets provided, fetching all photos from library")
            fetchAllPhotosForFavorites()
        }
        
        print("Found \(allAssets.count) favorite assets")
        
        // Update title
        if collectionViewType == .favourite {
            switch mediaType {
            case .photos:
                titleLabel.text = "Favorite Photos (\(allAssets.count))"
            case .videos:
                titleLabel.text = "Favorite Videos (\(allAssets.count))"
            case .all:
                titleLabel.text = "Favorites (\(allAssets.count))"
            }
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Load Recently Added Assets
    private func loadRecentlyAddedAssets() {
        allAssets.removeAll()
        
        print("Loading recently added assets...")
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch based on mediaType
        switch mediaType {
        case .photos:
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            processFetchedAssetsForRecentlyAdded(assets)
        case .videos:
            let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            processFetchedAssetsForRecentlyAdded(assets)
        case .all:
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            processFetchedAssetsForRecentlyAdded(assets)
        }
        
        // Update title
        if collectionViewType == .recentlyAdded {
            switch mediaType {
            case .photos:
                titleLabel.text = "Recently Added Photos (\(allAssets.count))"
            case .videos:
                titleLabel.text = "Recently Added Videos (\(allAssets.count))"
            case .all:
                titleLabel.text = "Recently Added (\(allAssets.count))"
            }
        }
        
        collectionView.reloadData()
    }
    
    private func processFetchedAssetsForRecentlyAdded(_ assets: PHFetchResult<PHAsset>) {
        var tempAssets: [PHAsset] = []
        
        assets.enumerateObjects { (asset, _, _) in
            tempAssets.append(asset)
        }
        
        // Get recently added assets (last 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        allAssets = tempAssets.filter { asset in
            guard let creationDate = asset.creationDate else { return false }
            return creationDate > thirtyDaysAgo
        }
        
        print("Processed \(tempAssets.count) assets, found \(allAssets.count) recently added")
    }
    
    // MARK: - Fetch All Photos for Favorites (NEW METHOD)
    private func fetchAllPhotosForFavorites() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch based on mediaType
        switch mediaType {
        case .photos:
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            processFetchedAssets(assets)
        case .videos:
            let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            processFetchedAssets(assets)
        case .all:
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            processFetchedAssets(assets)
        }
    }
    
    private func processFetchedAssets(_ assets: PHFetchResult<PHAsset>) {
        var tempAssets: [PHAsset] = []
        
        assets.enumerateObjects { (asset, _, _) in
            tempAssets.append(asset)
        }
        
        // Filter only favorite assets
        allAssets = tempAssets.filter { asset in
            FavoritesManager.shared.isFavorite(asset: asset)
        }
        
        print("Processed \(tempAssets.count) assets, found \(allAssets.count) favorites")
    }
    
    // MARK: - Favorite Button Actions
    private func handleFavoriteButtonTap(for asset: PHAsset, in cell: Any) {
        let isCurrentlyFavorite = FavoritesManager.shared.isFavorite(asset: asset)
        
        if isCurrentlyFavorite {
            // Remove from favorites
            FavoritesManager.shared.removeFromFavorites(asset: asset)
            showToast(message: "Removed from favorites".localized(LocalizationService.shared.language))
            
            // If we're in favorite mode, remove the asset from the list
            if collectionViewType == .favourite {
                if let index = allAssets.firstIndex(of: asset) {
                    allAssets.remove(at: index)
                    collectionView.reloadData()
                }
            }
        } else {
            // Add to favorites
            FavoritesManager.shared.addToFavorites(asset: asset)
            showToast(message: "Added to favorites".localized(LocalizationService.shared.language))
        }
        
        // Update button image immediately
        updateFavoriteButtonImage(for: cell, asset: asset)
    }
    
    private func updateFavoriteButtonImage(for cell: Any, asset: PHAsset) {
        let isFavorite = FavoritesManager.shared.isFavorite(asset: asset)
        let imageName = isFavorite ? "favourite_selected" : "favourite_unselected"
        let favoriteImage = UIImage(named: imageName)
        
        if let photoCell = cell as? PhotosCollectionCell {
            photoCell.favouriteButton.setImage(favoriteImage, for: .normal)
        } else if let videoCell = cell as? VideosCollectionCell {
            videoCell.favouriteButton.setImage(favoriteImage, for: .normal)
        }
    }
    
    private func getFavoriteButtonImage(for asset: PHAsset) -> UIImage? {
        let isFavorite = FavoritesManager.shared.isFavorite(asset: asset)
        let imageName = isFavorite ? "favourite_selected" : "favourite_unselected"
        return UIImage(named: imageName)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 150,
                                             y: self.view.frame.size.height-100,
                                             width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    private func setupUIForVideoMerge() {
        // Show/hide multiple selection button based on video editing feature
        let isMergeMode = videoEditingFeature == .merge
        selectMultipleVideoCountButton.isHidden = !isMergeMode
        
        if isMergeMode {
            selectMultipleVideoCountButton.setTitle("Select".localized(LocalizationService.shared.language), for: .normal)
            selectMultipleVideoCountButton.isEnabled = false
            selectMultipleVideoCountButton.alpha = 0.5
        }
        
        // Enable multiple selection only for merge mode
        collectionView.allowsMultipleSelection = isMergeMode
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setUpCollectionView() {
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.bounces = true
        
        // Set custom layout for videos
        if self.mediaType == .videos {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 110)
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            collectionView.collectionViewLayout = layout
        } else {
            // Set Waterfall Flow Layout for photos
            let layout = WaterfallFlowLayout()
            layout.numberOfColumns = 2
            layout.cellPadding = 8
            collectionView.collectionViewLayout = layout
        }
        
        collectionView.reloadData()
    }
    
    private func updateVideoSelectionView() {
        // Update multiple selection button
        if videoEditingFeature == .merge {
            if selectedVideoAssets.count >= 2 {
                selectMultipleVideoCountButton.setTitle("Done (\(selectedVideoAssets.count))", for: .normal)
                selectMultipleVideoCountButton.isEnabled = true
                selectMultipleVideoCountButton.alpha = 1.0
            } else {
                selectMultipleVideoCountButton.setTitle("Select".localized(LocalizationService.shared.language), for: .normal)
                selectMultipleVideoCountButton.isEnabled = false
                selectMultipleVideoCountButton.alpha = 0.5
            }
        }
        
        // Reload collection view to update selection states
        collectionView.reloadData()
    }
    
    private func getVideoDateString(from asset: PHAsset) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy 'at' hh:mm a"
        
        guard let creationDate = asset.creationDate else {
            return "Unknown date"
        }
        
        return dateFormatter.string(from: creationDate)
    }
    
    func loadFullImageAndNavigate(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self, let image = image else { return }
            
            DispatchQueue.main.async {
                if self.photoEditingFeature == .resize {
                    
                    // Navigate to CropImageVC with the selected image
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let cropVC = storyboard.instantiateViewController(withIdentifier: "CropImageVC") as? CropImageVC {
                        cropVC.selectedImage = image
                        cropVC.originalAsset = asset
                        self.navigationController?.pushViewController(cropVC, animated: true)
                    }
                } else if self.photoEditingFeature == .enhance {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let enhanceVC = storyboard.instantiateViewController(withIdentifier: "PhotoEnhanceVC") as? PhotoEnhanceVC {
                        enhanceVC.image = image
                        self.navigationController?.pushViewController(enhanceVC, animated: true)
                    }
                } else if self.photoEditingFeature == .filter {
                    // FilterPhotoVC
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let filterVC = storyboard.instantiateViewController(withIdentifier: "FilterPhotoVC") as? FilterPhotoVC {
                        filterVC.originalImage = image
                        self.navigationController?.pushViewController(filterVC, animated: true)
                    }
                } else if self.photoEditingFeature == .addText {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let addTextVC = storyboard.instantiateViewController(withIdentifier: "AddTextPhotoVC") as? AddTextPhotoVC {
                        addTextVC.originalImage = image
                        self.navigationController?.pushViewController(addTextVC, animated: true)
                    }
                }
            }
        }
    }

    
    // MARK: - Load Full Video and Navigate
    func loadFullVideoAndNavigate(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (avAsset, audioMix, info) in
            guard let self = self, let avAsset = avAsset else { return }
            
            DispatchQueue.main.async {
                if self.videoEditingFeature == .crop {
                    // Navigate to CropVideo for cropping
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let cropVideoVC = storyboard.instantiateViewController(withIdentifier: "CropVideoVC") as? CropVideoVC {
                        cropVideoVC.isCroppedVideo = true
                        
                        // Get the video URL from the asset
                        if let urlAsset = avAsset as? AVURLAsset {
                            cropVideoVC.videoURL = urlAsset.url
                            cropVideoVC.originalAsset = asset
                        } else {
                            // If it's not a URL asset, we need to export it first
                            self.exportVideoAsset(avAsset, completion: { url in
                                if let url = url {
                                    cropVideoVC.videoURL = url
                                    cropVideoVC.originalAsset = asset
                                    self.navigationController?.pushViewController(cropVideoVC, animated: true)
                                }
                            })
                            return
                        }
                        
                        self.navigationController?.pushViewController(cropVideoVC, animated: true)
                    }
                } else if self.videoEditingFeature == .speed {
                    // Navigate to CropVideo for cropping
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let cropVideoVC = storyboard.instantiateViewController(withIdentifier: "CropVideoVC") as? CropVideoVC {
                        
                        cropVideoVC.isCroppedVideo = false
                        
                        // Get the video URL from the asset
                        if let urlAsset = avAsset as? AVURLAsset {
                            cropVideoVC.videoURL = urlAsset.url
                            cropVideoVC.originalAsset = asset
                        } else {
                            // If it's not a URL asset, we need to export it first
                            self.exportVideoAsset(avAsset, completion: { url in
                                if let url = url {
                                    cropVideoVC.videoURL = url
                                    cropVideoVC.originalAsset = asset
                                    DispatchQueue.main.async {
                                        self.navigationController?.pushViewController(cropVideoVC, animated: true)
                                    }
                                }
                            })
                            return
                        }
                        
                        self.navigationController?.pushViewController(cropVideoVC, animated: true)
                    }
                } else if self.videoEditingFeature == .reverse {
                    // Navigate to reverse video
                    // Check video duration for reverse feature is not working more then 20 mb
                    let maxSizeInBytes: Int64 = 20 * 1024 * 1024   // 20 MB

                    self.getAssetFileSize(asset) { fileSize in
                        DispatchQueue.main.async {
                            
                            if fileSize > maxSizeInBytes {
                                self.showDurationAlert()   // show alert for large size
                                return
                            }
                            
                            // PROCEED ONLY IF <= 20MB
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            guard let reverseVideoVC = storyboard.instantiateViewController(withIdentifier: "ReverseVideoVC") as? ReverseVideoVC else {
                                return
                            }

                            if let urlAsset = avAsset as? AVURLAsset {
                                reverseVideoVC.videoURL = urlAsset.url
                                reverseVideoVC.originalAsset = asset
                                self.navigationController?.pushViewController(reverseVideoVC, animated: true)
                            } else {
                                self.exportVideoAsset(avAsset) { url in
                                    guard let url = url else { return }
                                    DispatchQueue.main.async {
                                        reverseVideoVC.videoURL = url
                                        reverseVideoVC.originalAsset = asset
                                        self.navigationController?.pushViewController(reverseVideoVC, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func getAssetFileSize(_ asset: PHAsset, completion: @escaping (Int64) -> Void) {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            if let fileSize = resource.value(forKey: "fileSize") as? CLong {
                completion(Int64(fileSize))
                return
            }
        }

        // fallback (export tmp file to measure)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        PHAssetResourceManager.default().writeData(for: resources.first!, toFile: tmpURL, options: options) { error in
            if error == nil {
                let size = (try? FileManager.default.attributesOfItem(atPath: tmpURL.path)[.size] as? Int64) ?? 0
                completion(size)
            } else {
                completion(0)
            }
        }
    }
    private func showDurationAlert() {
        let alert = UIAlertController(
            title: "Video Too Long",
            message: "Please select a video that is 20MB or less for reversing.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Use your topViewController extension
        if let topVC = self.topViewController {
            topVC.present(alert, animated: true, completion: nil)
        } else {
            // Fallback to presenting from self if topViewController is not available
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func exportVideoAsset(_ asset: AVAsset, completion: @escaping (URL?) -> Void) {
        let manager = FileManager.default
        
        guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true) else {
            completion(nil)
            return
        }
        
        let outputURL = documentDirectory.appendingPathComponent("temp_video_\(Date().timeIntervalSince1970).mp4")
        
        // Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(outputURL)
            case .failed, .cancelled:
                print("Export failed: \(String(describing: exportSession.error))")
                completion(nil)
            default:
                completion(nil)
            }
        }
    }
    
    @IBAction func selectedVideoButtonAction(_ sender: UIButton) {
        guard videoEditingFeature == .merge, selectedVideoAssets.count >= 2 else {
            return
        }
        
        // Navigate to MergeVideoVC with selected assets
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mergeVC = storyboard.instantiateViewController(withIdentifier: "MergeVideoVC") as? MergeVideoVC {
            mergeVC.selectedVideoAssets = selectedVideoAssets
            self.navigationController?.pushViewController(mergeVC, animated: true)
        }
    }
    
    // MARK: - Helper Methods for Selection Logic
    private func canSelectAsset(_ asset: PHAsset) -> Bool {
        // Allow selection in all cases since we're using allAssets array for all types
        return true
    }
    
    private func shouldNavigateForAsset(_ asset: PHAsset) -> Bool {
        // Determine if we should navigate to editing screen for this asset
        if asset.mediaType == .image {
            return photoEditingFeature != nil
        } else if asset.mediaType == .video {
            return videoEditingFeature != nil && videoEditingFeature != .merge
        }
        return false
    }
    func openPhotoEditor(with asset: UIImage) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        guard let photoEditorVC = storyboard.instantiateViewController(withIdentifier: "PhotoEditorVC") as? PhotoEditorVC else { return }
        
        // Pass the selected asset to PhotoEditorVC
        photoEditorVC.selectedAsset = asset
        photoEditorVC.isOpenHome = true // Set this flag for new navigation
        
        self.navigationController?.pushViewController(photoEditorVC, animated: true)
    }
    func loadFullImageForPhotoEditor(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self, let image = image else { return }
            
            DispatchQueue.main.async {
                self.openPhotoEditor(with: image)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension PhotoVideoListVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = allAssets[indexPath.item]
        
        if asset.mediaType == .video {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideosCollectionCell", for: indexPath) as! VideosCollectionCell
            
            // Use actual video name from PHAsset
            cell.videoNameLabel.text = getVideoName(from: asset)
            cell.videoDateTimeLabel.text = getVideoDateString(from: asset)
            
            // Load thumbnail for video
            let targetSize = CGSize(width: 120, height: 80)
            cell.videoPreviewImageView.fetchImageAsset(asset, targetSize: targetSize, completionHandler: nil)
            
            // Configure selection view only for merge mode
            let isSelected = selectedVideoAssets.contains(asset)
            cell.videoSelectionView.isHidden = !isSelected || videoEditingFeature != .merge
            
            if isSelected, let index = selectedVideoAssets.firstIndex(of: asset) {
                cell.selectedVideoCountLabel.text = "\(index + 1)"
            }
            
            cell.durationLabel.text = " " + String(format: "%02d:%02d", Int(asset.duration)/60, Int(asset.duration) % 60) + " "
            
            // Configure favorite button - Display previously set favorite image
            let favoriteImage = getFavoriteButtonImage(for: asset)
            cell.favouriteButton.setImage(favoriteImage, for: .normal)
            
            cell.favouriteButton.setOnClickListener { [weak self] in
                self?.handleFavoriteButtonTap(for: asset, in: cell)
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionCell", for: indexPath) as! PhotosCollectionCell

            // Load thumbnail image
            let targetSize = CGSize(width: 300, height: 300)
            cell.imageView.fetchImageAsset(asset, targetSize: targetSize, completionHandler: nil)
            
            // Configure favorite button - Display previously set favorite image
            let favoriteImage = getFavoriteButtonImage(for: asset)
            cell.favouriteButton.setImage(favoriteImage, for: .normal)
            
            cell.favouriteButton.setOnClickListener { [weak self] in
                self?.handleFavoriteButtonTap(for: asset, in: cell)
            }
            return cell
        }
    }

    private func getVideoName(from asset: PHAsset) -> String {
        // Get from resources (most reliable method)
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            return (resource.originalFilename as NSString).deletingPathExtension
        }
        
        // Fallback to filename property
        if let fileName = asset.value(forKey: "filename") as? String {
            return (fileName as NSString).deletingPathExtension
        }
        
        // Final fallback
        return "Video"
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = allAssets[indexPath.row]
        
        // Check if we can select this asset (considering favorite mode)
        guard canSelectAsset(asset) else {
            // If we can't select (e.g., in favorite mode without editing features), just return
            collectionView.deselectItem(at: indexPath, animated: false)
            return
        }
        
        if asset.mediaType == .image {
            // Handle photo selection
            print("Selected photo at index: \(indexPath.row)")
            
            // Only navigate if we have photo editing features
            if shouldNavigateForAsset(asset) {
                self.loadFullImageAndNavigate(asset: asset)
            } else {
                // If no editing feature but we're allowed to select, just show selection feedback
                print("Photo selected but no editing feature specified")
                self.loadFullImageForPhotoEditor(asset: asset)
            }
        } else if asset.mediaType == .video {
            // Handle video selection based on editing feature
            print("Selected video at index: \(indexPath.row)")
            
            if videoEditingFeature == .merge {
                // Multiple selection for merge - toggle selection
                if let index = selectedVideoAssets.firstIndex(of: asset) {
                    // Deselect: Remove from selected videos
                    selectedVideoAssets.remove(at: index)
                    collectionView.deselectItem(at: indexPath, animated: true)
                } else {
                    // Select: Add to selected videos
                    selectedVideoAssets.append(asset)
                }
                collectionView.reloadItems(at: [indexPath])
            } else {
                // Single selection for other video features
                if let index = selectedVideoAssets.firstIndex(of: asset) {
                    selectedVideoAssets.remove(at: index)
                    collectionView.deselectItem(at: indexPath, animated: true)
                } else {
                    selectedVideoAssets.removeAll()
                    selectedVideoAssets.append(asset)
                }
                
                // Reload to update selection state
                collectionView.reloadItems(at: [indexPath])
                
                // If it's single video selection for editing, navigate directly
                if selectedVideoAssets.count == 1 && shouldNavigateForAsset(asset) {
                    self.loadFullVideoAndNavigate(asset: asset)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let asset = allAssets[indexPath.row]
        
        if asset.mediaType == .video && videoEditingFeature == .merge {
            // Remove from selected videos only in merge mode
            if let index = selectedVideoAssets.firstIndex(of: asset) {
                selectedVideoAssets.remove(at: index)
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

// MARK: - Waterfall Flow Layout
class WaterfallFlowLayout: UICollectionViewFlowLayout {
    var numberOfColumns = 2
    var cellPadding: CGFloat = 8
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override func prepare() {
        guard cache.isEmpty, let collectionView = collectionView else { return }

        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        let xOffset = (0..<numberOfColumns).map { CGFloat($0) * columnWidth }
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            // Calculate cell height based on aspect ratio or random height
            let height = calculateHeightForItem(at: indexPath, columnWidth: columnWidth)
            
            let column = yOffset.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
        }
    }
    
    private func calculateHeightForItem(at indexPath: IndexPath, columnWidth: CGFloat) -> CGFloat {
        guard let collectionView = collectionView as? UICollectionView,
              let vc = collectionView.delegate as? PhotoVideoListVC,
              indexPath.item < vc.allAssets.count else {
            return 200 // Default height
        }
        
        let asset = vc.allAssets[indexPath.item]
        let width = CGFloat(asset.pixelWidth)
        let height = CGFloat(asset.pixelHeight)
        
        if width > 0 && height > 0 {
            // Calculate height maintaining aspect ratio
            let aspectRatio = height / width
            return (columnWidth - (cellPadding * 2)) * aspectRatio
        }
        
        return 200 // Default height if dimensions not available
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}
