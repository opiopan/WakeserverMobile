//
//  DetectingSheetController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2018/01/08.
//  Copyright © 2018年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch

class DetectingSheetController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        placeRecognizer.refleshForce()
    }
    
    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

}
