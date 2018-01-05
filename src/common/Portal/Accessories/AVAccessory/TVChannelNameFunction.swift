//
//  TVChannelNameFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class TVChannelNameFunction : AVFunction {
    open func setChannel(portal: Portal, name: String) {
        let command: Portal.AttributeCommand = (
            server: self.server,
            attribute: "tvchannelname",
            value: name,
            callback: nil
        )
        portal.sendAttributeCommand(command, withOverride: true)
    }
}
