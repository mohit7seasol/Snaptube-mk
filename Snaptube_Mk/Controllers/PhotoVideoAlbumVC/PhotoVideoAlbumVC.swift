//
//  PhotoVideoAlbumVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//

import UIKit
import Photos

// MARK: - Supporting Types
enum AlbumType {
    case camera
    case screenshots
    case videos
    case other
}

struct Album {
    let title: String
    let count: Int
    let type: AlbumType
    let assets: PHFetchResult<PHAsset>
}

class PhotoVideoAlbumVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "AlbumCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AlbumCollectionViewCell")
        }
    }
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var titleLAbel: UILabel!
    
    // MARK: - Variables
    var mediaType: MediaType = .all
    private var albums: [Album] = []
    private var ALL_ASSETS: [[String: PHFetchResult<PHAsset>]] = []
    private var SMART_ALBUM = PHFetchResult<PHAssetCollection>()
    private var OTHER_ALBUM = PHFetchResult<PHAssetCollection>()
    var photoEditingFeature: PhotoEditingFeatures?
    var videoEditingFeature: VideoEditingFeatures?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationBar()
        requestPhotoLibraryPermission()
        setLoca()
    }
    
    func setLoca() {
        self.titleLAbel.text = "Album".localized(LocalizationService.shared.language)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        checkAndUpdateFavoriteButton()
    }

    private func setupNavigationBar() {
        switch mediaType {
        case .photos:
            self.title = "Photo Albums".localized(LocalizationService.shared.language)
        case .videos:
            self.title = "Video Albums".localized(LocalizationService.shared.language)
        case .all:
            self.title = "Albums".localized(LocalizationService.shared.language)
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let padding: CGFloat = 16
        let availableWidth = collectionView.frame.width - (padding * 3)
        let itemWidth = availableWidth / 2
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.2)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Check and Update Favorite Button
    private func checkAndUpdateFavoriteButton() {
        let hasFavorites = checkIfAnyFavoritesExist()
        favouriteButton.isHidden = !hasFavorites
        
        print("Favorite button visibility: \(!hasFavorites ? "HIDDEN" : "VISIBLE")")
        print("Total favorites found: \(countAllFavorites())")
    }
    
    private func checkIfAnyFavoritesExist() -> Bool {
        return countAllFavorites() > 0
    }
    
    private func countAllFavorites() -> Int {
        var favoriteCount = 0
        
        // Create fetch options based on current mediaType
        let fetchOptions = PHFetchOptions()
        
        switch mediaType {
        case .photos:
            // Only check photos
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let photos = PHAsset.fetchAssets(with: fetchOptions)
            favoriteCount += countFavoritesInFetchResult(photos)
            
        case .videos:
            // Only check videos
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let videos = PHAsset.fetchAssets(with: fetchOptions)
            favoriteCount += countFavoritesInFetchResult(videos)
            
        case .all:
            // Check both photos and videos
            let photosFetchOptions = PHFetchOptions()
            photosFetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let photos = PHAsset.fetchAssets(with: photosFetchOptions)
            favoriteCount += countFavoritesInFetchResult(photos)
            
            let videosFetchOptions = PHFetchOptions()
            videosFetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let videos = PHAsset.fetchAssets(with: videosFetchOptions)
            favoriteCount += countFavoritesInFetchResult(videos)
        }
        
        return favoriteCount
    }
    
    private func countFavoritesInFetchResult(_ fetchResult: PHFetchResult<PHAsset>) -> Int {
        var count = 0
        
        fetchResult.enumerateObjects { (asset, _, _) in
            if FavoritesManager.shared.isFavorite(asset: asset) {
                count += 1
            }
        }
        
        return count
    }
    
    // MARK: - Permission Handling
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized, .limited:
                DispatchQueue.main.async {
                    self?.fetchAssets()
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self?.showPermissionAlert()
                }
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permission Required".localized(LocalizationService.shared.language),
            message: "Please allow access to your photo library to display albums.".localized(LocalizationService.shared.language),
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
    
    // MARK: - Fetch Assets (Same as AlbumsVc)
    func fetchAssets() {
        let allVideosOptions = PHFetchOptions()
        allVideosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        SMART_ALBUM = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        OTHER_ALBUM = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        
        let fetchOptions = PHFetchOptions()
        if mediaType == .videos {
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        } else if mediaType == .photos {
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        }
        // For .all, no predicate - show both
        
        var fetchedAssets = PHFetchResult<PHAsset>()
        
        // Clear previous data
        ALL_ASSETS.removeAll()
        albums.removeAll()
        
        // Process smart albums
        for i in 0..<SMART_ALBUM.count {
            fetchedAssets = PHAsset.fetchAssets(in: SMART_ALBUM[i], options: fetchOptions)
            if fetchedAssets.count > 0 {
                let albumName = SMART_ALBUM[i].localizedTitle ?? "Unknown"
                let temp = [albumName: PHAsset.fetchAssets(in: SMART_ALBUM[i], options: fetchOptions)]
                ALL_ASSETS.append(temp)
                
                let album = Album(
                    title: albumName,
                    count: fetchedAssets.count,
                    type: getAlbumType(from: SMART_ALBUM[i]),
                    assets: fetchedAssets
                )
                albums.append(album)
            }
        }
        
        // Process user albums
        for i in 0..<OTHER_ALBUM.count {
            fetchedAssets = PHAsset.fetchAssets(in: OTHER_ALBUM[i], options: fetchOptions)
            if fetchedAssets.count > 0 {
                let albumName = OTHER_ALBUM[i].localizedTitle ?? "Unknown"
                let temp = [albumName: PHAsset.fetchAssets(in: OTHER_ALBUM[i], options: fetchOptions)]
                ALL_ASSETS.append(temp)
                
                let album = Album(
                    title: albumName,
                    count: fetchedAssets.count,
                    type: getAlbumType(from: OTHER_ALBUM[i]),
                    assets: fetchedAssets
                )
                albums.append(album)
            }
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            // Re-check favorites after fetching assets
            self.checkAndUpdateFavoriteButton()
        }
    }
    
    private func getAlbumType(from collection: PHAssetCollection) -> AlbumType {
        switch collection.assetCollectionSubtype {
        case .smartAlbumUserLibrary, .smartAlbumRecentlyAdded:
            return .camera
        case .smartAlbumScreenshots:
            return .screenshots
        case .smartAlbumVideos:
            return .videos
        default:
            if collection.localizedTitle?.lowercased().contains("video") == true {
                return .videos
            }
            return .other
        }
    }
    
    // MARK: - Get first 4 assets for thumbnails
    private func getFirstFourAssets(from assets: PHFetchResult<PHAsset>) -> [PHAsset?] {
        var firstFour: [PHAsset?] = []
        let count = min(assets.count, 4)
        
        for i in 0..<count {
            firstFour.append(assets.object(at: i))
        }
        
        // Fill remaining slots with nil if needed
        while firstFour.count < 4 {
            firstFour.append(nil)
        }
        
        return firstFour
    }
    
    // MARK: - Navigate to Favorite Assets
    private func moveToFavoriteAssetsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let photoVideoListVC = storyboard.instantiateViewController(withIdentifier: "PhotoVideoListVC") as? PhotoVideoListVC else {
            print("Error: Could not instantiate PhotoVideoListVC")
            return
        }
        
        // Set flag to indicate we want to show favorites
        photoVideoListVC.shouldShowFavorites = true
        photoVideoListVC.collectionViewType = .favourite
        photoVideoListVC.mediaType = self.mediaType
        
        // Set appropriate title based on media type
        switch mediaType {
        case .photos:
            photoVideoListVC.albumName = "Favorite Photos".localized(LocalizationService.shared.language)
            photoVideoListVC.photoEditingFeature = self.photoEditingFeature
        case .videos:
            photoVideoListVC.albumName = "Favorite Videos".localized(LocalizationService.shared.language)
            photoVideoListVC.videoEditingFeature = self.videoEditingFeature
        case .all:
            photoVideoListVC.albumName = "Favorites".localized(LocalizationService.shared.language)
        }
        
        self.navigationController?.pushViewController(photoVideoListVC, animated: true)
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func favouriteButtonAction(_ sender: UIButton) {
        self.moveToFavoriteAssetsVC()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension PhotoVideoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "AlbumCollectionViewCell",
            for: indexPath
        ) as? AlbumCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let album = albums[indexPath.item]
        let assets = album.assets
        
        // Get first 4 assets for thumbnails
        let firstFourAssets = getFirstFourAssets(from: assets)
        
        // Configure cell with album info
        cell.configure(with: album)
        
        // Load thumbnails for each image view
        let targetSize = CGSize(width: 150, height: 150)
        
        // Load thumbnail for imgView1
        if let asset1 = firstFourAssets[0] {
            cell.imgView1.fetchImageAsset(asset1, targetSize: targetSize) { success in
                if !success {
                    cell.imgView1.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                }
            }
        } else {
            cell.imgView1.image = nil
            cell.imgView1.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        }
        
        // Load thumbnail for imgView2
        if let asset2 = firstFourAssets[1] {
            cell.imgView2.fetchImageAsset(asset2, targetSize: targetSize) { success in
                if !success {
                    cell.imgView2.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
                }
            }
        } else {
            cell.imgView2.image = nil
            cell.imgView2.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        }
        
        // Load thumbnail for imgView3
        if let asset3 = firstFourAssets[2] {
            cell.imgView3.fetchImageAsset(asset3, targetSize: targetSize) { success in
                if !success {
                    cell.imgView3.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
                }
            }
        } else {
            cell.imgView3.image = nil
            cell.imgView3.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        }
        
        // Load thumbnail for imgView4
        if let asset4 = firstFourAssets[3] {
            cell.imgView4.fetchImageAsset(asset4, targetSize: targetSize) { success in
                if !success {
                    cell.imgView4.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
                }
            }
        } else {
            cell.imgView4.image = nil
            cell.imgView4.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = albums[indexPath.item]
        print("Selected album: \(album.title) with \(album.count) items")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "PhotoVideoListVC") as? PhotoVideoListVC {
            vc.albumName = album.title
            vc.albumAssets = album.assets
            vc.mediaType = mediaType
            vc.photoEditingFeature = photoEditingFeature
            vc.videoEditingFeature = videoEditingFeature
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let availableWidth = collectionView.frame.width - (padding * 3)
        let itemWidth = availableWidth / 2
        return CGSize(width: itemWidth, height: itemWidth * 1.2)
    }
}
