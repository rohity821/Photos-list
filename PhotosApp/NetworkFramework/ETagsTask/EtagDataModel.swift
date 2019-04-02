//
//  EtagDataModel.swift
//  AirtelMovies
//
//  Created by a15tnkbm on 06/09/17.
//  Copyright © 2017 Accedo. All rights reserved.
//

import Foundation

struct EtagDataModel : Codable {
    let timeStamp : Date
    let url : String
    let expiryDuration : Double
    let hashID : String
    let etag : String?
    
    private enum CodingKeys : String, CodingKey {
        case url
        case expiryDuration
        case hashID
        case etag
    }
    
    init(timeStamp:Date, url:String, expiryDuration:Double, hashID:String, etag:String?) {
        self.timeStamp = timeStamp
        self.url = url
        self.expiryDuration = expiryDuration
        self.hashID = hashID
        self.etag = etag
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        expiryDuration = try container.decode(Double.self, forKey: .expiryDuration)
        hashID = try container.decode(String.self, forKey: .hashID)
        etag = try container.decode(String.self, forKey: .etag)
        timeStamp = Date.distantPast
    }
}

