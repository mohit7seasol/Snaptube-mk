//
//  LanguageVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 14/11/25.
//

import UIKit

enum ChooseLanguage: String, CaseIterable {
    case english = "English"
    case spanish = "Spanish"
    case hindi = "Hindi"
    case danish = "Danish"
    case german = "German"
    case italian = "Italian"
    case portuguese = "Portuguese"
    case turkish = "Turkish"
    
    // Map ChooseLanguage → Language (for localization)
    var languageCode: Language {
        switch self {
        case .english: return .English
        case .spanish: return .Spanish
        case .hindi: return .Hindi
        case .danish: return .Danish
        case .german: return .German
        case .italian: return .Italian
        case .portuguese: return .Portuguese
        case .turkish: return .Turkish
        }
    }
}

// MARK: - Language Enum Localized Names
extension Language {
    var localizedName: String {
        switch self {
        case .English: return "English".localized(self)
        case .Spanish: return "Spanish".localized(self)
        case .Hindi: return "हिंदी".localized(self)
        case .Danish: return "dansk".localized(self)
        case .German: return "Deutsch".localized(self)
        case .Italian: return "Italiana".localized(self)
        case .Portuguese: return "Português".localized(self)
        case .Turkish: return "Türkçe".localized(self)
        }
    }
}

class LanguageVC: UIViewController {
    @IBOutlet weak var selecteLanLabel: UILabel!
    @IBOutlet weak var chooseYourLablel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneButtonLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    var countries: ChooseLanguage = .english
    var selectedLanguage: ChooseLanguage?
    var selectedIndexPath: IndexPath?
    var isOpenSetting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpUI()
    }
    
    func setUpUI() {
        setCollection()
        
        // Reload to show selected gradient border
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        if isOpenSetting {
            backButton.isHidden = false
        } else {
            backButton.isHidden = true
        }
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        restorePreviousLanguageSelection()
        setLoca()
    }
    
    func setLoca() {
        self.selecteLanLabel.text = "Select Language".localized(LocalizationService.shared.language)
        self.chooseYourLablel.text = "Choose your preferred language to continue".localized(LocalizationService.shared.language)
        self.doneButtonLabel.text = "Done".localized(LocalizationService.shared.language)
    }
    
    private func setCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        // For 2x2 layout with proper spacing
        let spacing: CGFloat = 10
        let inset: CGFloat = 10
        
        // Calculate width for 2 columns: (screen width - left inset - right inset - spacing between columns) / 2
        let totalWidth = view.frame.width - (inset * 2) - spacing
        let width = totalWidth / 2
        
        // Set fixed height as per requirement
        let height: CGFloat = 110
        
        layout.itemSize = CGSize(width: width, height: height)
        layout.minimumInteritemSpacing = spacing    // Horizontal spacing between columns
        layout.minimumLineSpacing = spacing         // Vertical spacing between rows
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(["LanguageCell"])
    }
    
    private func restorePreviousLanguageSelection() {
        if let savedLanguage = AppStorage.get(forKey: UserDefaultKeys.selectedLanguage) as String?,
           let language = ChooseLanguage(rawValue: savedLanguage) {
            // Restore previously selected language
            countries = language
            if let index = ChooseLanguage.allCases.firstIndex(of: language) {
                selectedIndexPath = IndexPath(item: index, section: 0)
                selectedLanguage = language
            }
        } else {
            // No language saved in UserDefaults - set default to first item (index 0)
            setDefaultLanguageSelection()
        }
        
        collectionView.reloadData()
    }
    
    private func setDefaultLanguageSelection() {
        // Set default selection to first language (index 0)
        selectedIndexPath = IndexPath(item: 0, section: 0)
        selectedLanguage = ChooseLanguage.allCases[0]
        countries = ChooseLanguage.allCases[0]
        
        print("No previous language found. Setting default to: \(selectedLanguage?.rawValue ?? "None")")
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonClickAction(_ sender: UIButton) {
        guard let selectedLanguage = selectedLanguage else {
            // If no language is selected, use the default (first one)
            self.selectedLanguage = ChooseLanguage.allCases[0]
            self.selectedIndexPath = IndexPath(item: 0, section: 0)
            self.collectionView.reloadData()
            
            // Proceed with default selection
            handleLanguageSelection(selectedLanguage: ChooseLanguage.allCases[0])
            return
        }
        
        handleLanguageSelection(selectedLanguage: selectedLanguage)
    }
    
    private func handleLanguageSelection(selectedLanguage: ChooseLanguage) {
        // Handle the selected language
        print("Selected language: \(selectedLanguage.rawValue)")
        print("Language code: \(selectedLanguage.languageCode)")
        print("Localized name: \(selectedLanguage.languageCode.localizedName)")
        
        // Save selected language and update app language
        AppStorage.set(selectedLanguage.rawValue, forKey: UserDefaultKeys.selectedLanguage)
        
        // Set the language in LocalizationService
        LocalizationService.shared.language = selectedLanguage.languageCode
        
        // Delay resetting root until notification is posted
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Update root view controller
            self.updateRootViewController()
        }
    }
    
    private func updateRootViewController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let sceneWindow = sceneDelegate.window else { return }
        
        let initialVC: UIViewController
        
        if !(AppStorage.get(forKey: UserDefaultKeys.hasLaunchedBefore) ?? false) {
            // First launch → Onboarding
            initialVC = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.introVC1)
        } else {
            // Main screen
            initialVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.homeVC)
        }
        
        // Always wrap in navigation controller - CRITICAL FIX
        let navController = UINavigationController(rootViewController: initialVC)
        
        // Customize navigation bar - same as goToNextScreen
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
        
        // Set AppDelegate window
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window = sceneWindow
            print("✅ AppDelegate window set successfully from updateRootViewController")
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension LanguageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ChooseLanguage.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LanguageCell", for: indexPath) as? LanguageCell ?? LanguageCell()
        
        let language = ChooseLanguage.allCases[indexPath.item]
        cell.parentView.backgroundColor = #colorLiteral(red: 0.06666666667, green: 0.06666666667, blue: 0.06666666667, alpha: 1)
        // Set country name using localized name
        cell.countryNameLabel.text = language.languageCode.localizedName
        
        // Set image - using the rawValue in lowercase for image name
        cell.countryIconImageView.image = UIImage(named: language.rawValue.lowercased())
        
        // Set selection state
        if selectedIndexPath == indexPath {
            cell.setSelectedState()
        } else {
            cell.setDeselectedState()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        selectedLanguage = ChooseLanguage.allCases[indexPath.item]
        collectionView.reloadData()
        
        // Update UI or perform any immediate action on selection
        print("Selected: \(selectedLanguage?.rawValue ?? "None")")
    }
}
