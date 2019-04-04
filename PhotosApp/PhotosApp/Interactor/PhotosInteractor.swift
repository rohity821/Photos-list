//
//  PhotosInteractor.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

protocol PhotosInteractorInteraceProtocol {
    
    var delegate : PhotosInteractorDelegateProtocol? { get set }
    
    /**
     method initiates the call for fetching images from server. This method is invoked by presenter when viewcontroller asks for data.
     */
    func fetchImages()
}

protocol PhotosInteractorDelegateProtocol : class{
    
    /**
     delegate method used to notify the class implementing it that the data is fetched successfully and gives an array of imagemodels in param.
     */
    func didFetchPhotosCompleted(imageModels: [ImageModel])
    
    /**
     delegate method used to notify the implmenting class that fetching photos call have failed with error
     */
    func didFetchPhotosFailed(error:Error?)
}


class PhotosInteractor : PhotosInteractorInteraceProtocol {
    weak var delegate: PhotosInteractorDelegateProtocol?
    
    
    func fetchImages() {
        print("photosPresenter.startFetchingImages()")
        
        PhotosAPITask.fetchImagesfromServer(onSuccess: { [weak self] (imageModels) in
            // Handle Success
            if let imgModels = imageModels {
                self?.delegate?.didFetchPhotosCompleted(imageModels: imgModels)
            }
        }) { [weak self] (error) in
            //Handle Error
            self?.delegate?.didFetchPhotosFailed(error: error)
        }
    }
    
    
}
