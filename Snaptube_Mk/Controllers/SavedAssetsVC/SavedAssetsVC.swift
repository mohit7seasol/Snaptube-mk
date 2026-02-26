//
//  SavedAssetsVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 25/11/25.
//

import UIKit
import Photos

enum ViewType: String, CaseIterable {
    case video
    case photo
}

class SavedAssetsVC: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Variables
    var viewType: ViewType = .photo {
        didSet {
            // Save to UserDefaults whenever viewType changes
            saveViewTypeToLocal()
        }
    }
    var appAlbumAssets: [PHAsset] = []
    let albumName = AppConstant.albumName
    private let viewTypeKey = "SavedAssetsVC_ViewType"
    private var isReturningFromPlayer = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViewTypeFromLocal()
        updateTitle()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        // If returning from PlayerVC → DO NOTHING (no reload, no layout change)
        if isReturningFromPlayer {
            isReturningFromPlayer = false
            return
        }

        // First-time load → run normally
        loadViewTypeFromLocal()
        fetchAppAlbumAssets()
        updateTitle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Force layout update when view dimensions are known
        collectionView.collectionViewLayout.invalidateLayout()
    }
    // MARK: - ViewType Local Storage Management
    private func saveViewTypeToLocal() {
        UserDefaults.standard.set(viewType.rawValue, forKey: viewTypeKey)
        UserDefaults.standard.synchronize()
        print("Saved viewType: \(viewType.rawValue)")
    }
    
    private func loadViewTypeFromLocal() {
        if let savedViewTypeString = UserDefaults.standard.string(forKey: viewTypeKey),
           let savedViewType = ViewType(rawValue: savedViewTypeString) {
            viewType = savedViewType
            print("Loaded viewType: \(viewType.rawValue)")
        } else {
            // If no saved value, use default (.photo) and save it
            viewType = .photo
            saveViewTypeToLocal()
            print("No saved viewType found, using default: \(viewType.rawValue)")
        }
    }
    
    // MARK: - Public method to set viewType from outside
    func setViewType(_ type: ViewType) {
        self.viewType = type
        // This will trigger didSet and save to local automatically
    }
    
    private func updateTitle() {
        switch viewType {
        case .video:
            titleLabel.text = "Saved Videos".localized(LocalizationService.shared.language)
        case .photo:
            titleLabel.text = "Saved Photos".localized(LocalizationService.shared.language)
        }
    }
    
    private func setupCollectionView() {
        collectionView.register(UINib(nibName: "CreationCollectionCell", bundle: nil), forCellWithReuseIdentifier: "CreationCollectionCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .always
    }
    
    // MARK: - Fetch App Album Assets with filtering
    private func fetchAppAlbumAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let appAlbum = collections.firstObject else {
            // Album doesn't exist yet, clear data
            appAlbumAssets.removeAll()
            updateUIForEmptyState()
            return
        }
        
        // Fetch all assets from the app album
        let assetsFetchOptions = PHFetchOptions()
        assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: appAlbum, options: assetsFetchOptions)
        
        // Convert to array and filter based on viewType
        appAlbumAssets.removeAll()
        assets.enumerateObjects { (asset, _, _) in
            switch self.viewType {
            case .video:
                if asset.mediaType == .video {
                    self.appAlbumAssets.append(asset)
                }
            case .photo:
                if asset.mediaType == .image {
                    self.appAlbumAssets.append(asset)
                }
            }
        }
        
        updateUIForEmptyState()
        collectionView.reloadData()
    }
    
    private func updateUIForEmptyState() {
        let isEmpty = appAlbumAssets.isEmpty
        collectionView.isHidden = isEmpty
        
        if isEmpty {
            // You can customize the empty state message here
            print("No assets found for viewType: \(viewType.rawValue)")
        }
    }
    
    // Helper method to format video duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Debug method to check current state
    private func printCurrentState() {
        print("Current ViewType: \(viewType.rawValue)")
        print("Assets count: \(appAlbumAssets.count)")
        print("Saved ViewType in UserDefaults: \(UserDefaults.standard.string(forKey: viewTypeKey) ?? "Not found")")
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension SavedAssetsVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appAlbumAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreationCollectionCell", for: indexPath) as! CreationCollectionCell
        
        let asset = appAlbumAssets[indexPath.item]
        
        // Configure cell based on asset type
        if asset.mediaType == .video {
            // Show duration label for videos
            cell.durationLabel.isHidden = false
            cell.durationLabel.text = formatDuration(asset.duration)
        } else {
            // Hide duration label for photos
            cell.durationLabel.isHidden = true
        }
        
        // Load image for the asset
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 300, height: 300)
        
        imageManager.requestImage(for: asset,
                                targetSize: targetSize,
                                contentMode: .aspectFill,
                                options: nil) { (image, _) in
            DispatchQueue.main.async {
                cell.previewImageView.image = image
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let numberOfColumns: CGFloat = 2
        let sectionInset: CGFloat = 16
        
        let totalHorizontalSpacing = spacing * (numberOfColumns - 1) + (sectionInset * 2)
        let availableWidth = collectionView.bounds.width - totalHorizontalSpacing
        let itemWidth = max(availableWidth / numberOfColumns, 0)
        let itemHeight: CGFloat = 230
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isReturningFromPlayer = true
        let asset = appAlbumAssets[indexPath.item]
        
        // Navigate to PlayerVC with selected asset and all assets
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as? PlayerVC {
            playerVC.mediaAssets = appAlbumAssets
            playerVC.currentAssetIndex = indexPath.item
            self.navigationController?.pushViewController(playerVC, animated: true)
        }
    }
}
