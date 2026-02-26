//
//  ViewController.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import UIKit
import AWSCore
import Lottie

class LoadingVC: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lottieAnimationView: UIView!
    
    private var loadingAnimation: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    func setUI() {
        // Stop and hide the activity indicator
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        // Start Lottie animation
        startLottieAnimation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(goToNextScreen), name: NSNotification.Name(rawValue: "naviToTab"), object: nil)
    }

    private func startLottieAnimation() {
        // Unhide the lottieAnimationView before starting animation
        lottieAnimationView.isHidden = false
        
        // Create and configure Lottie animation
        loadingAnimation = LottieAnimationView(name: "Loading")
        loadingAnimation?.frame = lottieAnimationView.bounds
        loadingAnimation?.contentMode = .scaleAspectFit
        loadingAnimation?.loopMode = .loop
        loadingAnimation?.animationSpeed = 1.0
        
        if let animationView = loadingAnimation {
            lottieAnimationView.addSubview(animationView)
            animationView.play()
        }
        
        // Call config API immediately
        NetworkManager.shared.fetchRemoteConfig(from: self) { result in
            switch result {
            case .success(let json):
                if let json = json as? [String: Any] {
                    let jsonDict = json
                    bannerId = (jsonDict["bannerId"] as AnyObject).stringValue ?? ""
                    nativeId = (jsonDict["nativeId"] as AnyObject).stringValue ?? ""
                    interstialId = (jsonDict["interstialId"] as AnyObject).stringValue ?? ""
                    appopenId = (jsonDict["appopenId"] as AnyObject).stringValue ?? ""
                    rewardId = (jsonDict["rewardId"] as AnyObject).stringValue ?? ""
                    
                    addButtonColor = (jsonDict["addButtonColor"] as AnyObject).stringValue ?? "#7462FF"
                    let customInterstial = (jsonDict["customInterstial"] as AnyObject).intValue ?? 0
                    
                    adsCount = (jsonDict["afterClick"] as AnyObject).intValue ?? 4
                    isDelete = (jsonDict["isDeleted"] as AnyObject).intValue ?? 0
                    adsPlus = customInterstial == 0  ?  adsCount - 1 : adsCount
                    
                    let extraFields = (jsonDict["extraFields"] as AnyObject).dictionaryValue ?? [:]
                    smallNativeBannerId = (extraFields?["small_native"] as AnyObject).stringValue ?? ""
                    
                    isIAPON = (extraFields?["plan"] as AnyObject).stringValue ?? ""
                    IAPRequiredForTrailor = (extraFields?["play"] as AnyObject).stringValue ?? ""
                    prefixUrl = (extraFields?["appjson"] as AnyObject).stringValue ?? ""
                    NewsAPI = (extraFields?["story"] as AnyObject).stringValue ?? ""
                    
                    Task {
                        await AppOpenAdManager.shared.loadAd()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: DispatchWorkItem(block: {
                        self.navigateToVc()
                    }))
                }
                
            case .failure(let error):
                print("❌ Failed to fetch config:", error.localizedDescription)
                
                // Fallback after 2 seconds if API fails
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.stopLottieAnimation()
                    self.goToNextScreen()
                }
            }
        }
    }
    
    private func stopLottieAnimation() {
        // Stop and remove Lottie animation
        loadingAnimation?.stop()
        loadingAnimation?.removeFromSuperview()
        loadingAnimation = nil
        
        // Hide the lottieAnimationView after animation stops
        lottieAnimationView.isHidden = true
    }
    
    func navigateToVc() {
        let credentials = AWSStaticCredentialsProvider(accessKey: ACCESS, secretKey: SECRET)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.EUWest1, credentialsProvider: credentials)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        AdsManager.shared.requestForConsentForm { (isConsentGranted) in
            if isConsentGranted {
                isfromeAppStart = true
                isComeFromSplash = true
                appOpenHome = true
                if Subscribe.get() == false {
                    AppOpenAdManager.shared.showAdIfAvailable(viewController: self)
                } else {
                    self.stopLottieAnimation()
                    self.goToNextScreen()
                }
            } else {
                isfromeAppStart = true
                isComeFromSplash = true
                appOpenHome = true
                if Subscribe.get() == false {
                    AppOpenAdManager.shared.showAdIfAvailable(viewController: self)
                } else {
                    self.stopLottieAnimation()
                    self.goToNextScreen()
                }
            }
        }
    }
    
    @objc func goToNextScreen() {
        // Stop animation before navigating
        stopLottieAnimation()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let sceneWindow = sceneDelegate.window else { return }
        
        let initialVC: UIViewController
        
        if !AppStorage.contains(UserDefaultKeys.selectedLanguage) {
            // No language set → languageVC
            initialVC = UIStoryboard(name: StoryboardName.language, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.languageVC)
        } else if !(AppStorage.get(forKey: UserDefaultKeys.hasLaunchedBefore) ?? false) {
            // First launch → Onboarding introVC1
            initialVC = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.introVC1)
            AppStorage.set(true, forKey: UserDefaultKeys.hasLaunchedBefore)
        } else {
            // Language already set → homeVC
            initialVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.homeVC)
        }
        
        // Always wrap in navigation controller
        let navController = UINavigationController(rootViewController: initialVC)
        
        // Customize navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#111111")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.tintColor = .white
        
        // Hide nav bar only for HomeVC
        if initialVC is HomeVC {
            navController.isNavigationBarHidden = true
        }
        
        sceneWindow.rootViewController = navController
        sceneWindow.makeKeyAndVisible()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window = sceneWindow
            print("✅ AppDelegate window set successfully")
        }
    }
    
    deinit {
        // Clean up animation when view controller is deallocated
        stopLottieAnimation()
        NotificationCenter.default.removeObserver(self)
    }
}
