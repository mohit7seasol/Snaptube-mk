//
//  AlbumCollectionViewCell.swift
//  Snaptube_Mk
//
//  Created by DREAMWORLD on 17/11/25.
//
import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imgView1: UIImageView!
    @IBOutlet weak var imgView2: UIImageView!
    @IBOutlet weak var imgView3: UIImageView!
    @IBOutlet weak var imgView4: UIImageView!
    @IBOutlet weak var totalAlbumImageCountLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var totlaPhotosCountAlbumLabel: UILabel!
    @IBOutlet weak var parentView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageViewsLayout()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetImageViews()
    }
    
    private func setupUI() {
        // Configure image views
        configureImageView(imgView1)
        configureImageView(imgView2)
        configureImageView(imgView3)
        configureImageView(imgView4)
        
        parentView.layer.borderWidth = 0.5
        parentView.backgroundColor = #colorLiteral(red: 0.0659404695, green: 0.0659404695, blue: 0.0659404695, alpha: 1)
        parentView.layer.borderColor = #colorLiteral(red: 0.1000000015, green: 0.1000000015, blue: 0.1000000015, alpha: 1)
        parentView.layer.cornerRadius = 10
        parentView.layer.borderColor = #colorLiteral(red: 0.2372712493, green: 0.2372712493, blue: 0.2372712493, alpha: 1)
        parentView.clipsToBounds = true
    }
    
    private func configureImageView(_ imageView: UIImageView) {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.backgroundColor = .systemGray6
    }
    
    private func updateImageViewsLayout() {
        // Make image views with rounded corners
        let cornerRadius: CGFloat = 8
        imgView1.layer.cornerRadius = cornerRadius
        imgView2.layer.cornerRadius = cornerRadius
        imgView3.layer.cornerRadius = cornerRadius
        imgView4.layer.cornerRadius = cornerRadius
    }
    
    private func resetImageViews() {
        let imageViews = [imgView1, imgView2, imgView3, imgView4]
        imageViews.forEach {
            $0?.image = nil
            $0?.backgroundColor = .systemGray6
        }
    }
    
    // MARK: - Configuration Method
    func configure(with album: Album) {
        // Configure labels
        albumNameLabel.text = album.title
        totlaPhotosCountAlbumLabel.text = "\(album.count) items"
        totalAlbumImageCountLabel.text = "+\(album.count)"
        
        // Set specific colors based on album type
//        applyAlbumTypeStyling(album.type)
    }
    
    private func applyAlbumTypeStyling(_ type: AlbumType) {
        switch type {
        case .camera:
            albumNameLabel.textColor = .label
            totalAlbumImageCountLabel.textColor = .systemBlue
        case .screenshots:
            albumNameLabel.textColor = .systemGreen
            totalAlbumImageCountLabel.textColor = .systemGreen
        case .videos:
            albumNameLabel.textColor = .systemRed
            totalAlbumImageCountLabel.textColor = .systemRed
        case .other:
            albumNameLabel.textColor = .systemGray
            totalAlbumImageCountLabel.textColor = .systemGray
        }
    }
}
