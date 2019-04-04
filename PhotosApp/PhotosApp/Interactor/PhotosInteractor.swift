//
//  PhotosInteractor.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

enum ResultType {
    case success(imageModels: [ImageModel])
    case failure(error:Error?)
}

protocol PhotosInteractorInteraceProtocol: class {
    
    var delegate : PhotosInteractorDelegateProtocol? { get set }
    
    /**
     method initiates the call for fetching images from server. This method is invoked by presenter when viewcontroller asks for data.
     */
    func fetchImages()
}

protocol PhotosInteractorDelegateProtocol : class {
    /**
     delegate method used to notify the class implementing it that the data is fetched. Result depends on the ResultType enum. if result is success, it will contain an array of imagemodels. In case of error, it will have an error object
     */
    func didFetchPhotos(result: ResultType)
}


class PhotosInteractor : PhotosInteractorInteraceProtocol {
    
    weak var delegate: PhotosInteractorDelegateProtocol?
    private var apiTask : PhotosAPITaskInterfaceProtocol?
    
    init(apiTask : PhotosAPITask) {
        self.apiTask = apiTask
    }
    
    func fetchImages() {
        print("photosPresenter.startFetchingImages()")
        apiTask?.fetchImagesfromServer(onSuccess: { [weak self] (imageModels) in
            // Handle Success
            if let imgModels = imageModels {
                self?.delegate?.didFetchPhotos(result: .success(imageModels: imgModels))
            }
        }) { [weak self] (error) in
            //Handle Error
            self?.delegate?.didFetchPhotos(result: .failure(error: error))
        }
    }
    
    
}
