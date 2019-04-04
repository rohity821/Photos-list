//
//  PhotosAPITask.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

protocol PhotosAPITaskInterfaceProtocol : class {
    func fetchImagesfromServer(onSuccess:@escaping ([ImageModel]?)->Void, onFailure:@escaping (Error?)->Void)
}

class PhotosAPITask : PhotosAPITaskInterfaceProtocol {
    
    private var serverUrl : String?
    
    init(serverUrl : String) {
        self.serverUrl = serverUrl
    }
    
    func fetchImagesfromServer(onSuccess:@escaping ([ImageModel]?)->Void, onFailure:@escaping (Error?)->Void) {
        if let apiUrl = serverUrl, let url = URL(string: apiUrl) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let dataResponse = data, error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let model = try decoder.decode([ImageModel].self, from:
                        dataResponse)
                    onSuccess(model)
                } catch let parsingError {
                    print("Error", parsingError)
                    onFailure(parsingError)
                }
            }
            task.resume()
        }
    }
}
