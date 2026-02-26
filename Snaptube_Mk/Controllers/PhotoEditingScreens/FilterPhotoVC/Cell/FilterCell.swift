//
//  FilterCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 19/11/25.
//

import UIKit

class FilterCell: UICollectionViewCell {

    @IBOutlet weak var filterImageView: UIImageView!
    @IBOutlet weak var selectedEffectIconImageView: UIImageView!
    @IBOutlet weak var parentView: UIView!

    private let gradientBorderLayer = CAGradientLayer()
    private let borderWidth: CGFloat = 2.0    // visible border size
    private let cornerRadius: CGFloat = 12.0  // cell corner radius
    @IBOutlet weak var subView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGradientBorder()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        parentView.layer.cornerRadius = cornerRadius
        parentView.clipsToBounds = true
        
        subView.layer.cornerRadius = cornerRadius
        subView.clipsToBounds = true

        // Update gradient layer frame + mask
        updateGradientFrame()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gradientBorderLayer.isHidden = true
        selectedEffectIconImageView.isHidden = true
        parentView.backgroundColor = .clear
        filterImageView.image = nil
    }

    // MARK: - UI Setup
    private func setupUI() {
        // parentView shows background but doesn't clip so gradient can show
        parentView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        parentView.layer.cornerRadius = cornerRadius
        parentView.clipsToBounds = false // important

        // filter image view smaller than parentView (we set frame in layoutSubviews)
        filterImageView.contentMode = .scaleAspectFill
        filterImageView.clipsToBounds = true
        filterImageView.layer.masksToBounds = true

        selectedEffectIconImageView.isHidden = true
        selectedEffectIconImageView.tintColor = .white
    }

    // MARK: - Gradient Border
    private func setupGradientBorder() {
        // Prevent duplicates
        parentView.layer.sublayers?.removeAll(where: { $0.name == "gradientBorder" })

        gradientBorderLayer.name = "gradientBorder"
        gradientBorderLayer.colors = [
            UIColor(red: 0.74, green: 0.66, blue: 1.00, alpha: 1.00).cgColor, // #BDA9FF
            UIColor(red: 1.00, green: 0.32, blue: 0.31, alpha: 1.00).cgColor  // #FF524E
        ]
        gradientBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientBorderLayer.cornerRadius = cornerRadius

        // Insert below imageView so gradient appears under the image
        parentView.layer.insertSublayer(gradientBorderLayer, at: 0)
        gradientBorderLayer.isHidden = true
    }

    private func updateGradientFrame() {
        // Ensure parentView has valid bounds
        guard parentView.bounds.width > 0 && parentView.bounds.height > 0 else { return }

        // Gradient should cover the whole parentView (we'll mask it with a stroke)
        gradientBorderLayer.frame = parentView.bounds

        // Create/Update mask: a stroked rounded rect centered on parentView bounds,
        // so only the stroke area of the gradient is visible.
        let mask = CAShapeLayer()
        let inset = borderWidth / 2.0
        let pathRect = parentView.bounds.insetBy(dx: inset, dy: inset)
        mask.path = UIBezierPath(roundedRect: pathRect, cornerRadius: cornerRadius - inset).cgPath
        mask.lineWidth = borderWidth
        mask.fillColor = UIColor.clear.cgColor
        mask.strokeColor = UIColor.white.cgColor
        mask.frame = parentView.bounds

        gradientBorderLayer.mask = mask
    }

    // MARK: - Configure Cell
    func configure(with name: String, isSelected: Bool) {
        // show/hide gradient
        gradientBorderLayer.isHidden = !isSelected
        selectedEffectIconImageView.isHidden = !isSelected

        if isSelected {
            // Slight background tint for selected state (optional)
            parentView.backgroundColor = UIColor(red: 0.74, green: 0.66, blue: 1.00, alpha: 0.08)
            // Add subtle shadow (optional)
            parentView.layer.shadowColor = UIColor(red: 0.74, green: 0.66, blue: 1.00, alpha: 0.35).cgColor
            parentView.layer.shadowRadius = 6
            parentView.layer.shadowOpacity = 0.25
            parentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        } else {
            parentView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            parentView.layer.shadowOpacity = 0
        }

        // Force an immediate layout update so the gradient mask is correct
        setNeedsLayout()
        layoutIfNeeded()
    }
}
