//
//  VideoEditorVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 18/11/25.
//

import UIKit

enum VideoEditingFeatures {
    case crop
    case speed
    case merge
    case reverse
}

class VideoEditorVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cropLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var mergeLabel: UILabel!
    @IBOutlet weak var reverseLabel: UILabel!
    @IBOutlet weak var videolbl1: UILabel!
    @IBOutlet weak var videolbl2: UILabel!
    @IBOutlet weak var videolbl3: UILabel!
    @IBOutlet weak var videolbl4: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var isOpenHome: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    func setUI() {
        cropLabel.font = FontManager.shared.font(for: .sriracha, size: 24.0)
        videolbl1.font = FontManager.shared.font(for: .sriracha, size: 24.0)
        speedLabel.font = FontManager.shared.font(for: .seoulHangang, size: 24.0)
        videolbl2.font = FontManager.shared.font(for: .seoulHangang, size: 24.0)
        mergeLabel.font = FontManager.shared.font(for: .splineSans, size: 24.0)
        videolbl3.font = FontManager.shared.font(for: .splineSans, size: 24.0)
        reverseLabel.font = FontManager.shared.font(for: .anekKannada, size: 24.0)
        videolbl4.font = FontManager.shared.font(for: .anekKannada, size: 24.0)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        setLoca()
    }
    func setLoca() {
        self.titleLabel.text = "Edit".localized(LocalizationService.shared.language)
        self.saveButton.setTitle("Save".localized(LocalizationService.shared.language), for: .normal)
        self.cropLabel.text = "Crop".localized(LocalizationService.shared.language)
        self.videolbl1.text = "Videos".localized(LocalizationService.shared.language)
        self.speedLabel.text = "Speed".localized(LocalizationService.shared.language)
        self.videolbl2.text = "Videos".localized(LocalizationService.shared.language)
        self.mergeLabel.text = "Merge".localized(LocalizationService.shared.language)
        self.videolbl3.text = "Videos".localized(LocalizationService.shared.language)
        self.reverseLabel.text = "Reverse".localized(LocalizationService.shared.language)
        self.videolbl4.text = "Videos".localized(LocalizationService.shared.language)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func moveToAlbumVC(mediaType: MediaType, videoEditingFeatures: VideoEditingFeatures) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "PhotoVideoAlbumVC") as? PhotoVideoAlbumVC else { return }

        vc.mediaType = mediaType
        vc.videoEditingFeature = videoEditingFeatures
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func moveToSavedVideoVC() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        guard let vc = storyboard.instantiateViewController(withIdentifier: "SavedAssetsVC") as? SavedAssetsVC else { return }
        vc.viewType = .video
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
// MARK: - Button's Actions
extension VideoEditorVC {
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        self.moveToSavedVideoVC()
    }
    
    @IBAction func cropVideoButtonAction(_ sender: UIButton) {
        self.moveToAlbumVC(mediaType: .videos, videoEditingFeatures: .crop)
    }
    
    @IBAction func speedVideoButtonAction(_ sender: UIButton) {
        self.moveToAlbumVC(mediaType: .videos, videoEditingFeatures: .speed)
    }
    
    @IBAction func mergeVideoButtonAction(_ sender: UIButton) {
        self.moveToAlbumVC(mediaType: .videos, videoEditingFeatures: .merge)
    }
    
    @IBAction func reverseVideoButtonAction(_ sender: UIButton) {
        self.moveToAlbumVC(mediaType: .videos, videoEditingFeatures: .reverse)
    }
}
