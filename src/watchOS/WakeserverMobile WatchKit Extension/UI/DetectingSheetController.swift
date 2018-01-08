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
        communicator.getLocation(handler: {portalData, error in
            guard let portalData = portalData else {
                if let portal = placeRecognizer.place.portalObject() {
                    placeRecognizer.setPlace(withPortal: (portalId: portal.id, service: portal.service))
                }else if placeRecognizer.place.isOutdoors(){
                    placeRecognizer.setPlace(withPortal: (portalId: nil, service: nil))
                }
                return
            }
            placeRecognizer.setPlace(withPortal: portalData)
        })
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

}
