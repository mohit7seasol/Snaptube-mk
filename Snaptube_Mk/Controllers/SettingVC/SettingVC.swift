//
//  SettingVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 22/11/25.
//

import UIKit

class SettingVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var languageView: UIView!
    @IBOutlet weak var langaugeLabel: UILabel!
    @IBOutlet weak var aboutUsView: UIView!
    @IBOutlet weak var aboutUsLabel: UILabel!
    @IBOutlet weak var rateUsLabel: UILabel!
    @IBOutlet weak var privacyPolicyView: UIView!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var inviteFriendView: UIView!
    @IBOutlet weak var inviteLabel: UILabel!
    @IBOutlet weak var termsView: UIView!
    @IBOutlet weak var termsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLoca()
    }
    func setLoca() {
        self.titleLabel.text = "Setting".localized(LocalizationService.shared.language)
        self.langaugeLabel.text = "Language".localized(LocalizationService.shared.language)
        self.aboutUsLabel.text = "About Us".localized(LocalizationService.shared.language)
        self.rateUsLabel.text = "Rate Us".localized(LocalizationService.shared.language)
        self.privacyLabel.text = "Privacy Policy".localized(LocalizationService.shared.language)
        self.inviteLabel.text = "Invite Friends".localized(LocalizationService.shared.language)
        self.termsLabel.text = "Terms & Conditions".localized(LocalizationService.shared.language)
    }
    func moveToLanguageScreen() {
        let storyboard = UIStoryboard(name: StoryboardName.language, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: Controllers.languageVC) as? LanguageVC {
            vc.hidesBottomBarWhenPushed = true
            vc.isOpenSetting = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
// MARK: - Button Actions
extension SettingVC {
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func languageButtonAction(_ sender: UIButton) {
        self.moveToLanguageScreen()
    }
    @IBAction func aboutUsButtonAction(_ sender: UIButton) {
        openURL(AppConstant.aboutUsURL)
    }
    @IBAction func rateUsButtonAction(_ sender: UIButton) {
        let appID = AppConstant.appID
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func privacyPolicyButtonAction(_ sender: UIButton) {
        openURL(AppConstant.privacyPolicyURL)
    }
    @IBAction func inviteFriendButtonAction(_ sender: UIButton) {
        openURL(AppConstant.inviteFriendsURL)
    }
    @IBAction func termsButtonAction(_ sender: UIButton) {
        openURL(AppConstant.tremsOfUseURL)
    }
}
