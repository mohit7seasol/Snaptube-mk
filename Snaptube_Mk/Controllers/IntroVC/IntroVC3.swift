//
//  IntroVC3.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import UIKit

class IntroVC3: UIViewController {
    @IBOutlet weak var nativeAdContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var nextButtonView: UIView!
    @IBOutlet weak var nextLabel: UILabel!
    @IBOutlet weak var addViewHeightConstant: NSLayoutConstraint!
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        AppStorage.set(true, forKey: UserDefaultKeys.hasLaunchedBefore)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    func setUI() {
        subscribeNativeAd()
        setLoca()
    }
    func setLoca() {
        self.titleLabel.text = "Filter Your Photo".localized(LocalizationService.shared.language)
        self.subTitleLabel.text = "Transform your image with beautiful effects.".localized(LocalizationService.shared.language)
        self.nextLabel.text = "Next".localized(LocalizationService.shared.language)
    }
    
    func subscribeNativeAd() {
        if Subscribe.get() == false {
            googleNativeAds.loadAds(self) { nativeAdsTemp in
                print("✅ TopPickVC Native Ad Loaded")
                self.isShowNativeAds = true
                self.addViewHeightConstant.constant = 180
                self.nativeAdContainerView.isHidden = false
                
                self.nativeAdContainerView.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: UIScreen.main.bounds.width,
                    height: 200
                )
                
                self.googleNativeAds.showAdsView8(
                    nativeAd: nativeAdsTemp,
                    view: self.nativeAdContainerView
                )
            }
            
            googleNativeAds.failAds(self) { fail in
                print("❌ TopPickVC Native Ad Failed to Load")
                self.isShowNativeAds = false
                DispatchQueue.main.async {
                    self.addViewHeightConstant.constant = 0
                    self.nativeAdContainerView.isHidden = true
                }
            }
        } else {
            isShowNativeAds = false
            self.addViewHeightConstant.constant = 0
            self.nativeAdContainerView.isHidden = true
        }
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IntroVC4") as! IntroVC4
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
