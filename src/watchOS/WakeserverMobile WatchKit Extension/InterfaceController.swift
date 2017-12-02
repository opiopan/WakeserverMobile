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


class InterfaceController: WKInterfaceController, PlaceRecognizerDelegate {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.setTitle("ほげほげ")
        /*
        IPC.session.start()
        IPC.session.getLocation{
            result, error in
            if let result = result {
                let url = result.portalUrl
                let id = result.portalId
            }
        }
        */
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        placeRecognizer.register(delegate: self)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func placeRecognizerDetectChangePortal(recognizer: PlaceRecognizer, place: PlaceType) {
        switch place {
        case .outdoors:
            self.setTitle("Outdoors")
        case .portal(let portal):
            self.setTitle(portal.name)
        default:
            self.setTitle("ほげほげ")
        }
    }

    @IBAction func onMenuItem() {
    }
    
    @IBAction func onTest() {
        IPC.session.getLocation{[unowned self] result, error in
            if let result = result {
                let id = result.portalId
                let portals = ConfigurationController.sharedController.registeredPortals
                if let index = portals.index(where:{$0.id == id}) {
                    self.setTitle(portals[index].name)
                }
            }
        }
    }
}
