//
//  ViewController.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation
import UIKit

/*
 ThreadSafePlistTask class creates a thread-safe dictionary and also provisions persistence through plist
 
 The class is optimized for writing operation of dictionary to plist.
 - writes when ThreadSafePlistWriteFrequency is achieved.
 - writes when "expensiveWrite" argument is provided with true value.
 - writes when UIApplicationDidEnterBackgroundNotification is received
 - writes before deinit
 
 NOTE:
 - Don't write in loops, memory will spike.
 - Don't create file more than 50 MB - it will be deleted on Load!!
 - Don't create two ThreadSafePlistTask object for same plistPath
 - Don't abuse "expensiveWrite" argument with true value.
 - serializable content should be present in dictionary.
 
 */

public enum ThreadSafePlistWriteFrequency : Int {
    case almostNone = 500
    case veryLow = 50
    case low = 40
    case normal = 30
    case high = 10
    case veryHigh = 5
}

public class ThreadSafePlistTask {
    
    private struct Constants {
        static let commonOperationQueue = DispatchQueue(label: "com.rohit.ThreadSafePlistTask.common.reader", qos: DispatchQoS.userInitiated, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
        static let writerQueue = DispatchQueue(label: "com.rohit.ThreadSafePlistTask.common.write")
        static let maxPlistFileThresholdSize:UInt64 = 50 * 1024 * 1024
    }
    
    private var plistPath:String?
    private var pListDictionary = [String: AnyObject]()
    private var writeOperationCount = 0
    private var writeFrequency:ThreadSafePlistWriteFrequency
    
    public init(plistPath:String?, writeFrequency:ThreadSafePlistWriteFrequency) {
        self.plistPath = plistPath
        self.writeFrequency = writeFrequency
        
        if let plistPath = plistPath {
            Constants.writerQueue.sync(flags: .barrier) { [unowned self] in
                
                //deleting plist file if more than 50 MB
                var fileSize : UInt64 = 0
                do {
                    let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: plistPath) as NSDictionary
                    
                    if let _attr = attr {
                        fileSize = _attr.fileSize()
                    }
                } catch {
                    print("ThreadSafePlistTask: \(plistPath) fileSize Error: \(error)")
                }
                
                if fileSize > 0 {
                    print("ThreadSafePlistTask \(plistPath) \(fileSize / 1024 / 1024) MB")
                    if fileSize > Constants.maxPlistFileThresholdSize {
                        print("ThreadSafePlistTask: \(plistPath) deleted due to over size")
                        _ = try? FileManager.default.removeItem(atPath: plistPath)
                    }
                }
                
                if let dict = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, AnyObject> {
                    self.pListDictionary = dict
                    print("ThreadSafePlistTask \(plistPath) \(dict.keys.count) count")
                } else {
                    let isWriteSuccessful = NSDictionary().write(toFile: plistPath, atomically: true)
                    assert(isWriteSuccessful,"unable to create plist \(plistPath)")
                }
                NotificationCenter.default.addObserver(self, selector: #selector(ThreadSafePlistTask.notificationApplicationWillResignActive), name:UIApplication.didEnterBackgroundNotification, object: nil)
            }
        }
        
    }
    
    deinit {
        print("ThreadSafePlistTask deallocated \(plistPath ?? "")")
        tryExpnesiveWrite(expnesiveWrite: true)
        NotificationCenter.default.removeObserver(self)
    }
    
    subscript(key:String) -> AnyObject? {
        get {
            return valueForKey(key: key)
        }
        set(value) {
            setValueForKey(key: key, value: value, expensiveWrite:false)
        }
    }
    
    
    public func valueForKey(key:String) -> AnyObject? {
        var result:AnyObject?
        
        readSync(completion: { [unowned self] in
            result = self.pListDictionary[key]
        })
        
        return result
    }
    
    public func setValueForKey(key:String, value:AnyObject?, expensiveWrite:Bool) {
        if let tValue = value {
            Constants.commonOperationQueue.sync(flags: .barrier) { [unowned self] in
                self.pListDictionary[key] = tValue
                self.tryExpnesiveWrite(expnesiveWrite: expensiveWrite)
            }
        }else {
            let _ = removeValueForKey(key: key, expensiveWrite: expensiveWrite)
        }
    }
    
    public func removeValueForKey(key:String, expensiveWrite:Bool) -> AnyObject? {
        var result:AnyObject?
        
        Constants.commonOperationQueue.sync(flags: .barrier) { [unowned self] in
            result = self.pListDictionary.removeValue(forKey: key)
            self.tryExpnesiveWrite(expnesiveWrite: expensiveWrite)
        }
        
        return result
    }
    
    public func removeAll() {
        Constants.commonOperationQueue.sync(flags: .barrier) { [unowned self] in
            self.pListDictionary.removeAll()
            self.tryExpnesiveWrite(expnesiveWrite: true)
        }
    }
    
    //do not use ThreadSafePlistTask object inside this, will lead to deadlock
    public func writeSync(key:String,completion:@escaping (_ value:AnyObject?)->AnyObject?) {
        Constants.commonOperationQueue.sync(flags: .barrier) { [unowned self] in
            var value = self.pListDictionary[key]
            value = completion(value)
            self.pListDictionary[key] = value
        }
    }
    
    //do not use ThreadSafePlistTask object inside this, will lead to deadlock
    func readSync(completion:@escaping ()->()) {
        if #available(iOS 9.0, *) {
            //on iOS 9 due to priority inversion main thread does not gets blocked hence this hack, has been added
            completion()
            return
        }
        Constants.commonOperationQueue.sync() {
            completion()
        }
    }
    
    public func keys() -> Array<String>?  {
        var result:Array<String>?
        
        readSync(completion: { [unowned self] in
            result = Array(self.pListDictionary.keys)
        })
        
        return result
    }
    
    @objc private func notificationApplicationWillResignActive() {
        Constants.commonOperationQueue.sync(flags: .barrier) { [unowned self] in
            NSLog("ThreadSafePlistTask notificationApplicationWillResignActive: saving \(String(describing: self.plistPath))")
            self.tryExpnesiveWrite(expnesiveWrite: true)
        }
    }
    
    public func tryExpnesiveWrite(expnesiveWrite:Bool) {
        if let plistPath = self.plistPath {
            self.writeOperationCount = self.writeOperationCount + 1
            
            if expnesiveWrite {
                ThreadSafePlistTask.write(queue: Constants.writerQueue, path: plistPath, data: self.pListDictionary)
                self.writeOperationCount = 0
            }else {
                if self.writeOperationCount == self.writeFrequency.rawValue {
                    ThreadSafePlistTask.write(queue: Constants.writerQueue, path: plistPath, data: self.pListDictionary)
                    self.writeOperationCount = 0
                }
            }
        }
    }
    
    private class func write(queue:DispatchQueue,path:String,data:[String: AnyObject]) {
        queue.async() {
            autoreleasepool {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    (data as NSDictionary).write(toFile: path, atomically: true)
                }
            }
        }
    }
}
