//
//  HistoryVCCollectionViewCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 25/11/25.
//

import UIKit

class HistoryVCCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var moreOptionsButton: UIButton!
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
