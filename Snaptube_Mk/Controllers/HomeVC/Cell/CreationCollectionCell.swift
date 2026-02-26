//
//  CreationCollectionCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 24/11/25.
//

import UIKit

class CreationCollectionCell: UICollectionViewCell {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        durationLabel.clipsToBounds = true
    }

}
