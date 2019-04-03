//
//  PhotoBrowserViewController.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 03/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import UIKit
import SDWebImage

protocol PhotoBrowserInterfaceProtocol {
    /**
     This method sets a preview image, view controller title and a url string to local variable which is used at the time viewDidLoad is called to show image in view
     */
    func setImageUrl(urlString: String, previewImage: UIImage?, title:String)
}

class PhotoBrowserViewController: UIViewController, PhotoBrowserInterfaceProtocol  {
    
    @IBOutlet weak private var imageView: UIImageView!
    private var url : URL?
    private var previewImg : UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        let placeholder = previewImg != nil ? previewImg : UIImage(named: Constants.placeholderImage)
        imageView.sd_setImage(with: url, placeholderImage: placeholder)
    }
    
    func setImageUrl(urlString: String, previewImage: UIImage?, title:String) {
        self.title = title
        url = URL(string: urlString)
        previewImg = previewImage
    }
}
