//
//  APIResponseCache.swift
//  AirtelMovies
//
//  Created by a15tnkbm on 06/09/17.
//  Copyright © 2017 Accedo. All rights reserved.
//

import Foundation

class APIResponseCacheManager {

    private struct Constants {
        struct keys {
            static let cachedPath = "cache"
        }
        static let cacheExtension = ".response"
        static let writerQueue = DispatchQueue(label: "com.rohit.APIResponseCacheManager.common.write")
    }

    class func writeData(data : Data, hashString : String) {
        APIResponseCacheManager.Constants.writerQueue.async {
            autoreleasepool {
                let pathEnd = "/"+hashString+Constants.cacheExtension
                let path = NetworkUtility.sharedManager.libraryCacheDirectory.appendingFormat(pathEnd)
                let fileURL = URL(fileURLWithPath: path)
                try? data.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
            }
        }
    }

    class func readData(hashString : String) -> Data? {
        var result : Data?
        APIResponseCacheManager.Constants.writerQueue.sync {
            let pathEnd = "/"+hashString+Constants.cacheExtension
            let path = NetworkUtility.sharedManager.libraryCacheDirectory.appendingFormat(pathEnd)
            let fileURL = URL(fileURLWithPath: path)
            result = try? Data(contentsOf: fileURL, options: Data.ReadingOptions.uncached)
        }

        return result
    }

    class func remove(hashString : String) {
        APIResponseCacheManager.Constants.writerQueue.async {
            let pathEnd = "/"+hashString+Constants.cacheExtension
            let path = NetworkUtility.sharedManager.libraryCacheDirectory.appendingFormat(pathEnd)
            let fileURL = URL(fileURLWithPath: path)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

