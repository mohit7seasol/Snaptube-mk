//
//  OptionsCellCollectionViewCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//

import UIKit

class OptionsCellCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
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
                cornerRadius: 12
            ).cgPath
        }
    }
    
    private func setupCell() {
        parentView.layer.cornerRadius = 12
        parentView.layer.masksToBounds = true
        parentView.backgroundColor = UIColor(hex: "#111111")
        
        gradientBorderLayer.colors = [
            UIColor(hex: "#BDA9FF").cgColor,
            UIColor(hex: "#FF524E").cgColor
        ]
        gradientBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientBorderLayer.cornerRadius = 12
        
        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = borderWidth
        maskLayer.fillColor = nil
        maskLayer.strokeColor = UIColor.white.cgColor
        
        gradientBorderLayer.mask = maskLayer
        
        // Add to parentView instead of cell
        parentView.layer.addSublayer(gradientBorderLayer)
        
        setDeselectedState()
        
        // Configure other UI elements
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    }
    
    func setSelectedState() {
        gradientBorderLayer.isHidden = false
        titleLabel.textColor = .white
        iconImageView.tintColor = .white
    }
    
    func setDeselectedState() {
        gradientBorderLayer.isHidden = true
        titleLabel.textColor = .lightGray
        iconImageView.tintColor = .lightGray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setDeselectedState()
    }
}
