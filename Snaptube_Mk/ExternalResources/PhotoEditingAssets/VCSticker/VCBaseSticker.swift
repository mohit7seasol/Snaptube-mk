import UIKit

enum VCBorderStyle {
    case dotted
    case solid
    case none
}

let kMinFrameWidth: CGFloat  = 35
let kMinFrameHeight: CGFloat = 35

open class VCBaseSticker: UIView {
    @objc public var onBeginEditing: (() -> Void)?
    @objc public var onClose: (() -> Void)?
    @objc public var onRotate: (() -> Void)? // Add rotation callback
    
    var closeImage  = VCAsserts.closeImage
    var resizeImage = VCAsserts.resizeImage
    var rotateImage = VCAsserts.rotateImage // Add rotation image
    
    @objc public var borderColor = UIColor.cyan {
        didSet {
            border.strokeColor  = borderColor.cgColor
            closeBtn.tintColor  = borderColor.highlightColor()
            resizeBtn.tintColor = borderColor.highlightColor()
            rotateBtn.tintColor = borderColor.highlightColor() // Add rotation button color
            closeBtn.backgroundColor  = borderColor
            resizeBtn.backgroundColor = borderColor
            rotateBtn.backgroundColor = borderColor // Add rotation button background
        }
    }
    var borderStyle = VCBorderStyle.solid
    var padding: CGFloat = 8

    @objc public var closeBtnEnable: Bool  = true
    @objc public var resizeBtnEnable: Bool = true
    @objc public var rotateBtnEnable: Bool = true // Add rotation button enable
    @objc public var restrictionEnable: Bool = false

    public var initState = -1
    public var isEditing: Bool = false

    private var lastAngle: CGFloat!
    private var lastDistance: CGFloat!
    
    lazy var border: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        switch self.borderStyle {
        case .none:
            layer.strokeColor = nil
        case .dotted:
            layer.lineDashPattern = [4, 3]
            fallthrough
        case .solid:
            fallthrough
        default:
            layer.strokeColor = borderColor.cgColor
        }
        return layer
    }()
    
    lazy var closeBtn: UIImageView = {
        let button = self.getItemImageView(self.closeImage)
        return button
    }()
    
    lazy var resizeBtn: UIImageView = {
        let button = self.getItemImageView(self.resizeImage)
        return button
    }()
    
    // ADD ROTATION BUTTON
    lazy var rotateBtn: UIImageView = {
        let button = self.getItemImageView(self.rotateImage)
        return button
    }()
    
    lazy public var contentView = UIView()

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if initState == -1 {
            initState = 0
            removeAutoLayout()
        } else if initState == 0 {
            initState = 1
            customInit()
        }
        
        border.path  = UIBezierPath(rect: contentView.bounds).cgPath
        border.frame = contentView.bounds
    }

    private func removeAutoLayout() {
        for con in self.constraints {
            self.removeConstraint(con)
        }
        
        if let superConstraints = self.superview?.constraints {
            for con in superConstraints {
                if con.firstItem?.isEqual(self) ?? false {
                    self.superview?.removeConstraint(con)
                }
            }
        }
        
        self.translatesAutoresizingMaskIntoConstraints = true
        setNeedsLayout()
        layoutIfNeeded()
    }

    open func customInit() {
        frame.size.width = max(frame.width, kMinFrameWidth)
        frame.size.height = max(frame.height, kMinFrameHeight)
        
        setupSubViews()
        setupGestures()
        
        self.beginEditing()
    }

    private func setupSubViews() {
        self.addSubview(contentView)
        self.contentView.edgesToSuperview(self.padding)
        
        if closeBtnEnable {
            self.addSubview(closeBtn)
            self.closeBtn.topLeftToSuperview(0, size: self.padding*2)
        }
        
        // ADD ROTATION BUTTON - TOP RIGHT
        if rotateBtnEnable {
            self.addSubview(rotateBtn)
            self.rotateBtn.topRightToSuperview(0, size: self.padding*2)
        }
        
        if resizeBtnEnable {
            self.addSubview(resizeBtn)
            self.resizeBtn.bottomRightToSuperview(0, size: self.padding*2)
        }
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gesture:)))
        self.addGestureRecognizer(panGesture)
        
        let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResize(gesture:)))
        self.resizeBtn.addGestureRecognizer(resizeGesture)
        
        // ADD ROTATION GESTURE
        let rotateGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotate(gesture:)))
        self.rotateBtn.addGestureRecognizer(rotateGesture)
        
        let bodyTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapBody))
        self.addGestureRecognizer(bodyTapGesture)
        
        let closeTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapClose))
        self.closeBtn.addGestureRecognizer(closeTapGesture)
        
        // ADD ROTATION TAP GESTURE
        let rotateTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapRotate))
        self.rotateBtn.addGestureRecognizer(rotateTapGesture)
    }

    private func getItemImageView(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.padding*2, height: self.padding*2))
        
        imageView.image = image
        imageView.tintColor = .black
        imageView.backgroundColor = self.borderColor
        imageView.layer.cornerRadius = self.padding
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }

    @objc open func beginEditing() {
        isEditing = true
        
        closeBtn.isHidden  = !closeBtnEnable
        resizeBtn.isHidden = !resizeBtnEnable
        rotateBtn.isHidden = !rotateBtnEnable // Show rotation button
        contentView.layer.addSublayer(border)
        onBeginEditing?()
    }

    @objc open func finishEditing() {
        isEditing = false
        
        closeBtn.isHidden  = true
        resizeBtn.isHidden = true
        rotateBtn.isHidden = true // Hide rotation button
        border.removeFromSuperlayer()
    }
}

// MARK: - Gesture Handler Methods
extension VCBaseSticker {
    
    /// Drag gesture for moving the sticker
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        if !isEditing {
            beginEditing()
        }
        
        // 1.获取手势在视图上的平移增量
        let translation = gesture.translation(in: gesture.view!.superview)
        // 2.设置中心点
        let center = gesture.view!.center
        let newCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        // 判断是否超出边缘
        if restrictionEnable {
            if (newCenter.x + self.frame.width*0.5 <= self.superview!.frame.width)
                && (newCenter.x - self.frame.width*0.5 >= 0) {
                gesture.view!.center.x = newCenter.x
            }
            
            if (newCenter.y + self.frame.height*0.5 <= self.superview!.frame.height)
                && (newCenter.y - self.frame.height*0.5 >= 0) {
                gesture.view!.center.y = newCenter.y
            }
        } else {
            gesture.view!.center = newCenter
        }
        
        // 3.将上一次的平移增量置为0
        gesture.setTranslation(CGPoint(x: 0.0, y: 0.0), in: gesture.view)
    }
    
    /// Resize gesture handler
    @objc func handleResize(gesture: UIPanGestureRecognizer) {
        // 以当前父页面为计算参考
        let location = gesture.location(in: self.superview)
        let center = self.center
        
        let distance = VCStickerUtils.getDistance(point1: location, point2: center)
        let angle = atan2(location.y - center.y, location.x - center.x)
        
        
        if gesture.state == .began {
            self.lastAngle = angle
            self.lastDistance = distance
        } else if gesture.state == .changed {
            // 旋转
            let final = angle - self.lastAngle
            self.transform = self.transform.rotated(by: final)
            self.lastAngle = angle
            
            // 缩放
            let scale = distance / self.lastDistance
            
            let newWidth  = self.bounds.width * scale
            let newHeight = self.bounds.height * scale
            if (newWidth >= kMinFrameWidth) && (newHeight >= kMinFrameHeight) {
                // 修改当前view的真实大小（不使用transform）
                // self.transform = self.transform.scaledBy(x: scale, y: scale)
                self.bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
                // 修改文字大小
                //                adjustTextFieldFont()
                
                self.lastDistance = distance
            }
        }
    }
    
    /// Rotation gesture handler for continuous rotation
    @objc func handleRotate(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.superview)
        let center = self.center
        
        let angle = atan2(location.y - center.y, location.x - center.x)
        
        if gesture.state == .began {
            self.lastAngle = angle
        } else if gesture.state == .changed {
            // Calculate rotation delta
            let deltaAngle = angle - self.lastAngle
            
            // Apply rotation transform
            self.transform = self.transform.rotated(by: deltaAngle)
            self.lastAngle = angle
            
            // Call rotation callback
            self.onRotate?()
        } else if gesture.state == .ended {
            // Optional: Snap to nearest 45 degrees when gesture ends
            snapToNearestAngle()
        }
    }
    
    /// Snap rotation to nearest 45 degrees
    private func snapToNearestAngle() {
        let currentAngle = self.cAngle
        let snapAngle = round(currentAngle / (.pi / 4)) * (.pi / 4) // Snap to nearest 45 degrees
        
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(rotationAngle: snapAngle)
        }
    }
    
    /// Rotation button tap handler
    @objc func handleTapRotate() {
        // Rotate 45 degrees on each tap
        let rotationAngle: CGFloat = .pi / 4 // 45 degrees
        UIView.animate(withDuration: 0.2) {
            self.transform = self.transform.rotated(by: rotationAngle)
        }
        
        // Call rotation callback
        self.onRotate?()
    }
    
    /// Close button tap handler
    @objc func handleTapClose() {
        self.onClose?()
        self.removeFromSuperview()
    }
    
    /// Body tap handler
    @objc func handleTapBody() {
        isEditing ? finishEditing() : beginEditing()
    }
}

// ADD TOP RIGHT CONSTRAINT METHOD
extension UIView {
    func topRightToSuperview(_ padding: CGFloat, size: CGFloat) {
        paddingToSuperView(top: padding, right: padding, width: size, height: size)
    }
}
