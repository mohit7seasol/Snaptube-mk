//
//  FilterPhotoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit

class FilterPhotoVC: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filtersCollectionView: UICollectionView!
    @IBOutlet weak var intensitySlider: UISlider!
    @IBOutlet weak var sliderFillEffectView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    var originalImage: UIImage?
    var filteredImage: UIImage?
    var selectedFilterIndex: Int = 0
    var context = CIContext()
    
    // Track if collection view layout needs update
    private var needsLayoutUpdate = true
    
    // Enhanced filters with configuration
    let filters: [(name: String, filterType: FilterType, intensity: Float)] = [
        ("Original", .none, 1.0),
        ("Chrome", .photoEffectChrome, 1.0),
        ("Fade", .photoEffectFade, 1.0),
        ("Instant", .photoEffectInstant, 1.0),
        ("Mono", .photoEffectMono, 1.0),
        ("Noir", .photoEffectNoir, 1.0),
        ("Process", .photoEffectProcess, 1.0),
        ("Tonal", .photoEffectTonal, 1.0),
        ("Transfer", .photoEffectTransfer, 1.0),
        ("Sepia", .sepiaTone, 0.8),
        ("Vignette", .vignette, 1.0),
        ("Bloom", .bloom, 0.8),
        ("Sharpen", .sharpen, 0.4),
        ("Gaussian Blur", .gaussianBlur, 0.3),
        ("Color Controls", .colorControls, 0.5),
        ("Hue Adjust", .hueAdjust, 0.5)
    ]
    
    enum FilterType {
        case none
        case photoEffectChrome
        case photoEffectFade
        case photoEffectInstant
        case photoEffectMono
        case photoEffectNoir
        case photoEffectProcess
        case photoEffectTonal
        case photoEffectTransfer
        case sepiaTone
        case vignette
        case bloom
        case sharpen
        case gaussianBlur
        case colorControls
        case hueAdjust
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupSliderFillEffect()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update collection view layout after auto layout completes
        if needsLayoutUpdate {
            updateCollectionViewLayout()
            needsLayoutUpdate = false
        }
    }
    
    private func setupUI() {
        imageView.image = originalImage
        filteredImage = originalImage
        
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        
        // Setup slider
        intensitySlider.isHidden = false
        intensitySlider.minimumValue = 0.0
        intensitySlider.maximumValue = 1.0
        intensitySlider.value = 0.5
        intensitySlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        setLoca()
    }
    
    func setLoca() {
        self.titleLabel.text = "Filter Photo".localized(LocalizationService.shared.language)
        self.nextButton.setTitle("Next".localized(LocalizationService.shared.language), for: .normal)
    }
    
    private func setupSliderFillEffect() {
        sliderFillEffectView.layer.cornerRadius = sliderFillEffectView.frame.height / 2
        sliderFillEffectView.layer.masksToBounds = true
        sliderFillEffectView.backgroundColor = .clear
        
        // Create circular fill effect layer
        let fillLayer = CAShapeLayer()
        fillLayer.fillColor = UIColor.systemPink.cgColor
        fillLayer.strokeColor = UIColor.clear.cgColor
        sliderFillEffectView.layer.addSublayer(fillLayer)
        
        updateSliderFillEffect(intensity: intensitySlider.value)
    }
    
    private func updateSliderFillEffect(intensity: Float) {
        guard let fillLayer = sliderFillEffectView.layer.sublayers?.first as? CAShapeLayer else { return }

        sliderFillEffectView.layoutIfNeeded()

        let fillWidth = CGFloat(intensity) * sliderFillEffectView.bounds.width
        let radius = sliderFillEffectView.bounds.height / 2

        let path = UIBezierPath(roundedRect: CGRect(
            x: 0,
            y: 0,
            width: fillWidth,
            height: sliderFillEffectView.bounds.height
        ), cornerRadius: radius)

        fillLayer.path = path.cgPath
        fillLayer.fillColor = UIColor.systemPink.cgColor

        // Pulse animation (subtle)
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 0.25
        pulse.fromValue = 1.0
        pulse.toValue = 1.06
        pulse.autoreverses = true
        fillLayer.add(pulse, forKey: "pulse")
    }
    
    private func setupCollectionView() {
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        filtersCollectionView.register("FilterCell")
        filtersCollectionView.backgroundColor = .clear
        
        // Set estimate size to None for proper layout
        if let layout = filtersCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
        }
    }
    
    private func updateCollectionViewLayout() {
        guard let layout = filtersCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        layout.scrollDirection = .horizontal

        let height = filtersCollectionView.bounds.height
        let cellHeight = height - 10   // padding
        let cellWidth = cellHeight * 0.78   // proportional width (square-ish)

        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        filtersCollectionView.collectionViewLayout.invalidateLayout()
        filtersCollectionView.layoutIfNeeded()
    }
    
    private func applyFilter(filterType: FilterType, intensity: Float = 0.5) {
        guard let image = originalImage, let ciImage = CIImage(image: image) else { return }
        
        if filterType == .none {
            filteredImage = originalImage
            imageView.image = originalImage
            updateSliderFillEffect(intensity: intensity)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var outputImage: CIImage = ciImage
            
            switch filterType {
            case .photoEffectChrome:
                if let filter = CIFilter(name: "CIPhotoEffectChrome") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectFade:
                if let filter = CIFilter(name: "CIPhotoEffectFade") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectInstant:
                if let filter = CIFilter(name: "CIPhotoEffectInstant") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectMono:
                if let filter = CIFilter(name: "CIPhotoEffectMono") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectNoir:
                if let filter = CIFilter(name: "CIPhotoEffectNoir") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectProcess:
                if let filter = CIFilter(name: "CIPhotoEffectProcess") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectTonal:
                if let filter = CIFilter(name: "CIPhotoEffectTonal") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .photoEffectTransfer:
                if let filter = CIFilter(name: "CIPhotoEffectTransfer") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .sepiaTone:
                if let filter = CIFilter(name: "CISepiaTone") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity, forKey: kCIInputIntensityKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .vignette:
                if let filter = CIFilter(name: "CIVignette") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity * 2, forKey: kCIInputIntensityKey)
                    filter.setValue(intensity * 30, forKey: kCIInputRadiusKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .bloom:
                if let filter = CIFilter(name: "CIBloom") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity * 0.5, forKey: kCIInputIntensityKey)
                    filter.setValue(intensity * 10, forKey: kCIInputRadiusKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .sharpen:
                if let filter = CIFilter(name: "CISharpenLuminance") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity * 2, forKey: kCIInputSharpnessKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .gaussianBlur:
                if let filter = CIFilter(name: "CIGaussianBlur") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity * 10, forKey: kCIInputRadiusKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .colorControls:
                if let filter = CIFilter(name: "CIColorControls") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity, forKey: kCIInputSaturationKey)
                    filter.setValue(1.0 + (intensity * 0.5), forKey: kCIInputContrastKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            case .hueAdjust:
                if let filter = CIFilter(name: "CIHueAdjust") {
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    filter.setValue(intensity * 3.14, forKey: kCIInputAngleKey)
                    outputImage = filter.outputImage ?? ciImage
                }
                
            default:
                break
            }
            
            if let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) {
                let processedImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.filteredImage = processedImage
                    self.imageView.image = processedImage
                    self.updateSliderFillEffect(intensity: intensity)
                }
            }
        }
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let filterType = filters[selectedFilterIndex].filterType
        applyFilter(filterType: filterType, intensity: slider.value)
        updateSliderFillEffect(intensity: slider.value)
    }
     
    // MARK: - Button Actions
    @IBAction func applyFilterTapped(_ sender: UIButton) {
        showAlert(message: "Filter applied successfully!".localized(LocalizationService.shared.language))
    }
     
    @IBAction func resetTapped(_ sender: UIButton) {
        selectedFilterIndex = 0
        filteredImage = originalImage
        imageView.image = originalImage
        intensitySlider.value = 0.5
        intensitySlider.isHidden = false
        updateSliderFillEffect(intensity: intensitySlider.value)
        
        // Properly reload collection view and ensure selection is cleared
        DispatchQueue.main.async {
            self.filtersCollectionView.reloadData()
            // Explicitly select the first item
            let indexPath = IndexPath(item: 0, section: 0)
            self.filtersCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
     
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        guard let imageToSave = filteredImage else { return }
        self.navigateToPreview(with: imageToSave)
    }
     
    @IBAction func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
     
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(message: "Save error: \(error.localizedDescription)")
        } else {
            showAlert(message: "Filtered photo saved to gallery!".localized(LocalizationService.shared.language))
        }
    }
     
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Filter Photo".localized(LocalizationService.shared.language), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToPreview(with image: UIImage) {
        self.showInterAdClick()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let savePhotoVC = storyboard.instantiateViewController(withIdentifier: "SavePhotoVC") as? SavePhotoVC {
            savePhotoVC.croppedImage = image
            navigationController?.pushViewController(savePhotoVC, animated: true)
        }
    }
}

// MARK: - Collection View Delegate & DataSource
extension FilterPhotoVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        let filter = filters[indexPath.item]
        
        // Configure cell with proper selection state
        let isSelected = indexPath.item == selectedFilterIndex
        cell.configure(with: filter.name, isSelected: isSelected)
        
        if indexPath.item == 0 {
            // ORIGINAL IMAGE THUMB
            cell.filterImageView.image = UIImage(named: "origional_image")
        } else {
            // Apply filter to thumbnail
            if let originalImage = originalImage {
                DispatchQueue.global(qos: .userInteractive).async {
                    let thumbnail = self.createFilteredThumbnail(image: originalImage,
                                                                 filterType: filter.filterType,
                                                                 intensity: filter.intensity)
                    DispatchQueue.main.async {
                        // Ensure cell hasn't been reused
                        if let currentIndexPath = collectionView.indexPath(for: cell),
                           currentIndexPath == indexPath {
                            cell.filterImageView.image = thumbnail
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Update selected index
        let previousIndex = selectedFilterIndex
        selectedFilterIndex = indexPath.item
        
        // Update UI for both previous and current selection
        if let previousCell = collectionView.cellForItem(at: IndexPath(item: previousIndex, section: 0)) as? FilterCell {
            previousCell.configure(with: filters[previousIndex].name, isSelected: false)
        }
        
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            selectedCell.configure(with: filters[indexPath.item].name, isSelected: true)
        }
        
        let selectedFilter = filters[indexPath.item]
        intensitySlider.isHidden = false
        intensitySlider.value = (indexPath.item == 0) ? 0.5 : selectedFilter.intensity

        applyFilter(filterType: selectedFilter.filterType, intensity: intensitySlider.value)
        updateSliderFillEffect(intensity: intensitySlider.value)
    }
    
    private func createFilteredThumbnail(image: UIImage, filterType: FilterType, intensity: Float) -> UIImage? {
        let thumbnailSize = CGSize(width: 60, height: 60)
        
        UIGraphicsBeginImageContext(thumbnailSize)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if filterType == .none {
            return thumbnail
        }
        
        guard let ciThumbnail = CIImage(image: thumbnail ?? image) else { return thumbnail }
        
        var outputImage: CIImage = ciThumbnail
        
        switch filterType {
        case .sepiaTone:
            if let filter = CIFilter(name: "CISepiaTone") {
                filter.setValue(ciThumbnail, forKey: kCIInputImageKey)
                filter.setValue(intensity, forKey: kCIInputIntensityKey)
                outputImage = filter.outputImage ?? ciThumbnail
            }
        case .vignette:
            if let filter = CIFilter(name: "CIVignette") {
                filter.setValue(ciThumbnail, forKey: kCIInputImageKey)
                filter.setValue(intensity, forKey: kCIInputIntensityKey)
                outputImage = filter.outputImage ?? ciThumbnail
            }
        case .photoEffectChrome, .photoEffectFade, .photoEffectInstant, .photoEffectMono,
             .photoEffectNoir, .photoEffectProcess, .photoEffectTonal, .photoEffectTransfer:
            if let filterName = getFilterName(for: filterType),
               let filter = CIFilter(name: filterName) {
                filter.setValue(ciThumbnail, forKey: kCIInputImageKey)
                outputImage = filter.outputImage ?? ciThumbnail
            }
        default:
            break
        }
        
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return thumbnail
    }
    
    private func getFilterName(for filterType: FilterType) -> String? {
        switch filterType {
        case .photoEffectChrome: return "CIPhotoEffectChrome"
        case .photoEffectFade: return "CIPhotoEffectFade"
        case .photoEffectInstant: return "CIPhotoEffectInstant"
        case .photoEffectMono: return "CIPhotoEffectMono"
        case .photoEffectNoir: return "CIPhotoEffectNoir"
        case .photoEffectProcess: return "CIPhotoEffectProcess"
        case .photoEffectTonal: return "CIPhotoEffectTonal"
        case .photoEffectTransfer: return "CIPhotoEffectTransfer"
        default: return nil
        }
    }
}
