//
//  ErrorVIew.swift
//  PhotosApp
//
//  Created by Rohit Yadav on 05/04/19.
//  Copyright © 2019 Rohit Yadav. All rights reserved.
//

import UIKit

protocol ErrorViewInterfaceProtocol : class {
    var delegate : ErrorViewDelegateProtocol? {get set}
    func updateError(message: String?, buttonTitle:String?)
}

protocol ErrorViewDelegateProtocol : class {
    func errorViewDidTapRetry()
}

class ErrorView: UIView, ErrorViewInterfaceProtocol {

    @IBOutlet weak private var contentView: UIView!
    @IBOutlet weak private var retryButton: UIButton!
    @IBOutlet weak private var messageLabel: UILabel!
    @IBOutlet weak private var imageVIew: UIImageView!
    
    weak var delegate : ErrorViewDelegateProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        loadViewNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
    
    private func loadViewNib() {
        Bundle.main.loadNibNamed("ErrorView", owner: self, options: nil)
        self.addSubview(contentView)
        self.backgroundColor = UIColor.red
    }
    
    func updateError(message: String?, buttonTitle: String?) {
        if let mes = message {
            messageLabel.text = mes
        }
        if let title = buttonTitle {
            retryButton.setTitle(title, for: .normal)
        }
    }
    
}
