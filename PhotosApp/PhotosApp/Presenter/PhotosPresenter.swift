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
     This is the datasource method for view controller's tableView. This is called from tableview's method numberofRowsInSection. Method returns an integer value equal to number of rows in section.
     */
    func numberOfRows() -> Int
    
    /**
     This is the datasource method for view controller's tableView. This is called from tableview's method cellforRowAtIndexPath. Method takes current index path as param and returns ImageModel to fill information on that cell.
     */
    func itemForRow(atIndexpath indexPath:IndexPath) -> ImageModel?
   
    /**
     This method is called user taps on a cell in tableview. Method takes indexpath and view controller as parameter. And correspondingly navigates to another view.
     */
    func didSelectRow(atIndexpath : IndexPath, viewController:PhotoListViewController)
}

protocol PhotosPresenterDelegateProtocol : class {
    
    /**
     delegate method used to notify the class implementing it that the data is fetched. Result depends on the ResultType enum. if result is success, it will contain an array of imagemodels. In case of error, it will have an error object
     */
    func didFetchPhotos(result: ResultType)
    
}

class PhotosPresenter : PhotosPresenterInterfaceProtocol, PhotosInteractorDelegateProtocol {
    weak var delegate: PhotosPresenterDelegateProtocol?
    
    private var datasourceArray = [ImageModel]()
    private let photosInteractor : PhotosInteractorInteraceProtocol
    
    init(photosInteractor : PhotosInteractorInteraceProtocol) {
        self.photosInteractor = photosInteractor
        photosInteractor.delegate = self;
    }
    
    //MARK: PhotosInteractorDelegateProtocol
    
    func didFetchPhotos(result: ResultType) {
        switch result {
        case .success(imageModels: let model):
            datasourceArray = model
        case .failure(let error):
            print("error occured \(String(describing: error))")
        }
        delegate?.didFetchPhotos(result: result)
    }
    
    func didFetchPhotosFailed(error: Error?) {
        print("didFetchPhotosFailed() \(String(describing: error?.localizedDescription))")
        
    }
    
    //MARK: PhotosPresenterInterfaceProtocol
    func startFetchingImages() {
        print("photosPresenter.startFetchingImages()")
        photosInteractor.fetchImages()
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
