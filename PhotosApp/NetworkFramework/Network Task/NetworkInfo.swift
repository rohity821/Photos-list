//
//  NetworkInfo.swift
//  NetworkFramework
//
//  Created by A19RSKV4 on 13/10/17.
//  Copyright © 2017 Wynk. All rights reserved.
//

import Foundation
import CoreTelephony

class NetworkInfo {
    private lazy var info : CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()
    private var currentRadio : String? {
        return info.currentRadioAccessTechnology
    }
    
    public var currentRadioInt:Int {
        
        if currentRadio != nil {
            switch currentRadio! {
            case CTRadioAccessTechnologyGPRS:
                return 1
            case CTRadioAccessTechnologyEdge:
                return 2
            case CTRadioAccessTechnologyWCDMA:
                return 3
            case CTRadioAccessTechnologyCDMA1x:
                return 4
            case CTRadioAccessTechnologyCDMAEVDORev0:
                return 5
            case CTRadioAccessTechnologyCDMAEVDORevA:
                return 6
            case CTRadioAccessTechnologyHSDPA:
                return 8
            case CTRadioAccessTechnologyHSUPA:
                return 9
            case CTRadioAccessTechnologyCDMAEVDORevB:
                return 12
            case CTRadioAccessTechnologyLTE:
                return 13
            case CTRadioAccessTechnologyeHRPD:
                return 14
            default:
                return 0
            }
        } else {
            return -1
        }
    }
}
