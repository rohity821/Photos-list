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
    /**
     This is interface protocol method of presenter class, via which view controller says that presenter should fetch images
     */
    func startFetchingImages()
    
    /**
     This is the datasource method for view controller's tableView. This is called from tableview's method numberofRowsInSection
     */
    func numberOfRows() -> Int
    func itemForRow(atIndexpath indexPath:IndexPath) -> ImageModel?
    func didSelectRow(atIndexpath : IndexPath, viewController:PhotoListViewController)
}

protocol PhotosPresenterDelegateProtocol : class {
    
    /**
     This is a delegate method of presenter class which notifies view controller that it has fetched data successfully so that view can reload the data from presenter.
     */
    func didFetchImagesSuccessfully()
    
    /**
     This is a delegate method of presenter class which notifies view controller that there was a error in fetching data so that view can handle it accordingly.
     */
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
