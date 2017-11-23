//
//  InterfaceController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/08/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch


class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.setTitle("ほげほげ")

        IPC.session.getLocation{
            result, error in
            /*
            let id = result?.portalId
            let url = result?.portalUrl
             */
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func onTest() {
        IPC.session.getLocation{result, error in
            if let result = result {
                let url = result.portalUrl
                let id = result.portalId
            }
        }
    }
}