//
//  HistoryVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 25/11/25.
//

import UIKit

class HistoryVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var noHistoryView: UIView!
    @IBOutlet weak var oppsLabel: UILabel!
    @IBOutlet weak var noDataFoundLabel: UILabel!
    
    // Array to hold history items
    private var historyItems: [HistoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadHistoryData()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistoryData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Force layout update after view appears
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        noHistoryView.isHidden = true
        collectionView.isHidden = false
        setLoca()
    }
    func setLoca() {
        self.titleLabel.text = "History".localized(LocalizationService.shared.language)
        self.oppsLabel.text =  "Oops!".localized(LocalizationService.shared.language)
        self.noDataFoundLabel.text = "No Data Found".localized(LocalizationService.shared.language)
    }
    
    private func setupCollectionView() {
        collectionView.register(UINib(nibName: "HistoryVCCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HistoryVCCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .always
        
        // Setup collection view layout
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    private func loadHistoryData() {
        print("Loading history data...".localized(LocalizationService.shared.language))
        
        // Get history items from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "downloadHistory") {
            print("Found data in UserDefaults")
            do {
                let items = try JSONDecoder().decode([HistoryItem].self, from: data)
                historyItems = items.reversed() // Show latest first
                print("Loaded \(historyItems.count) history items")
                
                // Debug: Print each item
                for (index, item) in historyItems.enumerated() {
                    print("Item \(index): \(item.name) - \(item.link)")
                }
            } catch {
                print("Error decoding history items: \(error)")
                historyItems = []
            }
        } else {
            print("No data found in UserDefaults for key 'downloadHistory'")
            historyItems = []
        }
        
        updateUI()
        collectionView.reloadData()
    }
    
    private func updateUI() {
        noHistoryView.isHidden = !historyItems.isEmpty
        collectionView.isHidden = historyItems.isEmpty
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension HistoryVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistoryVCCollectionViewCell", for: indexPath) as! HistoryVCCollectionViewCell
        
        let item = historyItems[indexPath.item]
        cell.nameLabel.text = item.name
        cell.linkLabel.text = item.link
        
        // Initially hide options view
        cell.optionsView.isHidden = true
        
        // Configure more options button
        cell.moreOptionsButton.tag = indexPath.item
        cell.moreOptionsButton.addTarget(self, action: #selector(moreOptionsTapped(_:)), for: .touchUpInside)
        
        // Configure share button
        cell.shareButton.tag = indexPath.item
        cell.shareButton.addTarget(self, action: #selector(shareTapped(_:)), for: .touchUpInside)
        
        // Configure delete button
        cell.deleteButton.tag = indexPath.item
        cell.deleteButton.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let horizontalInset: CGFloat = 10
        let width = collectionView.bounds.width - (horizontalInset * 2)
        return CGSize(width: width, height: 120)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Button Actions
    @objc private func moreOptionsTapped(_ sender: UIButton) {
        let indexPath = IndexPath(item: sender.tag, section: 0)
        
        // Toggle options view for this cell
        if let cell = collectionView.cellForItem(at: indexPath) as? HistoryVCCollectionViewCell {
            cell.optionsView.isHidden = !cell.optionsView.isHidden
            
            // Hide other cells' options views
            hideAllOptionsViews(except: indexPath)
        }
    }
    
    private func hideAllOptionsViews(except excludedIndexPath: IndexPath? = nil) {
        for case let cell as HistoryVCCollectionViewCell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell),
               indexPath != excludedIndexPath {
                cell.optionsView.isHidden = true
            }
        }
    }
    
    @objc private func shareTapped(_ sender: UIButton) {
        let item = historyItems[sender.tag]
        
        // Hide options view first
        hideAllOptionsViews()
        
        // Create activity view controller for sharing
        let shareText = "\(item.name): \(item.link)"
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // For iPad support
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func deleteTapped(_ sender: UIButton) {
        let index = sender.tag
        
        // Hide options view first
        hideAllOptionsViews()
        
        // Show confirmation alert
        let alert = UIAlertController(title: "Delete Item".localized(LocalizationService.shared.language),
                                    message: "Are you sure you want to delete this item?".localized(LocalizationService.shared.language),
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete".localized(LocalizationService.shared.language), style: .destructive, handler: { _ in
            self.deleteItem(at: index)
        }))
        
        present(alert, animated: true)
    }
    
    private func deleteItem(at index: Int) {
        // Remove item from array
        historyItems.remove(at: index)
        
        // Update UserDefaults
        saveUpdatedHistory()
        
        // Reload collection view
        collectionView.reloadData()
        updateUI()
    }
    
    private func saveUpdatedHistory() {
        let reversedItems = historyItems.reversed() // Store in original order
        if let encoded = try? JSONEncoder().encode(Array(reversedItems)) {
            UserDefaults.standard.set(encoded, forKey: "downloadHistory")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func hideAllOptionsViews() {
        for case let cell as HistoryVCCollectionViewCell in collectionView.visibleCells {
            cell.optionsView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Hide options view when cell is tapped
        hideAllOptionsViews()
        
        let item = historyItems[indexPath.item]
        
        // Copy link to clipboard when cell is tapped
        UIPasteboard.general.string = item.link
        
        // Show feedback
        showToast(message: "Link copied to clipboard".localized(LocalizationService.shared.language))
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 150, y: self.view.frame.size.height-100, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

// Add this struct at the top of HistoryVC file (outside the class)
struct HistoryItem: Codable {
    let name: String
    let link: String
    let date: Date
}
