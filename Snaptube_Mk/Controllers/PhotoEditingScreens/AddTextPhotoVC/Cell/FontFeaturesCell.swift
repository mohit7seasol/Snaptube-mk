//
//  FontFeaturesCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit

class FontFeaturesCell: UICollectionViewCell {

    @IBOutlet weak var featureTitleLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var stickerImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        parentView.layoutIfNeeded()
        parentView.layoutSubviews()
        
        // Re-apply gradient border if needed when layout changes
        if let gradientLayer = parentView.layer.sublayers?.first(where: { $0.name == "gradientBorder" }) as? CAGradientLayer {
            gradientLayer.frame = parentView.bounds
            if let maskLayer = gradientLayer.mask as? CAShapeLayer {
                maskLayer.path = UIBezierPath(
                    roundedRect: parentView.bounds.insetBy(dx: 1, dy: 1),
                    cornerRadius: parentView.layer.cornerRadius
                ).cgPath
                maskLayer.frame = parentView.bounds
            }
        }
    }
    
    func addGradientBorder(to view: UIView, cornerRadius: CGFloat = 8) {
        // Remove only previous gradient borders, not other layers
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })
        
        // Ensure we have a valid frame
        guard view.bounds.width > 0 && view.bounds.height > 0 else {
            // If frame isn't ready, schedule to try again
            DispatchQueue.main.async { [weak self] in
                self?.addGradientBorder(to: view, cornerRadius: cornerRadius)
            }
            return
        }

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "gradientBorder"
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "#BDA9FF").cgColor,
            UIColor(hex: "#FF524E").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = cornerRadius

        // Mask to make it appear like a border
        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = 2
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.path = UIBezierPath(
            roundedRect: view.bounds.insetBy(dx: 1, dy: 1),
            cornerRadius: cornerRadius
        ).cgPath
        maskLayer.frame = view.bounds

        gradientLayer.mask = maskLayer
        view.layer.addSublayer(gradientLayer)
    }

}
