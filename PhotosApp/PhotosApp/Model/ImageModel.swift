//
//  ImageModel.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 03/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

struct ImageModel : Decodable {
    let albumId : Int
    let id : Int
    let title : String
    let url : String
    let thumbnailUrl : String

}
