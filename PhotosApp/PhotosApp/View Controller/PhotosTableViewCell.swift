//
//  PhotosTableViewCell.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import UIKit
import SDWebImage

class PhotosTableViewCell: UITableViewCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var photoImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCell(withTitle title:String, andThumbUrl thumbUrl:String) {
        self.titleLabel.text = title
        if let url = URL(string: thumbUrl) {
            photoImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
    }

}
