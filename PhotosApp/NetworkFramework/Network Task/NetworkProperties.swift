//
//  NetworkProperties.swift
//  NetworkFramework
//
//  Created by A19RSKV4 on 13/10/17.
//  Copyright © 2017 Wynk. All rights reserved.
//

import Foundation
import AdSupport

public final class NetworkProperties {
    public struct Constants {
        public struct Keys {
            public static let deviceID = "deviceID"
            public static let deviceType = "deviceType"
            public static let osName = "osName"
            public static let osVersion = "osVersion"
            public static let appVersion = "appVersion"
            public static let buildNumber = "buildNumber"
            public static let userID = "userID"
            public static let userToken = "userToken"
            public static let languageCode = "languageCode"
            public static let deviceAdvertisingIdentifier = "deviceAdvertisingIdentifier"
            public static let deviceManufacturer = "deviceManufacturer"
            public static let deviceModel = "deviceModel"
            public static let deviceName = "deviceName"
        }
    }
    
    public var deviceID:String = ""
    public var deviceAdvertisingIdentifier:String = ""
    public var deviceManufacturer:String = ""
    public var deviceModel:String = ""
    public var deviceName:String = ""
    public var deviceType:String = ""
    public var osName:String = ""
    public var osVersion:String = ""
    public var appVersion:String = ""
    public var buildNumber:String = ""
    
    public var userID:String = ""
    public var userToken:String = ""
    
    public var networkQuality:Int = -1
    public var networkType:Int {
        return networkInfo.currentRadioInt
    }
    public var networkConnectionType:Int {
        return NetworkUtility.sharedManager.currentReachabilityStatus.rawValue
    }
    
    public var languageCode = "en_US"
    
    private var networkInfo:NetworkInfo
    
    init(networkInfo:NetworkInfo = NetworkInfo()) {
        self.networkInfo = networkInfo
    }
    
    func did() -> String {
        let tdid = "\(deviceID)|\(deviceType)|\(osName)|\(osVersion)|\(buildNumber)|\(appVersion)"
        return tdid
    }
    
    func currentCopy() -> NetworkProperties {
        let pr = NetworkProperties()
        pr.deviceID = deviceID
        pr.deviceType = deviceType
        pr.osName = osName
        pr.osVersion = osVersion
        pr.appVersion = appVersion
        pr.buildNumber = buildNumber
        
        pr.userID = userID
        pr.userToken = userToken
        
        pr.networkQuality = networkQuality
        pr.languageCode = languageCode
        
        pr.deviceAdvertisingIdentifier = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        pr.deviceManufacturer = "Apple"
        pr.deviceModel = UIDevice.current.model
        pr.deviceName = UIDevice.current.name
        return pr
    }
    
     func updateUserData(data : Dictionary<AnyHashable,Any>) {
        if let value = data[NetworkProperties.Constants.Keys.deviceID] as? String {
            deviceID = value
        }
        if let value = data[NetworkProperties.Constants.Keys.deviceType] as? String {
            deviceType = value
        }
        if let value = data[NetworkProperties.Constants.Keys.osName] as? String {
            osName = value
        }
        if let value = data[NetworkProperties.Constants.Keys.osVersion] as? String {
            osVersion = value
        }
        if let value = data[NetworkProperties.Constants.Keys.appVersion] as? String {
            appVersion = value
        }
        if let value = data[NetworkProperties.Constants.Keys.buildNumber] as? String {
            buildNumber = value
        }
        
        if let value = data[NetworkProperties.Constants.Keys.userID] as? String {
            userID = value
        }
        if let value = data[NetworkProperties.Constants.Keys.userToken] as? String {
            userToken = value
        }
        
        if let value = data[NetworkProperties.Constants.Keys.languageCode] as? String {
            languageCode = value
        }
        
    }
}
