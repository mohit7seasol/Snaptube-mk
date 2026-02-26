//
//  FontTextColorCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit

class FontTextColorCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func addGradientBorder(to view: UIView, cornerRadius: CGFloat = 8) {

        // Remove only previous gradient borders, not other layers
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })

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
