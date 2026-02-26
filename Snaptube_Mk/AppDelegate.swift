//
//  AppDelegate.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import UIKit
import IQKeyboardManagerSwift
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var showAdTimer: Timer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Subscribe.save(true)
        setupIQKeyboardManager()
        return true
    }

    func loadDidFinish() {
        setupAppLifecycleObservers()
        // Load ads on app launch
        loadAndShowInterstitialAds()
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["3566CA2D-CE22-4567-A7AD-FAAFB5A5DCC5"]
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    private func setupIQKeyboardManager() {
        // Enable IQKeyboardManager
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        // Appearance
        IQKeyboardManager.shared.toolbarConfiguration.tintColor = UIColor.black
        IQKeyboardManager.shared.toolbarConfiguration.barTintColor = UIColor.white
    }
}

// MARK: - Interstitial Ads
extension AppDelegate {
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 App will enter foreground - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App became active - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    private func loadAndShowInterstitialAds() {
        // Check subscription status first
        if Subscribe.get() {
            print("🎫 User is subscribed - Skipping interstitial ads")
            return
        }
        
        print("🔄 Loading interstitial ads...")
        
        // Load interstitial ads using existing AdsManager method
        AdsManager.shared.loadInterstitialAd()
        
        // Show the ad after a short delay to ensure it's loaded
        showAdTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.showInterstitialAdIfReady()
        }
    }
    
    private func showInterstitialAdIfReady() {
        // Check subscription status again
        if Subscribe.get() {
            print("🎫 User is subscribed - Not showing ads")
            return
        }
        
        // Check if interstitial ad is ready
        if AdsManager.shared.isInterstitialAdReady() {
            print("✅ Interstitial ad is ready - Showing now")
            
            // Get the top view controller and show the ad
            if let topViewController = getTopViewController() {
                print("🎬 Presenting interstitial ad on: \(topViewController)")
                
                // Use the existing AdsManager method to show the ad
                AdsManager.shared.loadInterstitialAd()
            } else {
                print("❌ Could not find top view controller")
            }
        } else {
            print("❌ Interstitial ad not ready yet")
        }
        
        // Clean up timer
        showAdTimer?.invalidate()
        showAdTimer = nil
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let window = window else { return nil }
        
        var topController = window.rootViewController
        
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
