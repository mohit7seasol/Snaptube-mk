//
//  HomeVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//

import UIKit
import Photos

enum MediaType {
    case photos
    case videos
    case all // For both photos and videos
}

class HomeVC: UIViewController {
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var collectionViewOptions: UICollectionView!
    @IBOutlet weak var collectionRecentPhotos: UICollectionView!
    @IBOutlet weak var homeView: UIView!
    @IBOutlet weak var creationView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var creationButton: UIButton!
    @IBOutlet weak var creationCollectionView: UICollectionView!
    @IBOutlet weak var noCreationDataView: UIView!
    @IBOutlet weak var creationTitleView: UIView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var creationLabel: UILabel!
    @IBOutlet weak var pasteLinkButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var photosLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionRecentlyAddedPhotoHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var oppsNoPermissionLabel: UILabel!
    @IBOutlet weak var nodataLabel1: UILabel!
    @IBOutlet weak var oppsNoCreationLabel: UILabel!
    @IBOutlet weak var nodata2Label: UILabel!
    @IBOutlet weak var noPhotoPermisisonView: UIView!
    @IBOutlet weak var topViewHeightConstant: NSLayoutConstraint!
    
    var optionsImageicons = ["photos", "videos", "music", "youtube"]
    var optionTitle = ["Photos", "Videos", "Music", "Youtube"]
    var recentPhotos: [UIImage] = []
    var selectedIndexPath: IndexPath?
    var collectionViewRecentCount: Int = 6
    
    // MARK: - New properties for creation collection view
    var appAlbumAssets: [PHAsset] = []
    let albumName = AppConstant.albumName
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupButtonSelection()
        setupCreationCollectionView() // Setup creation collection view
        setUpLoca()
        
        // Initially hide both views until permission is checked
        noPhotoPermisisonView.isHidden = true
        collectionRecentPhotos.isHidden = true
        
        // Check permission after UI setup
        checkPhotoLibraryPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Check permission again when view appears
        checkPhotoLibraryPermission()
        
        // Fetch app album data when view appears
        fetchAppAlbumAssets()
    }
    
    func setUpLoca() {
        self.welcomeLabel.text = "Welcome 😊".localized(LocalizationService.shared.language)
        self.historyButton.setTitle("History".localized(LocalizationService.shared.language), for: .normal)
        self.nameTextfield.placeholder = "Name here".localized(LocalizationService.shared.language)
        self.linkTextField.placeholder = "Paste valid link here...".localized(LocalizationService.shared.language)
        self.pasteLinkButton.setTitle("Past Link".localized(LocalizationService.shared.language), for: .normal)
        self.downloadButton.setTitle("Save".localized(LocalizationService.shared.language), for: .normal)
        self.photosLabel.text = "Photos".localized(LocalizationService.shared.language)
        self.seeAllButton.setTitle("See all".localized(LocalizationService.shared.language), for: .normal)
        
        self.oppsNoPermissionLabel.text = "Oops!".localized(LocalizationService.shared.language)
        self.nodataLabel1.text = "No Data Found".localized(LocalizationService.shared.language)
        self.oppsNoCreationLabel.text = "Oops!".localized(LocalizationService.shared.language)
        self.nodata2Label.text = "No Data Found".localized(LocalizationService.shared.language)
    }
    
    // MARK: - Setup Creation Collection View
    private func setupCreationCollectionView() {
        creationCollectionView.register(UINib(nibName: "CreationCollectionCell", bundle: nil), forCellWithReuseIdentifier: "CreationCollectionCell")
        creationCollectionView.delegate = self
        creationCollectionView.dataSource = self
        
        // Setup layout for creation collection view
        if let layout = creationCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 12
            let numberOfColumns: CGFloat = 2
            
            // Calculate item size for 2x2 grid
            let totalHorizontalSpacing = spacing * (numberOfColumns - 1)
            let availableWidth = creationCollectionView.frame.width - totalHorizontalSpacing
            let itemWidth = availableWidth / numberOfColumns
            let itemHeight: CGFloat = 230 // Fixed height as requested
            
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.scrollDirection = .vertical
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    // MARK: - Fetch App Album Assets
    private func fetchAppAlbumAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let appAlbum = collections.firstObject else {
            // Album doesn't exist yet, clear data and show no data view
            appAlbumAssets.removeAll()
            updateCreationViewVisibility()
            return
        }
        
        // Fetch all assets from the app album
        let assetsFetchOptions = PHFetchOptions()
        assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: appAlbum, options: assetsFetchOptions)
        
        // Convert to array
        appAlbumAssets.removeAll()
        assets.enumerateObjects { (asset, _, _) in
            self.appAlbumAssets.append(asset)
        }
        
        updateCreationViewVisibility()
    }
    
    // MARK: - Update Creation View Visibility
    private func updateCreationViewVisibility() {
        DispatchQueue.main.async {
            if self.appAlbumAssets.isEmpty {
                // No data found, show no data view and hide collection view
                self.noCreationDataView.isHidden = false
                self.creationCollectionView.isHidden = true
            } else {
                // Data found, show collection view and hide no data view
                self.noCreationDataView.isHidden = true
                self.creationCollectionView.isHidden = false
                self.creationCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Photo Library Permission Handling - FIXED VERSION
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        print("Photo Library Permission Status: \(status.rawValue)")
        
        DispatchQueue.main.async {
            switch status {
            case .authorized, .limited:
                // Permission granted, show collection view and hide permission view
                print("Permission granted - showing collection view")
                self.noPhotoPermisisonView.isHidden = true
                self.collectionRecentPhotos.isHidden = false
                self.fetchRecentPhotos()
                
            case .denied, .restricted:
                // Permission denied, show permission view and hide collection view
                print("Permission denied - showing permission view")
                self.noPhotoPermisisonView.isHidden = false
                self.collectionRecentPhotos.isHidden = true
                self.showPlaceholderPhotos()
                
            case .notDetermined:
                // First time - automatically request permission
                print("Permission not determined - automatically requesting permission")
                self.noPhotoPermisisonView.isHidden = false
                self.collectionRecentPhotos.isHidden = true
                self.requestPhotoLibraryPermission() // Automatically request permission
                
            @unknown default:
                print("Unknown permission status - showing permission view")
                self.noPhotoPermisisonView.isHidden = false
                self.collectionRecentPhotos.isHidden = true
                self.showPlaceholderPhotos()
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        print("Requesting photo library permission...")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            print("Photo library permission response: \(status.rawValue)")
            
            // Add a small delay to ensure UI updates properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                switch status {
                case .authorized, .limited:
                    // Permission granted, show collection view and hide permission view
                    print("Permission granted after request - showing collection view")
                    self?.noPhotoPermisisonView.isHidden = true
                    self?.collectionRecentPhotos.isHidden = false
                    
                    // Ensure collection view is properly set up before fetching photos
                    self?.setupCollectionViewLayouts()
                    self?.fetchRecentPhotos()
                    
                case .denied, .restricted:
                    // Permission denied, show permission view and hide collection view
                    print("Permission denied after request - showing permission view")
                    self?.noPhotoPermisisonView.isHidden = false
                    self?.collectionRecentPhotos.isHidden = true
                    self?.showPlaceholderPhotos()
                    
                case .notDetermined:
                    // Should not happen after request
                    print("Permission still not determined after request")
                    self?.noPhotoPermisisonView.isHidden = false
                    self?.collectionRecentPhotos.isHidden = true
                    self?.showPlaceholderPhotos()
                    
                @unknown default:
                    print("Unknown permission status after request")
                    self?.noPhotoPermisisonView.isHidden = false
                    self?.collectionRecentPhotos.isHidden = true
                    self?.showPlaceholderPhotos()
                }
            }
        }
    }
    
    // MARK: - Button Selection Setup
    private func setupButtonSelection() {
        // Set home button as selected by default
        setHomeButtonSelected(true)
        setCreationButtonSelected(false)
        
        // Show home view and hide creation view by default
        homeView.isHidden = false
        creationView.isHidden = true
        
        // Add targets for button actions
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
        creationButton.addTarget(self, action: #selector(creationButtonTapped), for: .touchUpInside)
    }
    
    func setHomeButtonSelected(_ selected: Bool) {
        if selected {
            homeButton.backgroundColor = .white
            homeButton.setImage(UIImage(named: "home_selected"), for: .normal)
            homeButton.tintColor = .black // Ensure icon color contrasts with white background
        } else {
            homeButton.backgroundColor = .clear
            homeButton.setImage(UIImage(named: "home_unselected"), for: .normal)
            homeButton.tintColor = .white // Ensure icon color contrasts with dark background
        }
    }
    
    func setCreationButtonSelected(_ selected: Bool) {
        if selected {
            creationButton.backgroundColor = .white
            creationButton.setImage(UIImage(named: "creation_selected"), for: .normal)
            creationButton.tintColor = .black // Ensure icon color contrasts with white background
        } else {
            creationButton.backgroundColor = .clear
            creationButton.setImage(UIImage(named: "creation_unselected"), for: .normal)
            creationButton.tintColor = .white // Ensure icon color contrasts with dark background
        }
    }
    
    private func showPlaceholderPhotos() {
        print("Showing placeholder photos")
        recentPhotos.removeAll()
        
        // Add placeholder images
        for _ in 0..<self.collectionViewRecentCount {
            if let placeholderImage = UIImage(systemName: "photo") {
                recentPhotos.append(placeholderImage)
            }
        }
        
        DispatchQueue.main.async {
            self.collectionRecentPhotos.reloadData()
            print("Placeholder photos set up")
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
    
    private func requestPhotoLibraryPermissionForEditor(completion: @escaping (_ granted: Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // Permission granted, update UI and fetch photos
                    self.noPhotoPermisisonView.isHidden = true
                    self.collectionRecentPhotos.isHidden = false
                    self.fetchRecentPhotos() // This will handle the UI updates
                    completion(true)
                case .denied, .restricted:
                    // Permission denied, update UI
                    self.noPhotoPermisisonView.isHidden = false
                    self.collectionRecentPhotos.isHidden = true
                    completion(false)
                case .notDetermined:
                    // Should not happen after request
                    self.noPhotoPermisisonView.isHidden = false
                    self.collectionRecentPhotos.isHidden = true
                    completion(false)
                @unknown default:
                    self.noPhotoPermisisonView.isHidden = false
                    self.collectionRecentPhotos.isHidden = true
                    completion(false)
                }
            }
        }
    }
    
    func setUI() {
        setUPOprtionsCollectionView()
        setupCollectionViewLayouts() // Ensure this is called before permission check
        
        // Default selection = first item
        selectedIndexPath = IndexPath(item: 0, section: 0)
        
        // Reload to show selected gradient border
        DispatchQueue.main.async {
            self.collectionViewOptions.reloadData()
        }
        
        if isDelete == 0 {
            self.topViewHeightConstant.constant = 220
        } else {
            self.topViewHeightConstant.constant = 0
        }
        
        // 🔥 Set both textfields to use white text + white cursor
        nameTextfield.textColor = .white
        linkTextField.textColor = .white
        
        nameTextfield.tintColor = .white       // cursor color
        linkTextField.tintColor = .white       // cursor color
        
        nameTextfield.attributedPlaceholder = NSAttributedString(
            string: nameTextfield.placeholder ?? "",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        
        linkTextField.attributedPlaceholder = NSAttributedString(
            string: linkTextField.placeholder ?? "",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        
        applyLeftPadding(nameTextfield)
        applyLeftPadding(linkTextField)

        
        topView.layer.cornerRadius = 20
        topView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        topView.clipsToBounds = true
        
        // Initially hide no data view until we check for data
        noCreationDataView.isHidden = true
        creationCollectionView.isHidden = true
        
        creationTitleView.layer.cornerRadius = 10
        creationTitleView.layer.masksToBounds = true
        creationTitleView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    func applyLeftPadding(_ textField: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
    }

    func setUPOprtionsCollectionView() {
        collectionViewOptions.register(["OptionsCellCollectionViewCell"])
        collectionViewOptions.delegate = self
        collectionViewOptions.dataSource = self
        collectionViewOptions.isScrollEnabled = true // Keep existing scrolling
    }
    
    func setUPREcentAddedPhotoCollection() {
        collectionRecentPhotos.register(["PhotosCollectionCell"])
        collectionRecentPhotos.delegate = self
        collectionRecentPhotos.dataSource = self
        collectionRecentPhotos.isScrollEnabled = false // Disable scrolling for 2x2 grid
    }
    
    func setupCollectionViewLayouts() {
        // OPTIONS HORIZONTAL MENU - 3.5 cells visible (screenwidth - 20) / 3.5
        if let layout = collectionViewOptions.collectionViewLayout as? UICollectionViewFlowLayout {
            let screenWidth = UIScreen.main.bounds.width
            let spacing: CGFloat = 12
            
            // Calculate cell width: (screenwidth - 20) / 3.5
            let cellWidth = (screenWidth - 20) / 3.5
            let height: CGFloat = 70
            
            layout.itemSize = CGSize(width: cellWidth, height: height)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.scrollDirection = .horizontal
            layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
        
        // RECENT 2x2 GRID PHOTOS - Exactly 4 photos
        if let layout = collectionRecentPhotos.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 12
            let numberOfColumns: CGFloat = 2
            
            // Calculate item size for 2x2 grid
            let totalHorizontalSpacing = spacing * (numberOfColumns - 1)
            let availableWidth = collectionRecentPhotos.frame.width - totalHorizontalSpacing
            let itemWidth = availableWidth / numberOfColumns
            let itemHeight = itemWidth // Square items for consistent 2x2 grid
            
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.scrollDirection = .vertical
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            let totalRow = self.collectionViewRecentCount / 2
            self.collectionRecentlyAddedPhotoHeightConstant.constant =
                itemHeight * CGFloat(totalRow) + 180
        }
        
        // Ensure collection view is properly set up
        setUPREcentAddedPhotoCollection()
    }
    
    // MARK: - Enhanced fetchRecentPhotos with completion handler
    func fetchRecentPhotos(completion: (() -> Void)? = nil) {
        print("Fetching recent photos...")
        recentPhotos.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = collectionViewRecentCount
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        print("Found \(assets.count) assets")
        
        if assets.count == 0 {
            // If no photos found, use placeholder images
            print("No assets found - showing placeholders")
            showPlaceholderPhotos()
            completion?()
            return
        }
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        // Clear previous photos
        recentPhotos = []
        
        // Create a dispatch group to track when all images are loaded
        let dispatchGroup = DispatchGroup()
        
        // Fetch images
        let maxPhotos = min(assets.count, collectionViewRecentCount)
        
        for i in 0..<maxPhotos {
            dispatchGroup.enter()
            let asset = assets[i]
            let targetSize = CGSize(width: 600, height: 600)
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
                if let image = image {
                    self.recentPhotos.append(image)
                    print("Successfully loaded image \(i+1)")
                } else {
                    // Add placeholder if image couldn't be loaded
                    if let placeholderImage = UIImage(systemName: "photo") {
                        self.recentPhotos.append(placeholderImage)
                    }
                    print("Failed to load image \(i+1)")
                }
                dispatchGroup.leave()
            }
        }
        
        // When all images are loaded, reload collection view
        dispatchGroup.notify(queue: .main) {
            print("All images loaded. Total: \(self.recentPhotos.count)")
            
            // Ensure we have exactly the required number of items
            while self.recentPhotos.count < self.collectionViewRecentCount {
                if let placeholderImage = UIImage(systemName: "photo") {
                    self.recentPhotos.append(placeholderImage)
                }
            }
            
            // Make sure collection view is visible and reload data
            self.collectionRecentPhotos.isHidden = false
            self.noPhotoPermisisonView.isHidden = true
            self.collectionRecentPhotos.reloadData()
            
            print("Collection view reloaded with \(self.recentPhotos.count) items")
            completion?()
        }
    }
    
    // MARK: - Refresh method that can be called externally
    func refreshPhotoData() {
        checkPhotoLibraryPermission()
    }
    
    func moveToPhotoEditor() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "PhotoEditorVC") as? PhotoEditorVC else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func moveToVideoEditor() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "VideoEditorVC") as? VideoEditorVC else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Navigation to LanguageVC
    func navigateToLanguageVC() {
        let languageVC = LanguageVC()
        // Pass any necessary data to LanguageVC based on selected index
        if let selectedIndex = selectedIndexPath?.item {
            print("Navigating to LanguageVC with selected option: \(optionTitle[selectedIndex])")
        }
        navigationController?.pushViewController(languageVC, animated: true)
    }
    
    func showHomeView() {
        homeView.isHidden = false
        creationView.isHidden = true
    }
    
    func showCreationView() {
        homeView.isHidden = true
        creationView.isHidden = false
        // Refresh app album data when showing creation view
        fetchAppAlbumAssets()
    }
    
    // MARK: - Open Photo Editor from Recent Photos
    func openPhotoEditor(with asset: UIImage) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        guard let photoEditorVC = storyboard.instantiateViewController(withIdentifier: "PhotoEditorVC") as? PhotoEditorVC else { return }
        
        // Pass the selected asset to PhotoEditorVC
        photoEditorVC.selectedAsset = asset
        photoEditorVC.isOpenHome = true // Set this flag for new navigation
        
        self.navigationController?.pushViewController(photoEditorVC, animated: true)
    }
    
    // MARK: - Navigate to Favorite Assets
    func moveToRecentlyAddedAssetsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let photoVideoListVC = storyboard.instantiateViewController(withIdentifier: "PhotoVideoListVC") as? PhotoVideoListVC else {
            print("Error: Could not instantiate PhotoVideoListVC")
            return
        }
        
        // Set flag to indicate we want to show favorites
        photoVideoListVC.shouldShowRecentlyAdded = true
        photoVideoListVC.collectionViewType = .recentlyAdded
        photoVideoListVC.mediaType = .photos
        photoVideoListVC.albumName = "Recently Added Photos"
        
        self.navigationController?.pushViewController(photoVideoListVC, animated: true)
    }
}

extension HomeVC {
    @objc private func homeButtonTapped() {
        self.historyButton.isHidden = false
        self.creationLabel.isHidden = true
        self.welcomeLabel.isHidden = false
        setHomeButtonSelected(true)
        setCreationButtonSelected(false)
        showHomeView()
    }
    
    @objc private func creationButtonTapped() {
        self.historyButton.isHidden = true
        self.creationLabel.isHidden = false
        self.welcomeLabel.isHidden = true
        setHomeButtonSelected(false)
        setCreationButtonSelected(true)
        showCreationView()
    }
    
    
    @IBAction func historyButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "HistoryVC") as? HistoryVC else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func pasteLinkButtonAction(_ sender: UIButton) {
        if let pasteboardString = UIPasteboard.general.string {
            linkTextField.text = pasteboardString
        }
    }
    
    @IBAction func downloadButtonAction(_ sender: UIButton) {
        // Validate inputs
        guard validateInputs() else { return }
        
        // Get the validated inputs
        let name = nameTextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = linkTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save to UserDefaults
        saveHistoryItem(name: name, link: link)
        
        // Show success message
        showSuccessAlert()
        
        // Clear text fields after successful save
        nameTextfield.text = ""
        linkTextField.text = ""
    }
    
    @IBAction func seeAllButtonAction(_ sender: UIButton) {
        self.moveToRecentlyAddedAssetsVC()
    }
    
    @IBAction func settingButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionViewOptions {
            return optionsImageicons.count
        } else if collectionView == collectionRecentPhotos {
            return collectionViewRecentCount // Always return exactly 4 for 2x2 grid
        } else if collectionView == creationCollectionView {
            return appAlbumAssets.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collectionViewOptions {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionsCellCollectionViewCell", for: indexPath) as? OptionsCellCollectionViewCell ?? OptionsCellCollectionViewCell()
            
            // Configure options cell
            cell.iconImageView.image = UIImage(named: optionsImageicons[indexPath.item])
            cell.titleLabel.text = optionTitle[indexPath.item].localized(LocalizationService.shared.language)
            cell.parentView.layer.cornerRadius = 12
            cell.parentView.clipsToBounds = true
            cell.parentView.backgroundColor = UIColor(hex: "#111111")
            
            // Set selection state with gradient border
            if selectedIndexPath == indexPath {
                cell.setSelectedState() // Apply gradient border
            } else {
                cell.setDeselectedState() // Remove gradient border
            }
            
            return cell
        } else if collectionView == collectionRecentPhotos {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionCell", for: indexPath) as? PhotosCollectionCell ?? PhotosCollectionCell()
            
            // Configure recent photos cell - always 4 cells
            if indexPath.item < recentPhotos.count {
                cell.imageView.image = recentPhotos[indexPath.item]
            } else {
                // Fallback placeholder
                cell.imageView.image = UIImage(systemName: "photo")
            }
            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.clipsToBounds = true
            cell.imageView.layer.cornerRadius = 8
            
            cell.favouriteButton.isHidden = true
        
            return cell
        } else if collectionView == creationCollectionView {
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
        
        return UICollectionViewCell()
    }
    
    // Helper method to format video duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectionViewOptions {
            let screenWidth = UIScreen.main.bounds.width
            let visibleCells: CGFloat = 3.5
            let cellWidth = (screenWidth - 20) / visibleCells
            return CGSize(width: cellWidth, height: 84) // Keep existing height
        } else if collectionView == collectionRecentPhotos {
            // For 2x2 grid - square items
            let spacing: CGFloat = 12
            let numberOfColumns: CGFloat = 2
            
            let totalHorizontalSpacing = spacing * (numberOfColumns - 1)
            let availableWidth = collectionRecentPhotos.frame.width - totalHorizontalSpacing
            let itemWidth = availableWidth / numberOfColumns
            
            return CGSize(width: itemWidth, height: itemWidth) // Square items
        } else if collectionView == creationCollectionView {
            // For creation collection view - 2 columns with fixed height
            let spacing: CGFloat = 12
            let numberOfColumns: CGFloat = 2
            
            let totalHorizontalSpacing = spacing * (numberOfColumns - 1)
            let availableWidth = creationCollectionView.frame.width - totalHorizontalSpacing
            let itemWidth = availableWidth / numberOfColumns
            let itemHeight: CGFloat = 230 // Fixed height as requested
            
            return CGSize(width: itemWidth, height: itemHeight)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == collectionViewOptions {
            return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        } else {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionViewOptions {
            // Update selected index and show gradient border
            selectedIndexPath = indexPath
            collectionViewOptions.reloadData()
            
            // Handle navigation based on selected option
            switch indexPath.row {
            case 0: // Photos
                moveToPhotoEditor()
            case 1: // Videos
                moveToVideoEditor()
            case 2: // Music
                openYouTubeMusic()
            case 3: // Youtube
                openYouTube()
            default:
                break
            }
            
            print("Selected option: \(optionTitle[indexPath.item])")
            
        } else if collectionView == creationCollectionView {
            let asset = appAlbumAssets[indexPath.item]
            
            // Navigate to PlayerVC with selected asset and all assets
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
            if let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerVC") as? PlayerVC {
                playerVC.mediaAssets = appAlbumAssets // Pass all assets
                playerVC.currentAssetIndex = indexPath.item // Pass selected index
                self.navigationController?.pushViewController(playerVC, animated: true)
            }
            
        } else {
            print("Selected recent photo at index: \(indexPath.item)")
            // CHECK PHOTO LIBRARY PERMISSION BEFORE OPENING PHOTO EDITOR
            let status = PHPhotoLibrary.authorizationStatus()
            
            switch status {
            case .authorized, .limited:
                // Permission granted, open photo editor
                let selectedPhoto = recentPhotos[indexPath.item]
                self.openPhotoEditor(with: selectedPhoto)
                
            case .denied, .restricted:
                // Permission denied, show alert
                self.showPermissionAlert()
                
            case .notDetermined:
                // Request permission first
                self.requestPhotoLibraryPermissionForEditor { [weak self] (granted: Bool) in
                    guard let self = self else { return }
                    if granted {
                        // Permission granted after request, open photo editor
                        let selectedPhoto = self.recentPhotos[indexPath.item]
                        self.openPhotoEditor(with: selectedPhoto)
                    } else {
                        // Permission denied, show alert
                        self.showPermissionAlert()
                    }
                }
                
            @unknown default:
                self.showPermissionAlert()
            }
        }
    }
    
    private func openYouTubeMusic() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserVC") as? BrowserVC {
            browserVC.urlString = "https://music.youtube.com"
            self.navigationController?.pushViewController(browserVC, animated: true)
        }
    }

    private func openYouTube() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserVC") as? BrowserVC {
            browserVC.urlString = "https://www.youtube.com"
            self.navigationController?.pushViewController(browserVC, animated: true)
        }
    }
}

// Add this extension to HomeVC for UserDefaults management
extension HomeVC {
    // MARK: - UserDefaults Management
    struct HistoryItem: Codable {
        let name: String
        let link: String
        let date: Date
    }
    
    private func saveHistoryItem(name: String, link: String) {
        var historyItems = getHistoryItems()
        
        let newItem = HistoryItem(name: name, link: link, date: Date())
        historyItems.append(newItem)
        
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: "downloadHistory")
            UserDefaults.standard.synchronize()
        }
    }
    
    func getHistoryItems() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: "downloadHistory"),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Validation
    private func validateInputs() -> Bool {
        guard let name = nameTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(message: "Please enter a name")
            return false
        }
        
        guard let link = linkTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), // FIXED: .whitespacesAndNewlines
              !link.isEmpty,
              isValidURL(link) else {
            showAlert(message: "Please enter a valid URL")
            return false
        }
        
        return true
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // Basic URL validation
        if let url = URL(string: string) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Success", message: "Saved successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
