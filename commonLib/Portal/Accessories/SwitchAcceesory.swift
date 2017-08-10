//
//  SwitchAcceesory.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class SwitchAccessory : PortalAccessoryCorrespondsServer {
    override public init() {
        super.init()
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
    }
}
