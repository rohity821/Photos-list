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
    
    func fetchImages()
}

protocol PhotosInteractorDelegateProtocol : class{
    func didFetchPhotosCompleted(imageModels: [ImageModel])
    func didFetchPhotosFailed()
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
            self?.delegate?.didFetchPhotosFailed()
        }
    }
    
    
}
