//
//  PhotosPresenter.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation

protocol PhotosPresenterInterfaceProtocol : class {
    var delegate : PhotosPresenterDelegateProtocol? {get set}
    func startFetchingImages()
    func numberOfRows() -> Int
    func itemForRow(atIndexpath indexPath:IndexPath) -> ImageModel?
    func didSelectRow(atIndexpath : IndexPath, viewController:PhotoListViewController)
}

protocol PhotosPresenterDelegateProtocol : class {
    func didFetchImagesSuccessfully()
    func didFetchImagesFailed()
}

class PhotosPresenter : PhotosPresenterInterfaceProtocol, PhotosInteractorDelegateProtocol {
    weak var delegate: PhotosPresenterDelegateProtocol?
    
    private var datasourceArray = [ImageModel]()
    private var photosInteractor : PhotosInteractorInteraceProtocol = PhotosInteractor()
    
    init() {
        photosInteractor.delegate = self;
    }
    
    func startFetchingImages() {
        print("photosPresenter.startFetchingImages()")
        photosInteractor.fetchImages()
    }
    
    
    //MARK: PhotosInteractorDelegateProtocol
    func didFetchPhotosCompleted(imageModels: [ImageModel]) {
        print("didFetchPhotosCompleted()")
        datasourceArray = imageModels
        delegate?.didFetchImagesSuccessfully()
    }
    
    func didFetchPhotosFailed() {
        print("didFetchPhotosFailed()")
        delegate?.didFetchImagesFailed()
    }
    
    
    func numberOfRows() -> Int {
        return datasourceArray.count
    }
    
    func itemForRow(atIndexpath indexPath:IndexPath) -> ImageModel? {
        var imgModel : ImageModel?
        if (indexPath.row < datasourceArray.count) {
            imgModel = datasourceArray[indexPath.row]
        }
        return imgModel
    }
    
    func didSelectRow(atIndexpath: IndexPath, viewController: PhotoListViewController) {
        viewController.performSegue(withIdentifier: Constants.photoBrowserSegue, sender: viewController)
    }
    
}
