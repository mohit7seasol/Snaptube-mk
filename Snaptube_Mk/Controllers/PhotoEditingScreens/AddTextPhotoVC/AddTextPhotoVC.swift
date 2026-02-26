//
//  AddTextPhotoVC.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit // hello

class AddTextPhotoVC: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionViewFeaturesTypes: UICollectionView!{
        didSet{
            collectionViewFeaturesTypes.delegate = self
            collectionViewFeaturesTypes.dataSource = self
        }
    }
    @IBOutlet weak var collectionViewFeatures: UICollectionView!{
        didSet{
            collectionViewFeatures.delegate = self
            collectionViewFeatures.dataSource = self
        }
    }
    @IBOutlet weak var fontStyleView: UIView!
    @IBOutlet weak var shadowSlidersView: UIView!
    @IBOutlet weak var topBottomShadowSlider: UISlider!
    @IBOutlet weak var leftRightShadowSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addTextPhotoButton: UIButton!
    @IBOutlet weak var collectionFeaturesTypesWidthConstant: NSLayoutConstraint!
    @IBOutlet weak var nextButton: UIButton!
    
    
    // Data arrays
    let featureTypes = [
        ("Font", "font_unselected", "font_selected"),
        ("Style", "style_unselected", "style_selected"),
        ("Text Color", "text_unselected", "text_selected"),
        ("Shadow", "shadow_unselected", "shadow_selected"),
        ("Sticker", "sticker_unselected", "sticker_selected")
    ]
    
    let fonts = ["ArialMT", "Helvetica", "TimesNewRomanPSMT", "Courier", "Verdana", "Georgia", "Impact", "ComicSansMS"]
    let colors: [UIColor] = [.red, .blue, .green, .yellow, .purple, .orange, .black, .white, .cyan, .magenta, .brown, .gray]
    let stickers = ["s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10","s11", "s12", "s13", "s14", "s15", "s16", "s17", "s18", "s19", "s20","s21", "s22", "s23", "s24", "s25", "s26", "s27", "s28", "s29", "s30","s31", "s32", "s33", "s34", "s35"]
    
    // Current selections
    var selectedFeatureIndex = 0
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var textAlignment: NSTextAlignment = .center
    var selectedColor: UIColor = .white
    var shadowOffset = CGSize(width: 0, height: 0)
    var shadowColor: UIColor = .black
    var shadowBlur: CGFloat = 0
    var selectedFont: String = "ArialMT"
    var fontSize: CGFloat = 30
    
    // Track selected indices for each feature
    var selectedFontIndex: Int = 0
    var selectedColorIndex: Int = 0
    var selectedStickerIndex: Int = 0
    
    // VCSticker management
    var currentSticker: VCBaseSticker?
    
    // Add this property to receive the image
    var originalImage: UIImage?
    
    // Add these properties to prevent unwanted scrolling
    var shouldPreventScrolling = false
    var lastContentOffset: CGPoint = .zero
    
    // Add this property to track the original font size for new stickers
    var defaultFontSize: CGFloat = 30
    // Remove the fontSize property and replace with currentFontSize that preserves size during editing
    var currentFontSize: CGFloat = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        setupUI()
        setupImage()
        setupGestures()
        setLoca()
        calculateCollectionViewWidth()
    }
    
    private func calculateCollectionViewWidth() {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let itemWidth: CGFloat = screenWidth / 5 - 16
        let spacing: CGFloat = 8
        let sectionInset: CGFloat = 16
        let numberOfItems = featureTypes.count
        
        let totalWidth = (itemWidth * CGFloat(numberOfItems)) +
                        (spacing * CGFloat(numberOfItems - 1)) +
                        sectionInset
        
        collectionFeaturesTypesWidthConstant.constant = totalWidth
        view.layoutIfNeeded()
    }
    
    func setLoca() {
        self.titleLabel.text = "Add Text Photo".localized(LocalizationService.shared.language)
        self.addTextPhotoButton.setTitle("Add Text Photo".localized(LocalizationService.shared.language), for: .normal)
        self.nextButton.setTitle("Next".localized(LocalizationService.shared.language), for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewLayouts()
    }
    
    private func setupCollectionViews() {
        collectionViewFeaturesTypes.showsHorizontalScrollIndicator = false
        collectionViewFeaturesTypes.allowsMultipleSelection = false
        
        // Setup Features CollectionView
        collectionViewFeatures.showsHorizontalScrollIndicator = false
        collectionViewFeatures.isHidden = false
        
        // Register cells
        collectionViewFeaturesTypes.register(UINib(nibName: "FontStyleCell", bundle: nil), forCellWithReuseIdentifier: "FontStyleCell")
        collectionViewFeatures.register(UINib(nibName: "FontFeaturesCell", bundle: nil), forCellWithReuseIdentifier: "FontFeaturesCell")
        collectionViewFeatures.register(UINib(nibName: "FontTextColorCell", bundle: nil), forCellWithReuseIdentifier: "FontTextColorCell")
        
        // Select first item by default
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(item: 0, section: 0)
            self.collectionViewFeaturesTypes.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            self.handleFeatureSelection(at: 0)
            self.collectionViewFeaturesTypes.reloadData()
        }
    }
    
    private func updateCollectionViewLayouts() {
        guard let typesCV = collectionViewFeaturesTypes,
              let featuresCV = collectionViewFeatures else {
            return
        }

        typesCV.layoutIfNeeded()
        featuresCV.layoutIfNeeded()

        // Circular layout for feature types
        let layoutTypes = UICollectionViewFlowLayout()
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        layoutTypes.scrollDirection = .horizontal
        layoutTypes.itemSize = CGSize(width: screenWidth / 5 - 16, height: 82)
        layoutTypes.minimumInteritemSpacing = 8
        layoutTypes.minimumLineSpacing = 8
        layoutTypes.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        typesCV.collectionViewLayout = layoutTypes

        let layoutFeatures = UICollectionViewFlowLayout()
        layoutFeatures.scrollDirection = .horizontal
        layoutFeatures.minimumInteritemSpacing = 12
        layoutFeatures.minimumLineSpacing = 12
        layoutFeatures.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        switch selectedFeatureIndex {
        case 0: // Font
            layoutFeatures.itemSize = CGSize(width: 80, height: 40)
        case 2: // Text Color
            layoutFeatures.itemSize = CGSize(width: 40, height: 40)
        case 4: // Sticker
            layoutFeatures.itemSize = CGSize(width: 90, height: 40)
        default:
            layoutFeatures.itemSize = CGSize(width: 60, height: 60)
        }

        featuresCV.collectionViewLayout = layoutFeatures
    }
    
    private func setupUI() {
        fontStyleView.isHidden = true
        shadowSlidersView.isHidden = true
        collectionViewFeatures.isHidden = false
        
        topBottomShadowSlider.minimumValue = -10
        topBottomShadowSlider.maximumValue = 10
        topBottomShadowSlider.value = 0
        
        leftRightShadowSlider.minimumValue = -10
        leftRightShadowSlider.maximumValue = 10
        leftRightShadowSlider.value = 0
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
    }
    
    private func setupImage() {
        if let image = originalImage {
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
        }
    }
    
    private func setupGestures() {
        // Only keep gesture for finishing editing when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        tapGesture.cancelsTouchesInView = false
        imageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleImageTap(_ gesture: UITapGestureRecognizer) {
        // Only finish editing current sticker if tap is outside
        if currentSticker != nil {
            currentSticker?.finishEditing()
            currentSticker = nil
        }
    }
    
    private func createNewTextSticker(at location: CGPoint) {
        let textSticker = VCLabelSticker(center: location)
        imageView.addSubview(textSticker)
        
        // Configure text sticker
        textSticker.textColor = selectedColor
        textSticker.borderColor = .white
        textSticker.text = "Double tap to edit"
        textSticker.closeBtnEnable = true
        textSticker.resizeBtnEnable = true
        textSticker.restrictionEnable = true
        
        // Use default font size for new stickers, not the currentFontSize which might be modified
        if let font = UIFont(name: selectedFont, size: defaultFontSize) {
            textSticker.textField.font = font
        }
        
        // Store the original font size in the sticker for reference
        textSticker.tag = Int(defaultFontSize * 100) // Store as tag for easy retrieval
        
        textSticker.onBeginEditing = { [weak self] in
            if textSticker != self?.currentSticker {
                self?.currentSticker?.finishEditing()
                self?.currentSticker = textSticker
                
                // When editing starts, update currentFontSize to match this sticker's size
                if let editingFont = textSticker.textField.font {
                    self?.currentFontSize = editingFont.pointSize
                }
            }
        }
        
        textSticker.onClose = { [weak self] in
            if textSticker == self?.currentSticker {
                self?.currentSticker = nil
            }
        }
        // ADD ROTATION CALLBACK
        textSticker.onRotate = { [weak self] in
            // Rotate the text sticker by 45 degrees (π/4 radians) each time the button is tapped
            let rotationAngle: CGFloat = .pi / 4 // 45 degrees in radians
            
            // Apply rotation transform with animation
            UIView.animate(withDuration: 0.2) {
                textSticker.transform = textSticker.transform.rotated(by: rotationAngle)
            }
            
            // Optional: You can also add haptic feedback for better user experience
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            // Optional: Print current rotation angle for debugging
            let currentAngle = textSticker.cAngle
            print("Current rotation angle: \(currentAngle * 180 / .pi) degrees")
        }
        
        currentSticker = textSticker
    }
    
    private func createImageSticker(with imageName: String, at location: CGPoint) {
        let imageSticker = VCImageSticker(frame: CGRect(x: location.x - 50, y: location.y - 50, width: 100, height: 100))
        
        if let image = UIImage(named: imageName) {
            imageSticker.imageView.image = image
            imageSticker.imageView.contentMode = .scaleAspectFit
        }
        
        imageSticker.borderColor = .cyan
        imageSticker.closeBtnEnable = true
        imageSticker.resizeBtnEnable = true
        imageSticker.restrictionEnable = true
        
        imageView.addSubview(imageSticker)
        
        imageSticker.onBeginEditing = { [weak self] in
            if imageSticker != self?.currentSticker {
                self?.currentSticker?.finishEditing()
                self?.currentSticker = imageSticker
            }
        }
        
        imageSticker.onClose = { [weak self] in
            if imageSticker == self?.currentSticker {
                self?.currentSticker = nil
            }
        }
        
        currentSticker = imageSticker
    }
    
    private func handleFeatureSelection(at index: Int) {
        selectedFeatureIndex = index
        
        switch index {
        case 0: // Font
            fontStyleView.isHidden = true
            shadowSlidersView.isHidden = true
            collectionViewFeatures.isHidden = false
            
        case 1: // Style
            fontStyleView.isHidden = false
            shadowSlidersView.isHidden = true
            collectionViewFeatures.isHidden = true
            
        case 2: // Text Color
            fontStyleView.isHidden = true
            shadowSlidersView.isHidden = true
            collectionViewFeatures.isHidden = false
            
        case 3: // Shadow
            fontStyleView.isHidden = true
            shadowSlidersView.isHidden = false
            collectionViewFeatures.isHidden = true
            
        case 4: // Sticker
            fontStyleView.isHidden = true
            shadowSlidersView.isHidden = true
            collectionViewFeatures.isHidden = false
            
        default:
            break
        }
        
        updateCollectionViewLayouts()
        
        // Save current scroll position before reloading
        lastContentOffset = collectionViewFeatures.contentOffset
        
        // Force reload to ensure proper selection styling
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Layout first to ensure frames are calculated
            self.collectionViewFeaturesTypes.layoutIfNeeded()
            self.collectionViewFeatures.layoutIfNeeded()
            
            // Prevent scrolling during reload
            self.shouldPreventScrolling = true
            
            self.collectionViewFeatures.reloadData()
            self.collectionViewFeaturesTypes.reloadData()
            
            // Restore scroll position after reload
            self.collectionViewFeatures.contentOffset = self.lastContentOffset
            
            // Select appropriate item in features collection view without scrolling
            if index == 0 { // Font
                let fontIndexPath = IndexPath(item: self.selectedFontIndex, section: 0)
                self.collectionViewFeatures.selectItem(at: fontIndexPath, animated: false, scrollPosition: [])
            } else if index == 2 { // Text Color
                let colorIndexPath = IndexPath(item: self.selectedColorIndex, section: 0)
                self.collectionViewFeatures.selectItem(at: colorIndexPath, animated: false, scrollPosition: [])
            } else if index == 4 { // Sticker
                let stickerIndexPath = IndexPath(item: self.selectedStickerIndex, section: 0)
                self.collectionViewFeatures.selectItem(at: stickerIndexPath, animated: false, scrollPosition: [])
            }
            
            // Reset scroll prevention after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldPreventScrolling = false
            }
        }
    }
    private func updateCurrentTextAppearance() {
        guard let textSticker = currentSticker as? VCLabelSticker else { return }
        
        textSticker.textColor = selectedColor
        
        // PRESERVE THE CURRENT FONT SIZE - don't reset to default
        let currentSize = textSticker.textField.font?.pointSize ?? currentFontSize
        
        if let font = UIFont(name: selectedFont, size: currentSize) {
            textSticker.textField.font = font
        }
        
        // Update text alignment
        textSticker.textField.textAlignment = textAlignment
        
        // Update font with style - PRESERVE SIZE
        var fontDescriptor = UIFontDescriptor(name: selectedFont, size: currentSize)
        var traits = UIFontDescriptor.SymbolicTraits()
        
        if isBold {
            traits.insert(.traitBold)
        }
        if isItalic {
            traits.insert(.traitItalic)
        }
        
        if !traits.isEmpty {
            fontDescriptor = fontDescriptor.withSymbolicTraits(traits) ?? fontDescriptor
        }
        
        let updatedFont = UIFont(descriptor: fontDescriptor, size: currentSize)
        
        // Create attributed string with underline attribute
        let currentText = textSticker.textField.text ?? "Double tap to edit"
        let attributedString = NSMutableAttributedString(string: currentText)
        
        // Apply font and color
        let range = NSRange(location: 0, length: attributedString.length)
        
        // Font attributes - USE CURRENT SIZE
        attributedString.addAttribute(.font, value: updatedFont, range: range)
        attributedString.addAttribute(.foregroundColor, value: selectedColor, range: range)
        
        // Underline attribute
        if isUnderline {
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            attributedString.addAttribute(.underlineColor, value: selectedColor, range: range)
        } else {
            attributedString.removeAttribute(.underlineStyle, range: range)
            attributedString.removeAttribute(.underlineColor, range: range)
        }
        
        // Apply the attributed string to the text field
        textSticker.textField.attributedText = attributedString
        
        // Update shadow
        textSticker.shadowEnable = shadowOffset != CGSize.zero || shadowBlur > 0
        
        // Update currentFontSize to match what we just set
        currentFontSize = currentSize
    }
    
    // Add this method to handle when user manually resizes the text view
    private func updateFontSizeForCurrentSticker() {
        guard let textSticker = currentSticker as? VCLabelSticker,
              let currentFont = textSticker.textField.font else { return }
        
        // Update currentFontSize to match the sticker's current size
        currentFontSize = currentFont.pointSize
    }
    
    // MARK: - Color Picker Methods
    private func openColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = selectedColor
        colorPicker.title = "Choose Text Color".localized(LocalizationService.shared.language)
        present(colorPicker, animated: true)
    }
    
    // MARK: - Gradient Border Methods
    

    private func removeGradientBorder(from view: UIView) {
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })
    }
    
    private func createFinalImage() -> UIImage? {
        guard let originalImage = originalImage else { return nil }
        
        // Hide all sticker controls before capturing
        hideAllStickerControls()
        
        defer {
            // Restore sticker controls after capturing
            restoreAllStickerControls()
        }
        
        // Method 1: High-quality rendering using the original image as base
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        
        return renderer.image { context in
            // Set high quality interpolation
            context.cgContext.interpolationQuality = .high
            context.cgContext.setAllowsAntialiasing(true)
            context.cgContext.setShouldAntialias(true)
            
            // Draw original image
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
            
            // Get the actual frame of the image within imageView (for aspect fit)
            let imageViewBounds = imageView.bounds
            let imageSize = originalImage.size
            
            // Calculate the actual displayed rect of the image within imageView
            let imageRect: CGRect
            if imageSize.width / imageSize.height > imageViewBounds.width / imageViewBounds.height {
                let height = imageViewBounds.width * imageSize.height / imageSize.width
                imageRect = CGRect(x: 0,
                                 y: (imageViewBounds.height - height) / 2,
                                 width: imageViewBounds.width,
                                 height: height)
            } else {
                let width = imageViewBounds.height * imageSize.width / imageSize.height
                imageRect = CGRect(x: (imageViewBounds.width - width) / 2,
                                 y: 0,
                                 width: width,
                                 height: imageViewBounds.height)
            }
            
            // Calculate scale factor from screen coordinates to original image coordinates
            let scaleX = originalImage.size.width / imageRect.width
            let scaleY = originalImage.size.height / imageRect.height
            
            // Draw all stickers
            for subview in imageView.subviews {
                if let sticker = subview as? VCBaseSticker {
                    // Convert sticker frame from imageView coordinates to original image coordinates
                    let stickerFrame = sticker.frame
                    
                    // Adjust for the image's position within imageView
                    let adjustedX = (stickerFrame.origin.x - imageRect.origin.x) * scaleX
                    let adjustedY = (stickerFrame.origin.y - imageRect.origin.y) * scaleY
                    let adjustedWidth = stickerFrame.width * scaleX
                    let adjustedHeight = stickerFrame.height * scaleY
                    
                    let transformedRect = CGRect(
                        x: adjustedX,
                        y: adjustedY,
                        width: adjustedWidth,
                        height: adjustedHeight
                    )
                    
                    // Save graphics state for transformation
                    context.cgContext.saveGState()
                    
                    // Apply the same rotation as the sticker
                    let center = CGPoint(x: transformedRect.midX, y: transformedRect.midY)
                    context.cgContext.translateBy(x: center.x, y: center.y)
                    context.cgContext.rotate(by: sticker.cAngle)
                    context.cgContext.translateBy(x: -center.x, y: -center.y)
                    
                    if let textSticker = sticker as? VCLabelSticker,
                       let text = textSticker.text, !text.isEmpty {
                        // Scale font size appropriately
                        let originalFontSize = (textSticker.textField.font?.pointSize ?? 30) * scaleX
                        let font = UIFont(name: textSticker.textField.font?.fontName ?? "ArialMT",
                                        size: originalFontSize) ?? UIFont.systemFont(ofSize: originalFontSize)
                        
                        let textColor = textSticker.textField.textColor ?? .black
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = textSticker.textField.textAlignment
                        
                        var attributes: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: textColor,
                            .paragraphStyle: paragraphStyle
                        ]
                        
                        // Scale shadow appropriately
                        if textSticker.shadowEnable {
                            let shadow = NSShadow()
                            shadow.shadowColor = UIColor.black
                            shadow.shadowOffset = CGSize(width: 0, height: 2 * scaleX)
                            shadow.shadowBlurRadius = 4 * scaleX
                            attributes[.shadow] = shadow
                        }
                        
                        let attributedString = NSAttributedString(string: text, attributes: attributes)
                        attributedString.draw(in: transformedRect)
                        
                    } else if let imageSticker = sticker as? VCImageSticker,
                              let image = imageSticker.imageView.image {
                        // Draw image sticker
                        image.draw(in: transformedRect)
                    }
                    
                    // Restore graphics state
                    context.cgContext.restoreGState()
                }
            }
        }
    }
    
    private func hideAllStickerControls() {
        for subview in imageView.subviews {
            if let sticker = subview as? VCBaseSticker {
                sticker.closeBtn.isHidden = true
                sticker.resizeBtn.isHidden = true
                sticker.border.removeFromSuperlayer()
            }
        }
    }
    
    private func restoreAllStickerControls() {
        for subview in imageView.subviews {
            if let sticker = subview as? VCBaseSticker {
                if sticker == currentSticker && sticker.isEditing {
                    sticker.closeBtn.isHidden = !sticker.closeBtnEnable
                    sticker.resizeBtn.isHidden = !sticker.resizeBtnEnable
                    sticker.contentView.layer.addSublayer(sticker.border)
                }
            }
        }
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension AddTextPhotoVC: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        selectedColor = color
        updateCurrentTextAppearance()
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension AddTextPhotoVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionViewFeaturesTypes {
            return featureTypes.count
        } else {
            switch selectedFeatureIndex {
            case 0: return fonts.count
            case 2: return colors.count + 1 // +1 for color picker
            case 4: return stickers.count
            default: return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == collectionViewFeaturesTypes {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontStyleCell", for: indexPath) as! FontStyleCell
            let feature = featureTypes[indexPath.item]
            
            cell.featureNameLabel.text = feature.0.localized(LocalizationService.shared.language)
            cell.featureNameLabel.isHidden = false
            
            let isSelected = indexPath.item == selectedFeatureIndex
            let imageName = isSelected ? feature.2 : feature.1
            
            if let image = UIImage(named: imageName) {
                cell.featureStyleButton.setImage(image, for: .normal)
            }
            
            cell.featureStyleButton.layer.cornerRadius = cell.featureStyleButton.frame.height / 2
            cell.featureStyleButton.clipsToBounds = true
            
            // Remove any existing gradient layers and borders
            cell.featureStyleButton.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            cell.contentView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            
            if isSelected {
                // Create gradient border for selected cell
                cell.applyGradient()
                cell.featureNameLabel.textColor = .white
            } else {
                cell.featureStyleButton.backgroundColor = .clear
                cell.featureNameLabel.textColor = .lightGray
            }
            
            cell.featureButton.tag = indexPath.item
            cell.featureButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.featureButton.addTarget(self, action: #selector(featureButtonTapped(_:)), for: .touchUpInside)
            
            return cell
            
        } else {
            switch selectedFeatureIndex {
            case 0: // Font
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontFeaturesCell", for: indexPath) as! FontFeaturesCell
                
                cell.featureTitleLabel.text = "Hello"
                cell.featureTitleLabel.font = UIFont(name: fonts[indexPath.item], size: 18)
                cell.featureTitleLabel.textColor = .white
                cell.featureTitleLabel.isHidden = false
                
                cell.parentView.isHidden = false
                cell.parentView.layer.cornerRadius = 8
                cell.parentView.clipsToBounds = true
                cell.parentView.backgroundColor = #colorLiteral(red: 0.06042201072, green: 0.06042201072, blue: 0.06042201072, alpha: 1)
                cell.parentView.layer.borderColor = #colorLiteral(red: 0.2145400047, green: 0.2145400047, blue: 0.2145400047, alpha: 1)
                cell.parentView.layer.borderWidth = 1
                
                cell.stickerImageView.isHidden = true
                
                // Apply gradient border if selected
                if indexPath.item == selectedFontIndex {
                    cell.addGradientBorder(to: cell.parentView, cornerRadius: 8)
                } else {
                    removeGradientBorder(from: cell.parentView)
                }
                
                cell.contentView.gestureRecognizers?.forEach { cell.contentView.removeGestureRecognizer($0) }
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(fontCellTapped(_:)))
                cell.contentView.addGestureRecognizer(tapGesture)
                cell.contentView.tag = indexPath.item
                
                return cell
                
            case 2: // Text Color
                if indexPath.item == 0 {
                    // Color Picker Cell
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontFeaturesCell", for: indexPath) as! FontFeaturesCell
                    
                    cell.featureTitleLabel.text = ""
                    cell.featureTitleLabel.isHidden = true
                    cell.parentView.isHidden = false
                    cell.parentView.layer.cornerRadius = 8
                    cell.parentView.clipsToBounds = true
                    cell.parentView.backgroundColor = UIColor.darkGray
                    
                    cell.stickerImageView.isHidden = false
                    cell.stickerImageView.image = UIImage(named: "picker")
                    cell.stickerImageView.contentMode = .scaleAspectFit
                    cell.stickerImageView.tintColor = .white
                    
                    // Apply gradient border if selected
                    if indexPath.item == selectedColorIndex {
                        cell.addGradientBorder(to: cell.parentView, cornerRadius: 8)
                    } else {
                        removeGradientBorder(from: cell.parentView)
                    }
                    
                    cell.contentView.gestureRecognizers?.forEach { cell.contentView.removeGestureRecognizer($0) }
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(colorPickerCellTapped(_:)))
                    cell.contentView.addGestureRecognizer(tapGesture)
                    cell.contentView.tag = indexPath.item
                    
                    return cell
                } else {
                    // Regular Color Cell
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontTextColorCell", for: indexPath) as! FontTextColorCell
                    let colorIndex = indexPath.item - 1 // Adjust for color picker cell
                    cell.colorView.backgroundColor = colors[colorIndex]
                    cell.colorView.layer.cornerRadius = cell.colorView.frame.width / 2
                    cell.colorView.layer.borderWidth = 0.5
                    cell.colorView.layer.borderColor = UIColor.white.cgColor
                    
                    // Apply gradient border if selected
                    if indexPath.item == selectedColorIndex {
                        cell.addGradientBorder(to: cell.contentView, cornerRadius: cell.contentView.frame.width / 2)
                    } else {
                        removeGradientBorder(from: cell.contentView)
                    }
                    
                    cell.contentView.gestureRecognizers?.forEach { cell.contentView.removeGestureRecognizer($0) }
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(colorCellTapped(_:)))
                    cell.contentView.addGestureRecognizer(tapGesture)
                    cell.contentView.tag = indexPath.item
                    
                    return cell
                }
                
            case 4: // Sticker
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontFeaturesCell", for: indexPath) as! FontFeaturesCell

                // Hide non-sticker items
                cell.featureTitleLabel.isHidden = true
                cell.parentView.isHidden = false
                cell.parentView.layer.cornerRadius = 8
                cell.parentView.clipsToBounds = true
                cell.parentView.backgroundColor = UIColor.darkGray

                // Show sticker image
                cell.stickerImageView.isHidden = false
                cell.stickerImageView.contentMode = .scaleAspectFit
                cell.stickerImageView.clipsToBounds = true

                let stickerName = stickers[indexPath.item]
                if let image = UIImage(named: stickerName) {
                    cell.stickerImageView.image = image
                    cell.stickerImageView.backgroundColor = .clear
                } else {
                    print("Sticker not found → \(stickerName)")
                    cell.stickerImageView.image = nil
                }

                // Apply gradient border if selected
                if indexPath.item == selectedStickerIndex {
                    cell.addGradientBorder(to: cell.parentView, cornerRadius: 8)
                } else {
                    removeGradientBorder(from: cell.parentView)
                }

                // Remove gestures → add new tap gesture
                cell.contentView.gestureRecognizers?.forEach { cell.contentView.removeGestureRecognizer($0) }
                let tap = UITapGestureRecognizer(target: self, action: #selector(stickerCellTapped(_:)))
                cell.contentView.addGestureRecognizer(tap)
                cell.contentView.tag = indexPath.item
                return cell
                
            default:
                return UICollectionViewCell()
            }
        }
    }
    
    @objc private func featureButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        handleFeatureSelection(at: index)
    }
    
    @objc private func fontCellTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        selectedFontIndex = index
        selectedFont = fonts[index]
        updateCurrentTextAppearance()
        
        // Save current scroll position
        lastContentOffset = collectionViewFeatures.contentOffset
        
        // Prevent scrolling during reload
        shouldPreventScrolling = true
        collectionViewFeatures.reloadData()
        
        // Restore scroll position
        collectionViewFeatures.contentOffset = lastContentOffset
        
        // Reset scroll prevention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldPreventScrolling = false
        }
    }
    
    @objc private func colorCellTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        selectedColorIndex = index
        let colorIndex = index - 1 // Adjust for color picker cell
        selectedColor = colors[colorIndex]
        updateCurrentTextAppearance()
        
        // Save current scroll position
        lastContentOffset = collectionViewFeatures.contentOffset
        
        // Prevent scrolling during reload
        shouldPreventScrolling = true
        collectionViewFeatures.reloadData()
        
        // Restore scroll position
        collectionViewFeatures.contentOffset = lastContentOffset
        
        // Reset scroll prevention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldPreventScrolling = false
        }
    }
    
    @objc private func colorPickerCellTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        selectedColorIndex = index
        openColorPicker()
        
        // Save current scroll position
        lastContentOffset = collectionViewFeatures.contentOffset
        
        // Prevent scrolling during reload
        shouldPreventScrolling = true
        collectionViewFeatures.reloadData()
        
        // Restore scroll position
        collectionViewFeatures.contentOffset = lastContentOffset
        
        // Reset scroll prevention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldPreventScrolling = false
        }
    }
    
    @objc private func stickerCellTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        selectedStickerIndex = index
        let stickerName = stickers[index]
        
        // Create sticker at center of image view
        let center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        createImageSticker(with: stickerName, at: center)
        
        // Save current scroll position
        lastContentOffset = collectionViewFeatures.contentOffset
        
        // Prevent scrolling during reload
        shouldPreventScrolling = true
        collectionViewFeatures.reloadData()
        
        // Restore scroll position
        collectionViewFeatures.contentOffset = lastContentOffset
        
        // Reset scroll prevention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldPreventScrolling = false
        }
    }
    
    
}
// MARK: - UIScrollViewDelegate
extension AddTextPhotoVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Prevent scrolling if flag is set
        if shouldPreventScrolling && scrollView == collectionViewFeatures {
            scrollView.contentOffset = lastContentOffset
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Save the current offset when user starts dragging
        if scrollView == collectionViewFeatures {
            lastContentOffset = scrollView.contentOffset
        }
    }
}
// MARK: - Button Actions
extension AddTextPhotoVC {
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addTextButtonAction(_ sender: UIButton) {
        // Create new text sticker at center of image view when button is tapped
        let center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        
        // Reset to default font size when creating new sticker
        currentFontSize = defaultFontSize
        
        // Create new text sticker
        createNewTextSticker(at: center)
    }
    
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Error".localized(LocalizationService.shared.language), message: "Failed to save image: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Success".localized(LocalizationService.shared.language), message: "Image saved to photos library".localized(LocalizationService.shared.language), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
    
    @IBAction func italicFontButtonAction(_ sender: Any) {
        isItalic = !isItalic
        updateCurrentTextAppearance()
    }
    
    @IBAction func boldFontButtonAction(_ sender: Any) {
        isBold = !isBold
        updateCurrentTextAppearance()
    }
    
    @IBAction func underlineFontButtonAction(_ sender: Any) {
        isUnderline = !isUnderline
        updateCurrentTextAppearance()
    }
    
    @IBAction func leftAlignFontButtonAction(_ sender: Any) {
        textAlignment = .left
        updateCurrentTextAppearance()
    }
    
    @IBAction func centerAlignFontButtonAction(_ sender: Any) {
        textAlignment = .center
        updateCurrentTextAppearance()
    }
    
    @IBAction func rightAlignFontButtonAction(_ sender: Any) {
        textAlignment = .right
        updateCurrentTextAppearance()
    }
    
    @IBAction func topBottomShadowSliderChanged(_ sender: UISlider) {
        shadowOffset.height = CGFloat(sender.value)
        updateCurrentTextAppearance()
    }
    
    @IBAction func leftRightShadowSliderChanged(_ sender: UISlider) {
        shadowOffset.width = CGFloat(sender.value)
        updateCurrentTextAppearance()
    }
    
    @IBAction func NextButtonAction(_ sender: UIButton) {
        // Finish any ongoing editing before saving
        currentSticker?.finishEditing()
        currentSticker = nil
        
        if let finalImage = createFinalImage() {
            // Navigate to SavePhotoVC and pass the final image
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
            if let savePhotoVC = storyboard.instantiateViewController(withIdentifier: "SavePhotoVC") as? SavePhotoVC {
                savePhotoVC.croppedImage = finalImage
                self.navigationController?.pushViewController(savePhotoVC, animated: true)
            }
        }
    }
}
