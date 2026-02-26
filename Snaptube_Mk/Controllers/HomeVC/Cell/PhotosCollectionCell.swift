//
//  PhotosCollectionCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//

import UIKit

class PhotosCollectionCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var favouriteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        durationLabel.isHidden = true
        // Reset favorite button to default unselected state
        favouriteButton.setImage(UIImage(named: "favourite_unselected"), for: .normal)
    }
    
    func setupCell() {
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.contentMode = .scaleAspectFill
        
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        durationLabel.textColor = .white
        durationLabel.layer.cornerRadius = 4
        durationLabel.clipsToBounds = true
        durationLabel.isHidden = true
        
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
    }
}
