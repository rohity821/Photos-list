//
//  PhotoListViewController.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class PhotoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PhotosPresenterDelegateProtocol {
    
    @IBOutlet weak var photosListTableView: UITableView!
    
    var photosPresenter : PhotosPresenterInterfaceProtocol = PhotosPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        photosPresenter.delegate = self
        showLoadingIndicator()
        photosPresenter.startFetchingImages()
    }
    
    //MARK: UITableViewDatasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosPresenter.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "imageCell"
        let tableCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier);
        if let cell = tableCell as? PhotosTableViewCell, let model = photosPresenter.itemForRow(atIndexpath: indexPath) {
            cell.updateCell(withTitle: model.title, andThumbUrl: model.thumbnailUrl)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.photoListCellHeight)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        photosPresenter.didSelectRow(atIndexpath: indexPath, viewController: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.photoBrowserSegue {
            guard let indexPath = photosListTableView.indexPathForSelectedRow, let controller = segue.destination as? (UIViewController & PhotoBrowserInterfaceProtocol) else{
                return
            }
            if let model = photosPresenter.itemForRow(atIndexpath: indexPath), let cell = photosListTableView.cellForRow(at: indexPath) as? (UITableViewCell & PhotosTableCellInterfaceProtocol) {
                controller.setImageUrl(urlString: model.url, previewImage: cell.getThumbImage(), title: model.title)
            }
        }
    }
    
    func reloadTable() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadTable()
            }
            
            return
        }
        photosListTableView.reloadData()
    }
    
    //MARK: PhotosPresenterDelegateProtocol
    func didFetchImagesSuccessfully() {
        hideLoadingIndicator()
        reloadTable()
    }
    
    func didFetchImagesFailed() {
        //Handle error 
        hideLoadingIndicator()
    }
    
    //MARK: Loading Indicator
    func showLoadingIndicator() {
        let activityData = ActivityData(size: nil, message: nil, messageFont: nil, messageSpacing: nil, type: .ballClipRotateMultiple, color: nil, padding: nil, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: nil, textColor: nil)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
    }
    
    func hideLoadingIndicator() {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
    }


}

