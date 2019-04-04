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
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(PhotoListViewController.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.red
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        photosListTableView.addSubview(refreshControl)
        photosListTableView.tableFooterView = UIView()
        photosPresenter.delegate = self
        showLoadingIndicator()
        startFetchingData()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        startFetchingData()
    }
    
    func startFetchingData() {
        photosPresenter.startFetchingImages()
    }
    
    //MARK: UITableViewDatasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosPresenter.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier);
        if let cell = tableCell as? (UITableViewCell & PhotosTableCellInterfaceProtocol),
            let model = photosPresenter.itemForRow(atIndexpath: indexPath) {
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
    
    //MARK: Navigation
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
    
    /**
     This method reloads table with new data set, if it is not called on main thread it checks and call itself on main thread so that table reload happens on main thread.
     */
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
    /**
     This methods show blocking loading indicator on view.
    */
    func showLoadingIndicator() {
        let activityData = ActivityData(size: nil, message: nil, messageFont: nil, messageSpacing: nil, type: .ballClipRotateMultiple, color: nil, padding: nil, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: nil, textColor: nil)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
    }
    
    /**
     This method hides loading indicator and ends refresh control animation whichever applicable, if it is not called on main thread it checks and call itself on main thread.
     */
    func hideLoadingIndicator() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
            }
            return
        }
        if (refreshControl.isRefreshing) {
            refreshControl.endRefreshing()
        }else {
            NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
        }
    }


}

