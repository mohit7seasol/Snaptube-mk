//
//  PhotoEditorVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 18/11/25.
//

import UIKit
import Photos

enum PhotoEditingFeatures {
    case resize
    case addText
    case enhance
    case filter
}

class PhotoEditorVC: UIViewController {

    @IBOutlet weak var resizeLabel: UILabel!
    @IBOutlet weak var addTextLabel: UILabel!
    @IBOutlet weak var enhanceLabel: UILabel!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var photoslbl1: UILabel!
    @IBOutlet weak var photoslbl2: UILabel!
    @IBOutlet weak var photoslbl3: UILabel!
    @IBOutlet weak var photoslbl4: UILabel!
    @IBOutlet weak var editTitleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var photoEditingFeature: PhotoEditingFeatures?
    
    // HomeVC
    var isOpenHome: Bool = false
    var selectedAsset: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUPUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    func setUPUI() {
        resizeLabel.font = FontManager.shared.font(for: .salsa, size: 24.0)
        photoslbl1.font = FontManager.shared.font(for: .salsa, size: 24.0)
        addTextLabel.font = FontManager.shared.font(for: .sansitaSwashed, size: 24.0)
        photoslbl2.font = FontManager.shared.font(for: .sansitaSwashed, size: 24.0)
        enhanceLabel.font = FontManager.shared.font(for: .sen, size: 24.0)
        photoslbl3.font = FontManager.shared.font(for: .sen, size: 24.0)
        filterLabel.font = FontManager.shared.font(for: .tauri, size: 24.0)
        photoslbl4.font = FontManager.shared.font(for: .tauri, size: 24.0)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        setLoca()
    }
    func setLoca() {
        self.editTitleLabel.text = "Edit".localized(LocalizationService.shared.language)
        self.saveButton.setTitle("Save".localized(LocalizationService.shared.language), for: .normal)
        self.resizeLabel.text = "Resize".localized(LocalizationService.shared.language)
        self.photoslbl1.text = "Photos".localized(LocalizationService.shared.language)
        self.addTextLabel.text = "Add Text".localized(LocalizationService.shared.language)
        self.photoslbl2.text = "Photos".localized(LocalizationService.shared.language)
        self.enhanceLabel.text = "Enhance".localized(LocalizationService.shared.language)
        self.photoslbl3.text = "Photos".localized(LocalizationService.shared.language)
        self.filterLabel.text = "Filter".localized(LocalizationService.shared.language)
        self.photoslbl4.text = "Photos".localized(LocalizationService.shared.language)
    }
    func moveToAlbumVC(mediaType: MediaType, photoEditingFeatures: PhotoEditingFeatures) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "PhotoVideoAlbumVC") as? PhotoVideoAlbumVC else { return }
        vc.photoEditingFeature = photoEditingFeatures
        vc.mediaType = mediaType
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func moveToSavedVideoVC() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "SavedAssetsVC") as? SavedAssetsVC else { return }
        vc.viewType = .photo
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
// MARK: - Button Actions
extension PhotoEditorVC {
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.moveToSavedVideoVC()
    }
    @IBAction func resizePhotoButtonAction(_ sender: UIButton) {
        if isOpenHome {
            // New navigation - open CropImageVC directly
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let cropVC = storyboard.instantiateViewController(withIdentifier: "CropImageVC") as? CropImageVC {
                cropVC.selectedImage = self.selectedAsset
                self.navigationController?.pushViewController(cropVC, animated: true)
            }
        } else {
            // Existing navigation
            self.moveToAlbumVC(mediaType: .photos, photoEditingFeatures: .resize)
        }
    }
    
    @IBAction func addTextPhotosButtonAction(_ sender: UIButton) {
        if isOpenHome {
            // New navigation - open AddTextPhotoVC directly
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let addTextVC = storyboard.instantiateViewController(withIdentifier: "AddTextPhotoVC") as? AddTextPhotoVC {
                addTextVC.originalImage = self.selectedAsset
                self.navigationController?.pushViewController(addTextVC, animated: true)
            }
        } else {
            // Existing navigation
            self.moveToAlbumVC(mediaType: .photos, photoEditingFeatures: .addText)
        }
    }
    
    
    @IBAction func enhancePhotoButtonAction(_ sender: UIButton) {
        if isOpenHome {
            // New navigation - open PhotoEnhanceVC directly
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let enhanceVC = storyboard.instantiateViewController(withIdentifier: "PhotoEnhanceVC") as? PhotoEnhanceVC {
                enhanceVC.image = self.selectedAsset
                self.navigationController?.pushViewController(enhanceVC, animated: true)
            }
        } else {
            // Existing navigation
            self.moveToAlbumVC(mediaType: .photos, photoEditingFeatures: .enhance)
        }
    }
    
    @IBAction func filterPhotosButtonAction(_ sender: UIButton) {
        if isOpenHome {
            // New navigation - open FilterPhotoVC directly
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let filterVC = storyboard.instantiateViewController(withIdentifier: "FilterPhotoVC") as? FilterPhotoVC {
                filterVC.originalImage = self.selectedAsset
                self.navigationController?.pushViewController(filterVC, animated: true)
            }
        } else {
            // Existing navigation
            self.moveToAlbumVC(mediaType: .photos, photoEditingFeatures: .filter)
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
