//
//  DebugViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/12/16.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class DebugViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onRefleshButton(_ sender: Any) {
        complicationUpdater.reflesh(asBackground: false, whenCompletePlaceUpdate: {
        }, whenCompleteStatusUpdate: {
            complicationRepresentation.updateAndSyncWithWatch(force: true)
        }, onError: {
            error in
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
