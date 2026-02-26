import UIKit

public class VCImageSticker: VCBaseSticker {
    @objc public var imageView = UIImageView()
    
    override open func customInit() {
         super.customInit()
         self.contentView.addSubview(imageView)
         imageView.edgesToSuperview(0)
     }
}
