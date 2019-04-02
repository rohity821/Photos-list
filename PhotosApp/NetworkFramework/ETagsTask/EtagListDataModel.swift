//
//  EtagModel.swift
//  AirtelMovies
//
//  Created by a15tnkbm on 06/09/17.
//  Copyright © 2017 Accedo. All rights reserved.
//

import Foundation
import CommonLibrarySwift

struct EtagListDataModel {

    private struct Constants {
        static let rootKey = "tags"
        static let plistFileName = "/ETagsData.plist"
    }

    private var internalQueue = OperationQueue()
    private var etagThreadSafeList : ThreadSafePlistTask
    private var etagDataList = [EtagDataModel]()

    init() {
        let plistPath = NetworkUtility.sharedManager.libraryDirectory.appendingFormat(EtagListDataModel.Constants.plistFileName)
        etagThreadSafeList = ThreadSafePlistTask(plistPath: plistPath, writeFrequency: ThreadSafePlistWriteFrequency.normal)
        
        internalQueue.maxConcurrentOperationCount = 1

        if let etagThreadSafeList = etagThreadSafeList.valueForKey(key: EtagListDataModel.Constants.rootKey) as? Array<String> {
            let decoder = JSONDecoder()
            var loadedData = Array<EtagDataModel>()
            for jsonString in etagThreadSafeList {
                if let jsonData = jsonString.data(using: .utf8), let etagData = try? decoder.decode(EtagDataModel.self, from: jsonData) {
                    loadedData.append(etagData)
                }
            }
            etagDataList = loadedData
        }
    }

    func getCurrentList() -> [EtagDataModel] {
        return etagDataList
    }

    func searchByHash(hashID:String) -> EtagDataModel? {
        if let tIndex = etagDataList.firstIndex(where: { $0.hashID == hashID }) {
            return etagDataList[tIndex]
        }

        return nil
    }

    mutating func removeByHash(hashID:String) {
        if let tIndex = etagDataList.firstIndex(where: { $0.hashID == hashID }) {
            self.remove(index: tIndex)
        }
    }

    mutating func append(data : EtagDataModel) {
        etagDataList.append(data)
    }

    mutating func remove(index : Int) {
        if index != NSNotFound && index < etagDataList.count {
            etagDataList.remove(at: index)
        }
    }

    func saveData() {
        internalQueue.addOperation {
            let encoder = JSONEncoder()
            var dataArray = Array<String>()
            for item in self.etagDataList {
                if let jsonData = try? encoder.encode(item), let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                    dataArray.append(jsonString)
                }
            }

            self.etagThreadSafeList.setValueForKey(key: EtagListDataModel.Constants.rootKey, value: dataArray as AnyObject, expensiveWrite: true)
        }
    }
    
    mutating func deleteData() {
        etagThreadSafeList.removeAll()
        etagDataList = [EtagDataModel]()
    }
}

