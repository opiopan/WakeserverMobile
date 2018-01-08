//
//  HomeSheetController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2018/01/07.
//  Copyright © 2018年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch

class HomeSheetControllerContext {
    let name: String
    let portal: Portal
    init(name: String, portal: Portal){
        self.name = name
        self.portal = portal
    }
}

class HomeSheetController: WKInterfaceController {
    @IBOutlet var portalImage: WKInterfaceImage!
    @IBOutlet var descriptionLabel: WKInterfaceLabel!
    
    private var context: HomeSheetControllerContext?
    
    //-----------------------------------------------------------------------------------------
    // MARK: - initialization
    //-----------------------------------------------------------------------------------------
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? HomeSheetControllerContext {
            self.context = context
            setTitle(self.context?.name)
            let imageName = context.portal.isOutdoors ? "platform_icon_outdoors" : "platform_icon_home"
            portalImage.setImage(UIImage(named: imageName))
            descriptionLabel.setText(context.portal.hostDescription)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - status transition
    //-----------------------------------------------------------------------------------------
    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - portal detecting
    //-----------------------------------------------------------------------------------------
    @IBAction func detectPortal() {
        placeRecognizer.changeToDetectingPage()
    }
}
