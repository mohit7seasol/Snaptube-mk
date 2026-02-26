//
//  VideosCollectionCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 21/11/25.
//

import UIKit

class VideosCollectionCell: UICollectionViewCell {

    @IBOutlet weak var videoPreviewImageView: UIImageView!
    @IBOutlet weak var videoNameLabel: UILabel!
    @IBOutlet weak var videoDateTimeLabel: UILabel! // Changed from UIImageView to UILabel
    @IBOutlet weak var videoSelectionView: UIView!
    @IBOutlet weak var selectedVideoCountLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var favouriteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset favorite button to default unselected state
        favouriteButton.setImage(UIImage(named: "favourite_unselected"), for: .normal)
    }
    
    private func setupUI() {
        selectedVideoCountLabel.textColor = .white
        selectedVideoCountLabel.font = UIFont.boldSystemFont(ofSize: 14)
        durationLabel.clipsToBounds = true
    }

}
