//
//  AppBuilder.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 04/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import Foundation
import UIKit

class AppBuilder {
    
    let url = "http://jsonplaceholder.typicode.com/photos"
    
    func getRootViewController() -> UINavigationController? {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let rootController = storyboard.instantiateViewController(withIdentifier: "PhotoListViewController") as? PhotoListViewController
        
        let apiTask = PhotosAPITask(serverUrl: url)
        let interactor = PhotosInteractor(apiTask: apiTask)
        let presenter = PhotosPresenter(photosInteractor: interactor)
        rootController?.photosPresenter = presenter
        rootController?.builder = self

        if let rootVC = rootController {
         return UINavigationController(rootViewController: rootVC)
        }
        return nil
    }
    
    func getErrorView() -> ErrorViewInterfaceProtocol {
        let errorView = ErrorView(frame: .zero)
        return errorView
    }
    
    
    
    
}
