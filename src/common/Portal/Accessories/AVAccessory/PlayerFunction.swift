//
//  PlayerFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class PlayerFunction : AVFunction {
    public enum Verb: String {
        case playPause = "pauseplay"
        case forward = "skipf"
        case rewind = "skipb"
    }
    
    open func invokeAction(onPortal portal: Portal, withVerb action: Verb) {
        let command: Portal.AttributeCommand = (
            server: self.server,
            attribute: "player",
            value: {action.rawValue},
            callback: nil
        )
        portal.sendAttributeCommand(command, withOverride: false)
    }
}
