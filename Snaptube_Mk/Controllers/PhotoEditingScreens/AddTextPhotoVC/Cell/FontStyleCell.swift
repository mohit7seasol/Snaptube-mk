//
//  FontStyleCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit

class FontStyleCell: UICollectionViewCell {

    @IBOutlet weak var featureStyleButton: UIButton!
    @IBOutlet weak var featureNameLabel: UILabel!
    @IBOutlet weak var featureButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Re-apply gradient when layout changes
        if let gradientLayers = contentView.layer.sublayers?.filter({ $0 is CAGradientLayer }) {
            gradientLayers.forEach { $0.removeFromSuperlayer() }
        }
    }
    
    func applyGradient() {
        featureStyleButton.layoutIfNeeded()

        // Remove old gradients first
        featureStyleButton.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })

        let gradient = CAGradientLayer()
        gradient.name = "gradientBorder"
        gradient.frame = featureStyleButton.bounds // 👈 Only button frame
        gradient.colors = [
            UIColor(red: 0.74, green: 0.66, blue: 1.0, alpha: 1).cgColor,  // #BDA9FF
            UIColor(red: 1.0, green: 0.32, blue: 0.31, alpha: 1).cgColor   // #FF524E
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        // Create shape layer (border path)
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(
            roundedRect: featureStyleButton.bounds,
            cornerRadius: featureStyleButton.bounds.height / 2
        ).cgPath

        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.black.cgColor

        gradient.mask = shape
        featureStyleButton.layer.addSublayer(gradient)
    }

}
