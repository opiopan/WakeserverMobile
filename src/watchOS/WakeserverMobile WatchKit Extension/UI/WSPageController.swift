//
//  WSPageController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/24.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch

typealias WSPageContext = (
    portal: Portal,
    page: PortalAccessory
)

class WSPageController: WKInterfaceController {
    var context : WSPageContext?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? WSPageContext {
            self.context = context
            setTitle(self.context?.page.name)
        }
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}
