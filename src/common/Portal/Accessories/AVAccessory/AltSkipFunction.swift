//
//  AltSkipFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class AltSkipFunction: AVFunction {
    open var forward : Int?
    open var backward : Int?
    
    public enum Verb: String {
        case forward = "altskipf"
        case rewind = "altskipb"
    }
    
    public required init(type: String, server: String) {
        super.init(type: type, server: server)
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        refrectOption(option: dict)
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            if let value = forward {dict["forward"] = value}
            if let value = backward {dict["backward"] = value}
            return dict
        }
    }
    
    override open func refrectOption(option: [String : Any]) {
        super.refrectOption(option: option)
        if let value = option["forward"] as? Int {
            forward = value
        }
        if let value = option["backward"] as? Int {
            backward = value
        }
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
