//
//  SimpleFooterViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class SimpleFooterViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    static func viewController(_ owner: UIViewController) -> SimpleFooterViewController {
        return owner.storyboard?.instantiateViewController(withIdentifier: "simpleFooter") as! SimpleFooterViewController
    }

    var labelText : String? {
        get {
            return label?.text
        }
        set (text){
            if view.subviews.count > 0 {
                label.text = text
            }
        }
    }
}
