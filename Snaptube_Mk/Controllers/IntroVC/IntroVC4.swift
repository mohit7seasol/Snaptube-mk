//
//  IntroVC4.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import UIKit

class IntroVC4: UIViewController {
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
        self.nextLabel.text = "Done".localized(LocalizationService.shared.language)
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
//    func goToHomeScreen() {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let sceneDelegate = windowScene.delegate as? SceneDelegate,
//              let window = sceneDelegate.window else { return }
//        
//        let tabBarVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
//            .instantiateViewController(withIdentifier: Controllers.homeVC)
//        
//        window.rootViewController = tabBarVC
//        window.makeKeyAndVisible()
//    }
    func goToHomeScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let sceneWindow = sceneDelegate.window else { return }
        
        let homeVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
            .instantiateViewController(withIdentifier: Controllers.homeVC)
        
        // Always wrap in navigation controller for consistent navigation
        let navController = UINavigationController(rootViewController: homeVC)
        
        // Customize navigation bar - same as other navigation methods
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#111111")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.tintColor = .white
        
        // Hide nav bar for HomeVC
        navController.isNavigationBarHidden = true
        
        sceneWindow.rootViewController = navController
        sceneWindow.makeKeyAndVisible()
        
        // Set AppDelegate window
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window = sceneWindow
            print("✅ AppDelegate window set successfully from goToHomeScreen")
        }
    }
    
    @IBAction func doneButtonAction(_ sender: UIButton) {
        self.goToHomeScreen()
    }
    
}
