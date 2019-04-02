
//  EtagsTask.swift
//  AirtelMovies
//
//  Created by a15tnkbm on 06/09/17.
//  Copyright © 2017 Accedo. All rights reserved.
//

import Foundation

class EtagsTask {

    private struct Constants {
        static let etag = "Etag"
        static let maxExpiryDays = 3
    }

    private static let sharedManager = EtagsTask()
    private var internalQueue = DispatchQueue(label: "com.rohit.PhotosApp.EtagsTask")
    private var model = EtagListDataModel()

    init() {
        
        defer {
            internalQueue.async {
                EtagsTask.cleanup()
            }
        }
    }

    private class func cleanup() {
        for item in EtagsTask.sharedManager.model.getCurrentList() {
            let diff = Date().interval(ofComponent: .day, fromDate: item.timeStamp)
            if diff > EtagsTask.Constants.maxExpiryDays {
                EtagsTask.sharedManager.model.removeByHash(hashID: item.hashID)
                APIResponseCacheManager.remove(hashString: item.hashID)
            }
        }
    }

    class func save() {
        EtagsTask.sharedManager.internalQueue.async {
            EtagsTask.sharedManager.model.saveData()
        }
    }
    
    class func deleteData() {
        EtagsTask.sharedManager.internalQueue.async {
            EtagsTask.sharedManager.model.deleteData()
        }
        
    }

    class func processEtag(urlRequest : URLRequest, requestBody :Dictionary<String,AnyObject>?, urlResponse : HTTPURLResponse, responseData : Data, expiryDuration : Double) {
        guard urlResponse.statusCode == 200 else { return }
        guard let url = urlRequest.url?.absoluteString else { return }

        EtagsTask.sharedManager.internalQueue.async {
            let timeStamp = Date()
            let hashString = NetworkUtility.generateHash(value: url, body: requestBody)
            APIResponseCacheManager.writeData(data: responseData, hashString: hashString)
            let etag = urlResponse.allHeaderFields[EtagsTask.Constants.etag] as? String
            
            let dataModel = EtagDataModel(timeStamp: timeStamp, url: url, expiryDuration: expiryDuration, hashID: hashString, etag: etag)
            EtagsTask.sharedManager.model.removeByHash(hashID: hashString)
            EtagsTask.sharedManager.model.append(data: dataModel)
        }
    }

    class func canMakeAPICall(urlRequest : URLRequest, requestBody :Dictionary<String,AnyObject>?) -> Bool {
        guard let url = urlRequest.url?.absoluteString else { return true }
        let hashString = NetworkUtility.generateHash(value: url, body: requestBody)
        
        var result = true
        
        EtagsTask.sharedManager.internalQueue.sync {
            
            if let data = EtagsTask.sharedManager.model.searchByHash(hashID: hashString) {
                let difference = Date().timeIntervalSince(data.timeStamp)
                if difference < 0 {
                    result = true
                } else if difference > data.expiryDuration {
                    result = true
                } else {
                    result = false
                }
            } else {
                result = true
            }
        }
        
        return result
    }

    class func getTag(urlRequest : URLRequest, requestBody :Dictionary<String,AnyObject>?) -> String? {
        //commented for now
//        guard let url = urlRequest.url?.absoluteString else { return nil }
        let result:String? = nil
//        EtagsTask.sharedManager.internalQueue.sync {
//            let hashString = NetworkUtility.generateHash(value: url, body: requestBody)
//            if let data = EtagsTask.sharedManager.model.searchByHash(hashID: hashString) {
//                result = data.etag
//            }
//        }
        return result
    }

    class func getCachedResponse(urlRequest : URLRequest, requestBody :Dictionary<String,AnyObject>?) -> Data? {
        guard let url = urlRequest.url?.absoluteString else { return nil }
        let hashString = NetworkUtility.generateHash(value: url, body: requestBody)
        return APIResponseCacheManager.readData(hashString:hashString)
    }
}

extension Date {
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        return end - start
    }
}


