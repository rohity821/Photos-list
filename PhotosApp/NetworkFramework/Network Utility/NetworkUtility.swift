//
//  NetworkUtility.swift
//  AirtelMovies
//
//  Created by Bhartendu on 29/08/17.
//  Copyright © 2017 Accedo. All rights reserved.
//

import Foundation
import SystemConfiguration
import CoreTelephony

@objc public enum ReachabilityStatus : Int {
    case unknown = -1
    case notReachable = 0
    case reachableViaWWAN = 1
    case reachableViaWiFi = 2
}

public final class NetworkUtility : NSObject {

    struct Constants {
        static let appToken = "bhartendu"
        struct httpFields {
            static let did = "x-atv-did"
            static let utkn = "x-atv-utkn"
            static let etag = "If-None-Match"
            static let contentType = "Content-Type"
        }
    }

    public static let sharedManager : NetworkUtility = NetworkUtility()
    private let properties = NetworkProperties()
    private(set) var defaultExpirationTime:Double = 3600
    
    private lazy var info         : CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()

    lazy var libraryCacheDirectory:String = {
        let path : String = ((NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]) as String)
        let destPath : String = path.appending("/Data/Network/Cache")
        if !FileManager.default.fileExists(atPath: destPath) {
            try? FileManager.default.createDirectory(atPath: destPath, withIntermediateDirectories: true, attributes: nil)
        }
        return destPath
    }()

    lazy var libraryDirectory:String = {
        let path : String = ((NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]) as String)
        let destPath : String = path.appending("/Data/Network")
        if !FileManager.default.fileExists(atPath: destPath) {
            try? FileManager.default.createDirectory(atPath: destPath, withIntermediateDirectories: true, attributes: nil)
        }
        return destPath
    }()

    public lazy var documentDirectory:String = {
        let destPath:String = ((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]) as String)
        return destPath
    }()

    class func generateHash(value : String, body :Dictionary<String,AnyObject>?) -> String {
        var tValue = value
        if let tBody = body {
            if let data = try? JSONSerialization.data(withJSONObject: tBody, options: JSONSerialization.WritingOptions.init(rawValue: 0)) {
                if let dataString = String.init(data: data, encoding: String.Encoding.utf8) {
                    tValue = tValue.appendingFormat(dataString)
                }
            }
        }
        var localStringValueForHashCreation = tValue
        if let tSigningHandler = NetworkUtility.sharedManager.signingHandler {
            localStringValueForHashCreation = tSigningHandler(tValue,Constants.appToken)
        }
        let localHash = localStringValueForHashCreation.hash
        let hashString = String.init(localHash)

        return hashString
    }

    var currentReachabilityStatus: ReachabilityStatus {

        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }

        if flags.contains(.reachable) == false {
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
    
    public var mcc :String? {
        
        if let mobileCountryCode = info.subscriberCellularProvider?.mobileCountryCode {
            return "\(mobileCountryCode)"
        }
        
        return nil
    }
    
    public var mnc :String? {
        
        if let mobileNetworkCode = info.subscriberCellularProvider?.mobileNetworkCode {
            return "\(mobileNetworkCode)"
        }
        
        return nil
    }

    private var currentQualityInt    : Int {
        return -1
    }

    var lastPersistedRadio   : String?

    private var signingHandler:((_ url:String, _ key:String) -> String)?

    var backgroundCompletionHandlersDictionary : NSMutableDictionary?

    public class func getCurrentReachabilityStatus() -> ReachabilityStatus {
        return NetworkUtility.sharedManager.currentReachabilityStatus
    }

    public class func setSigningHandler(signingHandler:@escaping ((_ url:String, _ key:String) -> String)) {
        NetworkUtility.sharedManager.signingHandler = signingHandler
    }

    public class func setBackgroundCompletionHandlersDictionary(dictionary : NSMutableDictionary) {
        NetworkUtility.sharedManager.backgroundCompletionHandlersDictionary = dictionary
    }
    
    public class func currentProperties() -> NetworkProperties {
        return NetworkUtility.sharedManager.properties.currentCopy()
    }

    public class func populateUserData(data : Dictionary<AnyHashable,Any>) {
        NetworkUtility.sharedManager.properties.updateUserData(data: data)
    }

    public class func headerString() -> String {
        return "\(NetworkUtility.sharedManager.currentReachabilityStatus.rawValue)/\(NetworkUtility.sharedManager.properties.networkType)/\(NetworkUtility.sharedManager.properties.networkQuality)"
    }

    public class func getSignedUrlRequest(urlRequest : URLRequest, body : Dictionary<String,AnyObject>?, addtionalHeaderFeilds : Dictionary<String,String>?, urlString : String) -> URLRequest? {
        var tUrlRequest = urlRequest
        guard var data = urlRequest.httpMethod?.uppercased() else {
            NSLog("network error as urlRequest.httpMethod.uppercased() is nil")
            return nil
        }
        if let relativePath = urlRequest.url?.relativePath {
            data.append(relativePath)
        }
        
        if let query = urlRequest.url?.query {
            data.append("?\(query)")
        }

        if let b = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: b, options: JSONSerialization.WritingOptions.init(rawValue: 0))
                if let str = String(data:jsonData, encoding: .utf8) {
                    data.append(str)
                }
            } catch {

            }
        }

        tUrlRequest.setValue(NetworkUtility.sharedManager.properties.did(), forHTTPHeaderField: Constants.httpFields.did)
        
        if let tSigningHandler = NetworkUtility.sharedManager.signingHandler {
            let hash = tSigningHandler(data,NetworkUtility.sharedManager.properties.userToken)
            let utkn = NetworkUtility.sharedManager.properties.userID + ":" + hash
            tUrlRequest.setValue(utkn, forHTTPHeaderField: Constants.httpFields.utkn)
        }
        if tUrlRequest.value(forHTTPHeaderField: Constants.httpFields.contentType) == nil {
            tUrlRequest.setValue("application/json", forHTTPHeaderField:  Constants.httpFields.contentType)
        }

        //        if let requestUrl = URL(string:urlString), let etag = EtagsTask.getTag(urlRequest: URLRequest(url:requestUrl), requestBody: body) {
        //            tUrlRequest.setValue(etag, forHTTPHeaderField: Constants.httpFields.etag)
        //        }
        //        tUrlRequest = NetworkUtility.getRequestAfterAppendingEtag(in: tUrlRequest, for: body)

        if let tAdditionalHeaderFeild = addtionalHeaderFeilds {
            for (key,value) in tAdditionalHeaderFeild{
                tUrlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return tUrlRequest
    }

    public class func getRequestAfterAppendingEtag(in request:URLRequest,for body:Dictionary<String,AnyObject>?) -> URLRequest{
        var resultantRequest = request
        if let etag = EtagsTask.getTag(urlRequest: request, requestBody: body) {
            resultantRequest.setValue(etag, forHTTPHeaderField: Constants.httpFields.etag)
        }
        return resultantRequest
    }

    public class func setDefaultExpirationTime(_ expirationTime:Double){
        NetworkUtility.sharedManager.defaultExpirationTime = expirationTime
    }
    
    public class func clearNetworkData() {
        let url = NetworkUtility.sharedManager.libraryCacheDirectory
        if let files = try? FileManager.default.contentsOfDirectory(atPath: url) {
            for item in files {
                let path = "file://" + NetworkUtility.sharedManager.libraryCacheDirectory + "/" + item
                if let tUrl = URL.init(string: path) {
                    do {
                        try FileManager.default.removeItem(at: tUrl)
                    } catch let error{
                        print(error)
                    }
                }
            }
        }
        EtagsTask.deleteData()
    }
    
    public class func saveEtagData() {
        EtagsTask.save()
    }
}


