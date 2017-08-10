//
//  WebUIViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/10/25.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class WebUIViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "http://mserver.local:8080/") {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
