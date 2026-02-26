//
//  LanguageCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//

import UIKit

class LanguageCell: UICollectionViewCell {

    @IBOutlet weak var countryIconImageView: UIImageView!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    
    private let gradientBorderLayer = CAGradientLayer()
    private let borderWidth: CGFloat = 2.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientFrame()
    }
    
    private func updateGradientFrame() {
        gradientBorderLayer.frame = parentView.bounds
        
        if let maskLayer = gradientBorderLayer.mask as? CAShapeLayer {
            maskLayer.frame = parentView.bounds
            maskLayer.path = UIBezierPath(
                roundedRect: parentView.bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2),
                cornerRadius: 8
            ).cgPath
        }
    }
    
    private func setupCell() {
        parentView.layer.cornerRadius = 8
        parentView.layer.masksToBounds = true
        parentView.backgroundColor = UIColor(hex: "#111111")
        
        gradientBorderLayer.colors = [
            UIColor(hex: "#BDA9FF").cgColor,
            UIColor(hex: "#FF524E").cgColor
        ]
        gradientBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientBorderLayer.cornerRadius = 8
        
        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = borderWidth
        maskLayer.fillColor = nil
        maskLayer.strokeColor = UIColor.white.cgColor
        
        gradientBorderLayer.mask = maskLayer
        
        // FIXED → Add to parentView instead of cell
        parentView.layer.addSublayer(gradientBorderLayer)
        
        setDeselectedState()
    }
    
    func setSelectedState() {
        gradientBorderLayer.isHidden = false
        countryNameLabel.textColor = .white
    }
    
    func setDeselectedState() {
        gradientBorderLayer.isHidden = true
        countryNameLabel.textColor = .lightGray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setDeselectedState()
    }
}
