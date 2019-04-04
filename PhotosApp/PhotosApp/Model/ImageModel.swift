//
//  ImageModel.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 03/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

struct ImageModel : Codable {
    var albumId : Int
    var id : Int
    var title : String
    var url : String
    var thumbnailUrl : String

}
