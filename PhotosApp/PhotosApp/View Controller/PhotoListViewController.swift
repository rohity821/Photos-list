//
//  PhotoListViewController.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 02/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class PhotoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PhotosPresenterDelegateProtocol, ErrorViewDelegateProtocol {
    
    @IBOutlet weak var photosListTableView: UITableView!
    
    var photosPresenter : PhotosPresenterInterfaceProtocol?
    var builder : AppBuilder?
    
    private var errorView : ErrorViewInterfaceProtocol?
    
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
        photosPresenter?.delegate = self
        
        startFetchingData(showLoader: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let errView = errorView as? UIView {
            errView.frame = view.bounds
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        startFetchingData(showLoader: false)
    }
    
    func startFetchingData(showLoader: Bool) {
        if showLoader {
            showLoadingIndicator()
        }
        photosPresenter?.startFetchingImages()
    }
    
    //MARK: UITableViewDatasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let presenter = photosPresenter {
            return presenter.numberOfRows()
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier);
        if let cell = tableCell as? (UITableViewCell & PhotosTableCellInterfaceProtocol),
            let model = photosPresenter?.itemForRow(atIndexpath: indexPath) {
            cell.updateCell(withTitle: model.title, andThumbUrl: model.thumbnailUrl)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.photoListCellHeight)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        photosPresenter?.didSelectRow(atIndexpath: indexPath, viewController: self)
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.photoBrowserSegue {
            guard let indexPath = photosListTableView.indexPathForSelectedRow, let controller = segue.destination as? (UIViewController & PhotoBrowserInterfaceProtocol) else{
                return
            }
            if let model = photosPresenter?.itemForRow(atIndexpath: indexPath), let cell = photosListTableView.cellForRow(at: indexPath) as? (UITableViewCell & PhotosTableCellInterfaceProtocol) {
                controller.setImageUrl(urlString: model.url, previewImage: cell.getThumbImage(), title: model.title)
            }
        }
    }
    
    //MARK: Private functions
    /**
     This method reloads table with new data set, if it is not called on main thread it checks and call itself on main thread so that table reload happens on main thread.
     */
    private func reloadTable() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadTable()
            }
            return
        }
        photosListTableView.reloadData()
    }
    
    /**
     This method shows error view in case there is a failure or no data to be shown
    */
    private func showErrorView(message:String?) {
        if (errorView == nil) {
            errorView = builder?.getErrorView()
            errorView?.delegate = self
        }
        if let errView = errorView as? UIView{
            view.addSubview(errView)
        }
    }
    
    //MARK: PhotosPresenterDelegateProtocol
    func didFetchPhotos(result: ResultType) {
        hideLoadingIndicator()
        switch result {
        case .success(imageModels: _):
            reloadTable()
        case .failure(error: _):
            self.showErrorView(message: nil)
        }
    }
    
    //MARK: Error View Interface Protocol
    func errorViewDidTapRetry() {
        if let errView = errorView as? UIView {
            errView.removeFromSuperview()
        }
        startFetchingData(showLoader: true)
    }
    
    //MARK: Loading Indicator
    /**
     This methods show blocking loading indicator on view.
    */
    private func showLoadingIndicator() {
        let activityData = ActivityData(size: nil, message: nil, messageFont: nil, messageSpacing: nil, type: .ballClipRotateMultiple, color: nil, padding: nil, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: nil, textColor: nil)
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
    }
    
    /**
     This method hides loading indicator and ends refresh control animation whichever applicable, if it is not called on main thread it checks and call itself on main thread.
     */
    private func hideLoadingIndicator() {
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

