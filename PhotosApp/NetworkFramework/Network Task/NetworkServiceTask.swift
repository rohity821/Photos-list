//
//  NetworkServiceTask.swift
//  Wynk Music
//
//  Created by Ankit Gupta on 12/23/16.
//  Copyright © 2016 Wynk. All rights reserved.
//

import Foundation

/*

 Discusion - This file has classes and methods to perform network tasks.
 Currently these classes are used for DOWNLOAD FUNCTIONALITY ONLY.
 The normal session tasks have been blocked as they are in progress
 of development.
 */

public enum ResponseType {
    case error(uniqueIdentifier:String?,urlRequest:URLRequest,error:NSError)
    case progress(uniqueIdentifier:String?,urlRequest:URLRequest,result:Progress)
    case completed(uniqueIdentifier:String?,urlRequest:URLRequest)
    case responseArray(uniqueIdentifier:String?,urlRequest:URLRequest,result:NSArray?,cached:Bool)
    case responseDictionary(uniqueIdentifier:String?,urlRequest:URLRequest,result:NSDictionary?,cached:Bool)
    case responseData(uniqueIdentifier:String?,urlRequest:URLRequest,result:NSData?,cached:Bool)
}

@objc public enum APICallCachePolicy : Int {
    case notApplicable = 0
    case returnBoth = 1
    case returnIgnoringCache = 2
    case returnOnlyCache = 3
}

public typealias CompletionHandlerType = (ResponseType) -> Void

// Todo remove Locks and replace it with GCD or NSOperationQueue

class NetworkingManager:NSObject,URLSessionDelegate,URLSessionDataDelegate,URLSessionDownloadDelegate{

    private struct Constants{
        static let defaultExpiryTime = Double(3600)
        static let backgroundSessionIdentifier = "in.movies.networkServiceTask.networkManager.backgroundSession"
    }

    static let sharedManager = NetworkingManager()
    fileprivate let internalQueue = OperationQueue()
    fileprivate let internalBackgroundQueue = OperationQueue()
    fileprivate var allTaskDictionary = [URLSessionTask:NetworkItem]()
    fileprivate var allTaskResponse = [URLSessionTask:Data]()
    fileprivate var allTaskEtags = [URLSessionTask:String]()
    var backgroundSession:URLSession?
    var dataSession:URLSession?
    fileprivate let sessionLock = NSLock()
    fileprivate let allTaskDictionaryLock = NSLock()

    fileprivate func getUrlSessionTask(for networkItem:NetworkItem) -> URLSessionTask {
        switch networkItem.type {
        case .sessionTask:
            getCachedData(for: networkItem)
            let request = networkItem.urlRequest
            let dataSession = getDataSession()
            let sessionTask = dataSession.dataTask(with:request)
            allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary.updateValue(networkItem, forKey: sessionTask)
            })
            return sessionTask
        case .downloadTask:
            getCachedData(for: networkItem)
            let request = networkItem.urlRequest
            let dataSession = getDataSession()
            let downloadTask = dataSession.downloadTask(with: request)
            allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary.updateValue(networkItem, forKey: downloadTask)
            })
            return downloadTask
        case .backgroundTask:
            let urlRequest = networkItem.urlRequest
            let session = getBackgroundSession()
            let sessionTask = session.downloadTask(with: urlRequest)
            allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary.updateValue(networkItem, forKey: sessionTask)
            })
            return sessionTask
        }
    }

    fileprivate func removeTask(_ task:URLSessionTask){
        allTaskDictionaryLock.withCriticalScope(block: {
            allTaskDictionary.removeValue(forKey: task)
        })
        sessionLock.withCriticalScope(block: {
            allTaskResponse.removeValue(forKey: task)
        })
    }

    fileprivate func getCachedData(for networkItem:NetworkItem) {
//        internalQueue.addOperation {
        if networkItem.cachePolicy != .returnIgnoringCache {
            guard let urlString = networkItem.url.absoluteString else { return }
            if let url = URL(string:urlString), let result = EtagsTask.getCachedResponse(urlRequest: URLRequest(url:url), requestBody: networkItem.body) {
                do{
                    let jsonObject = try JSONSerialization.jsonObject(with: result, options: .mutableContainers)
                    if jsonObject is NSArray {
                        networkItem.completion(ResponseType.responseArray(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: jsonObject as? NSArray, cached: true))
                    }
                    else{
                        networkItem.completion(ResponseType.responseDictionary(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: jsonObject as? NSDictionary, cached: true))
                    }
                } catch let err as NSError {
                    NSLog("\(err)")
                    networkItem.completion(ResponseType.responseData(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: result as NSData, cached: true))
                }
            } else {
                // all three callbacks: it is expected client will have implemented only one of these, since it knows what kind of data to expect from this call
                networkItem.completion(ResponseType.responseArray(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: nil, cached: true))
                networkItem.completion(ResponseType.responseDictionary(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: nil, cached: true))
                networkItem.completion(ResponseType.responseData(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: nil, cached: true))
            }
        }
//        }
    }

    fileprivate func getBackgroundSession() -> URLSession{
        sessionLock.withCriticalScope(block: {
            if backgroundSession == nil {
                let backgroundConfig = URLSessionConfiguration.background(withIdentifier: NetworkingManager.Constants.backgroundSessionIdentifier)
                backgroundConfig.sessionSendsLaunchEvents = true
                backgroundConfig.isDiscretionary = true
                backgroundSession = URLSession(configuration: backgroundConfig, delegate: self, delegateQueue: self.internalBackgroundQueue)
            }
        })
        return backgroundSession!
    }

    fileprivate func getDataSession() ->URLSession{
        sessionLock.withCriticalScope(block: {
            if dataSession == nil {
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.timeoutIntervalForRequest = TimeInterval(10)
                dataSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: self.internalQueue)
            }
        })
        return dataSession!
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64){
        //You can get progress here
        if let networkItem = allTaskDictionaryLock.withCriticalScope(block: {allTaskDictionary[downloadTask]}){
            networkItem.progress.totalUnitCount = totalBytesExpectedToWrite
            networkItem.progress.completedUnitCount = totalBytesWritten
            networkItem.completion(ResponseType.progress(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: networkItem.progress))
            NSLog("Received: \(bytesWritten) bytes (Downloaded: (totalBytesWritten) bytes)  Expected: \(totalBytesExpectedToWrite) bytes.\n");
        }
        else{
            NSLog("No networkItem found for the downloaded data progress to report")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        if let networkItem = allTaskDictionaryLock.withCriticalScope(block: {allTaskDictionary[downloadTask]}){
            self.downloadFinished(url: location,storeUrl: URL(string:networkItem.downloadAtPath!), response: downloadTask.response as? HTTPURLResponse, error:downloadTask.error! as NSError)
            let _ = allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary.removeValue(forKey: downloadTask)
                if (session == dataSession){
                    allTaskResponse.removeValue(forKey: downloadTask)
                }
            })
            networkItem.completion(ResponseType.completed(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest))
        }
        else{
            NSLog("No networkItem found for the downloaded data")
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = NetworkUtility.sharedManager.backgroundCompletionHandlersDictionary?[session.configuration.identifier!] as? ()->Void{
            DispatchQueue.main.async(){
                completionHandler()
            }
            allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary = [URLSessionTask:NetworkItem]()
                session.getAllTasks{ (allTasks) in
                    for task in allTasks{
                        self.allTaskDictionary.removeValue(forKey: task)
                        self.allTaskResponse.removeValue(forKey: task)
                    }
                }
            })
            NetworkUtility.sharedManager.backgroundCompletionHandlersDictionary?.removeObject(forKey: session.configuration.identifier!)
        }
        else{
            NSLog("No background Task found for the downloaded data")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        if let networkItem = allTaskDictionaryLock.withCriticalScope(block: {allTaskDictionary[task]}){
            if (error != nil){
                networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error! as NSError))
            }
            else if session == dataSession {
                if let urlResponse = task.response as? HTTPURLResponse {
                    if urlResponse.statusCode == 200 || urlResponse.statusCode == 304 {
                        if let data = allTaskDictionaryLock.withCriticalScope(block: {allTaskResponse[task]}){
                            if let request = task.originalRequest,let urlResponse = task.response as? HTTPURLResponse {
                                var expiryTime = 0.0
                                if networkItem.cachePolicy != .returnIgnoringCache {
                                    if let tExpiryTime = networkItem.expiryDuration {
                                        expiryTime = tExpiryTime
                                    } else {
                                        expiryTime = NetworkingManager.Constants.defaultExpiryTime
                                    }
                                }
                                EtagsTask.processEtag(urlRequest: request, requestBody: nil, urlResponse: urlResponse, responseData: data, expiryDuration:expiryTime)
                            }
                            do{
                                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                                if jsonObject is NSArray {
                                    networkItem.completion(ResponseType.responseArray(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: jsonObject as? NSArray, cached: false))
                                }
                                else{
                                    networkItem.completion(ResponseType.responseDictionary(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: jsonObject as? NSDictionary, cached: false))
                                }
                            }
                            catch let err as NSError {
                                NSLog("\(err)")
                                networkItem.completion(ResponseType.responseData(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, result: data as NSData, cached: false))
                            }
                        }
                    } else {
                        if let data = allTaskDictionaryLock.withCriticalScope(block: {allTaskResponse[task]}){
                            do{
                                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [AnyHashable : Any] {
                                    let error = NSError(domain: urlResponse.description, code: urlResponse.statusCode, userInfo: jsonObject as? [String : Any])
                                    networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error))
                                }else {
                                    let error = NSError(domain: urlResponse.description, code: urlResponse.statusCode, userInfo: nil)
                                    networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error))
                                }
                            }
                            catch _ {
                                let error = NSError(domain: urlResponse.description, code: urlResponse.statusCode, userInfo: nil)
                                networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error))
                            }
                        }else {
                            let error = NSError(domain: urlResponse.description, code: urlResponse.statusCode, userInfo: nil)
                            networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error))
                        }
                    }
                }
            }
            networkItem.completion(ResponseType.completed(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest))

            let _ = allTaskDictionaryLock.withCriticalScope(block: {
                allTaskDictionary.removeValue(forKey: task)
                allTaskResponse.removeValue(forKey: task)
            })
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void){
        if let networkItem = allTaskDictionaryLock.withCriticalScope(block: {allTaskDictionary[dataTask]}){
            var expiryTime = 0.0
            if networkItem.cachePolicy != .returnIgnoringCache {
                if let tExpiryTime = networkItem.expiryDuration {
                    expiryTime = tExpiryTime
                } else {
                    expiryTime = NetworkingManager.Constants.defaultExpiryTime
                }
            }
            EtagsTask.processEtag(urlRequest: dataTask.originalRequest!, requestBody: nil, urlResponse: response as! HTTPURLResponse, responseData:Data(), expiryDuration: expiryTime)
            if let tResponse = response as? HTTPURLResponse {
                if tResponse.statusCode == 304 { //todo_nikhil: whether or not 304 we have to call for completion
                    networkItem.completion(ResponseType.completed(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest))
                }
            }
        }
        completionHandler(.allow);
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data){
        allTaskDictionaryLock.withCriticalScope(block: {
            var networkResponse = allTaskResponse[dataTask]
            if networkResponse == nil{
                networkResponse = data
            }
            else{
                networkResponse?.append(data)
            }
            allTaskResponse[dataTask] = networkResponse!
        })
    }
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?){
        sessionLock.withCriticalScope(block: {
            if session == backgroundSession{
                backgroundSession = nil
            }
            else{
                dataSession = nil
            }
            allTaskDictionaryLock.withCriticalScope(block: {
                if (error != nil){
                    session.getAllTasks{ (allTasks) in
                        for task in allTasks{
                            if let networkItem = self.allTaskDictionary[task]{
                                networkItem.completion(ResponseType.error(uniqueIdentifier: networkItem.uniqueIdentifier, urlRequest: networkItem.urlRequest, error:error! as NSError))
                                self.allTaskDictionary.removeValue(forKey: task)
                                self.allTaskResponse.removeValue(forKey: task)
                            }
                        }
                    }
                }
            })
        })
    }

    func cancel()
    {
        allTaskDictionaryLock.withCriticalScope(block: {
            for (_,networkItem) in allTaskDictionary{
                networkItem.cancel()
            }
            allTaskDictionary = [URLSessionTask:NetworkItem]()
            allTaskResponse   = [URLSessionTask:Data]()
        })

    }

    fileprivate func downloadFinished(url: URL?,storeUrl:URL? ,response: HTTPURLResponse?, error: NSError?) {
        if let cacheURL = storeUrl {
            do {
                /*
                 If we already have a file at this location, just delete it.
                 Also, swallow the error, because we don't really care about it.
                 */
                try FileManager.default.removeItem(at: cacheURL as URL) //todo_nikhil Use AMUtils method

            }
            catch let err as NSError {
                NSLog("cacheURL of Network Item has no file to delete \(err)")
            }
            do {
                try FileManager.default.moveItem(at: url! as URL, to: cacheURL as URL)
            } catch let err as NSError  {
                NSLog("\(err.localizedDescription)")
            }
        }
        else {
            NSLog("DownloadAtPath of Network Item is nil")
        }
    }
}




//this struct should only be used by the network service task and not by the app
fileprivate class NetworkItem {
    //MARK:NetworkItem enums
    enum NetworkCallType {
        case DELETE
        case GET
        case POST
        case PUT
    }

    enum NetworkingTaskType{
        case sessionTask,downloadTask,backgroundTask
    }

    enum NetworkItemError: Error {
        case IncorrectURLString
        case Unknown
    }
    //MARK:NetworkItem properties
    let body:Dictionary<String,AnyObject>?
    let addtionalHeaderFeilds : Dictionary<String,String>?
    let uniqueIdentifier:String?
    let callType:NetworkCallType
    let completion:CompletionHandlerType
    let isSigned: Bool
    let progress:Progress
    let type:NetworkingTaskType
    let url:NSURL
    let downloadAtPath:String?
    let expiryDuration:Double?
    var cachePolicy:APICallCachePolicy
    var urlRequest : URLRequest
    fileprivate var sessionTask = URLSessionTask()

    init(uniqueIdentifier:String?, url:String, callType:NetworkCallType, body:Dictionary<String,AnyObject>?, addtionalHeaderFeilds : Dictionary<String,String>?, isSigned: Bool,downloadAtPath:String? , expiryDuration:Double?, type:NetworkingTaskType,cachePolicy:APICallCachePolicy, completion:@escaping CompletionHandlerType) throws {
        guard let nsurl = NSURL(string: url) else {
            throw NetworkItemError.IncorrectURLString
        }

        self.uniqueIdentifier = uniqueIdentifier
        self.body = body
        self.addtionalHeaderFeilds = addtionalHeaderFeilds
        self.callType = callType
        self.completion = completion
        self.isSigned = isSigned
        self.progress = Progress()
        self.type = type
        self.url = nsurl
        self.cachePolicy = cachePolicy
        self.downloadAtPath = downloadAtPath
        if let expirationDuration = expiryDuration {
            self.expiryDuration = expirationDuration
        }
        else {
            self.expiryDuration = NetworkUtility.sharedManager.defaultExpirationTime
        }


        // todo_nikhil isSigned is not used here right now use it change the serializer
        var mutableRequest = URLRequest.init(url: nsurl as URL, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)
        switch callType {
        case .POST:
            mutableRequest.httpMethod = "POST"
        case .DELETE:
            mutableRequest.httpMethod = "DELETE"
        case .GET:
            mutableRequest.httpMethod = "GET"
        case .PUT:
            mutableRequest.httpMethod = "PUT"
        }

        if let tBody = body {
            mutableRequest.httpBody = try? JSONSerialization.data(withJSONObject: tBody, options: JSONSerialization.WritingOptions.init(rawValue: 0))
        }

        if isSigned
        {
            if let urlRequest = NetworkUtility.getSignedUrlRequest(urlRequest: mutableRequest, body: body, addtionalHeaderFeilds: addtionalHeaderFeilds, urlString: url) {
                mutableRequest = urlRequest
            } else {
                NSLog("Url request signing failed")
            }
        } else {
            if let tAddtionalHeaderFields = addtionalHeaderFeilds {
                for (key,value) in tAddtionalHeaderFields{
                    mutableRequest.setValue(value, forHTTPHeaderField: key)
                }
            }
        }
        mutableRequest = NetworkUtility.getRequestAfterAppendingEtag(in: mutableRequest, for: body)
        self.urlRequest = mutableRequest
        sessionTask = NetworkingManager.sharedManager.getUrlSessionTask(for:self)
    }

    func cancel() {
        self.sessionTask.cancel()
    }

    func pause() {
        assert(self.type == .sessionTask, "Only download operations can be paused")
        self.sessionTask.suspend()
    }

    func resume() {
        if self.type == .sessionTask {
            guard let urlString = url.absoluteString else {
                // todo check this not looking right
                completion(ResponseType.completed(uniqueIdentifier: self.uniqueIdentifier, urlRequest: self.urlRequest))
                return
            }
            if cachePolicy == .returnIgnoringCache {
                self.sessionTask.resume()
            } else {
                if let url = URL(string:urlString) {
                    if  EtagsTask.canMakeAPICall(urlRequest:URLRequest(url:url), requestBody: self.body) {
                        self.sessionTask.resume()
                    }
                    else{
                        NetworkingManager.sharedManager.removeTask(sessionTask)
                        completion(ResponseType.completed(uniqueIdentifier: self.uniqueIdentifier, urlRequest: self.urlRequest))
                    }
                }
            }
        } else {
            self.sessionTask.resume()
        }
    }
}

//this struct should only be used by the network service task and not by the app
fileprivate struct GroupNetworkItem {
    let progress:Progress
    let children:[NetworkItem]
    let completion:CompletionHandlerType

    init(children:[NetworkItem], completion:@escaping CompletionHandlerType) throws {

        self.children = children
        self.progress = Progress()
        self.completion = completion

        for item in children {
            if #available(iOS 9.0, *) {
                self.progress.addChild(item.progress, withPendingUnitCount: 1)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    func cancel() {
        for item in children {
            item.cancel()
        }
    }

    func pause() {
        for item in children {
            item.pause()
        }
    }

    func resume() {
        for item in children {
            item.resume()
        }
    }
}

public struct ApiRequestTask {
    fileprivate let networkItem:NetworkItem

    public static func get(uniqueIdentifier:String?, url:String, addtionalHeaderFeilds : Dictionary<String,String>?, isSigned: Bool, expiryDuration:Double?,cachePolicy:APICallCachePolicy, completion:@escaping CompletionHandlerType) throws -> ApiRequestTask {
        let networkTask = try ApiRequestTask(uniqueIdentifier: uniqueIdentifier, url:url, callType:NetworkItem.NetworkCallType.GET, body:nil, addtionalHeaderFeilds: addtionalHeaderFeilds, isSigned: isSigned, expiryDuration:expiryDuration, cachePolicy: cachePolicy,completion:completion)
        return networkTask
    }

    public static func post(uniqueIdentifier:String?, url:String, body:Dictionary<String,AnyObject>?, addtionalHeaderFeilds : Dictionary<String,String>?, isSigned: Bool, expiryDuration:Double?,cachePolicy:APICallCachePolicy, completion:@escaping CompletionHandlerType) throws -> ApiRequestTask {
        let networkTask = try ApiRequestTask(uniqueIdentifier:uniqueIdentifier, url:url, callType:NetworkItem.NetworkCallType.POST, body:body, addtionalHeaderFeilds: addtionalHeaderFeilds, isSigned: isSigned, expiryDuration:expiryDuration, cachePolicy: cachePolicy, completion:completion)
        return networkTask
    }

    public static func delete(uniqueIdentifier:String?,url:String, body:Dictionary<String,AnyObject>?, addtionalHeaderFeilds : Dictionary<String,String>?, isSigned: Bool, expiryDuration:Double?,cachePolicy:APICallCachePolicy, completion:@escaping CompletionHandlerType) throws -> ApiRequestTask {
        let networkTask = try ApiRequestTask(uniqueIdentifier: uniqueIdentifier, url:url, callType:NetworkItem.NetworkCallType.DELETE, body:body, addtionalHeaderFeilds: addtionalHeaderFeilds, isSigned: isSigned, expiryDuration:expiryDuration,cachePolicy:cachePolicy, completion:completion)
        return networkTask
    }

    public func cancel(){
        networkItem.cancel()
    }

    public func pause(){
        networkItem.pause()
    }

    public func resume(){
        networkItem.resume()
    }

    fileprivate init(uniqueIdentifier:String?, url:String, callType:NetworkItem.NetworkCallType, body:Dictionary<String,AnyObject>?, addtionalHeaderFeilds : Dictionary<String,String>?, isSigned: Bool, expiryDuration:Double?,cachePolicy:APICallCachePolicy,completion:@escaping CompletionHandlerType) throws {
        networkItem = try NetworkItem(uniqueIdentifier:uniqueIdentifier, url:url, callType:callType, body:body, addtionalHeaderFeilds: addtionalHeaderFeilds, isSigned: isSigned,downloadAtPath:nil, expiryDuration: expiryDuration, type:NetworkItem.NetworkingTaskType.sessionTask, cachePolicy : cachePolicy, completion:completion)
    }
}

public struct DownloadRequestTask {
    fileprivate let networkItem:NetworkItem

    public static func get(uniqueIdentifier:String?, url:String, inBackground:Bool, isSigned: Bool,downloadAtPath:String, completion:@escaping CompletionHandlerType) throws -> DownloadRequestTask {
        let downloadNetworkItem = try DownloadRequestTask(uniqueIdentifier: uniqueIdentifier, url:url,inBackground: inBackground, isSigned: isSigned,downloadAtPath:downloadAtPath,completion:completion)

        return downloadNetworkItem
    }

    fileprivate init(uniqueIdentifier:String?, url:String, inBackground:Bool, isSigned: Bool, downloadAtPath:String, completion:@escaping CompletionHandlerType) throws {
        if inBackground {
            networkItem = try NetworkItem(uniqueIdentifier: uniqueIdentifier, url:url, callType:NetworkItem.NetworkCallType.GET, body:nil, addtionalHeaderFeilds: nil, isSigned: isSigned,downloadAtPath:downloadAtPath, expiryDuration: nil, type:NetworkItem.NetworkingTaskType.backgroundTask, cachePolicy:.notApplicable, completion:completion)
        }
        else{
            networkItem = try NetworkItem(uniqueIdentifier: uniqueIdentifier, url:url, callType:NetworkItem.NetworkCallType.GET, body:nil, addtionalHeaderFeilds: nil, isSigned: isSigned,downloadAtPath:downloadAtPath, expiryDuration: nil, type:NetworkItem.NetworkingTaskType.downloadTask, cachePolicy: .notApplicable, completion:completion)
        }
    }

    public func cancel() {
        networkItem.cancel()
    }

    public func pause() {
        networkItem.pause()
    }

    public func resume() {
        networkItem.resume()
    }
}

public struct GroupRequestTask {
    fileprivate let groupNetworkItem:GroupNetworkItem

    fileprivate init(networkItemArray:[NetworkItem], completion:@escaping CompletionHandlerType) throws {
        groupNetworkItem = try GroupNetworkItem(children:networkItemArray, completion:completion)
    }

    init(apiRequestItems:[ApiRequestTask], completion:@escaping CompletionHandlerType) throws {
        var networkItemArray = [NetworkItem]()
        for requestItem in apiRequestItems{
            networkItemArray.append(requestItem.networkItem)
        }
        do {
            try self.init(networkItemArray:networkItemArray,completion: completion)
        } catch let err as NSError {
            throw(err)
        }
    }

    init(downloadRequestItems:[DownloadRequestTask], completion:@escaping CompletionHandlerType) throws {
        var networkItemArray = [NetworkItem]()
        for requestedItem in downloadRequestItems{
            networkItemArray.append(requestedItem.networkItem)
        }
        do {
            try self.init(networkItemArray:networkItemArray,completion: completion)
        } catch let err as NSError {
            throw(err)
        }
    }

    public func cancel() {
        groupNetworkItem.cancel()
    }

    public func pause() {
        groupNetworkItem.pause()
    }

    public func resume() {
        groupNetworkItem.resume()
    }
}

extension NSLock {
    @discardableResult func withCriticalScope<T>( block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}
