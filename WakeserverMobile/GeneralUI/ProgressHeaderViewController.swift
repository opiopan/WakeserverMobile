//
//  ProgressHeaderViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/23.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class ProgressHeaderViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    static func viewController(_ owner: UIViewController) -> ProgressHeaderViewController {
        return owner.storyboard?.instantiateViewController(withIdentifier: "progressHeader") as! ProgressHeaderViewController
    }
    
    var labelText : String? {
        get {
            return label?.text
        }
        set (text){
            if view != nil && view.subviews.count > 0 {
                label.text = text
            }
        }
    }
    
    func startAnimating(){
        indicator.startAnimating()
    }
    
    func stopAnimating(){
        indicator.stopAnimating()
    }
}
