//
//  VolumeFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class VolumeFunction : AVFunction {
    private let attribute = "volume"
    
    private var volumeValueHolder: Int?
    open var volumeValue: Int? {
        return volumeValueHolder
    }
    
    override func updateCharacteristics(portal: Portal, notifier: (() -> Void)?) {
        let command: Portal.AttributeCommand = (
            server: self.server,
            attribute: attribute,
            value: "",
            callback: {
                [unowned self] result, error in
                if result?.result == true, let value = result?.value {
                    self.volumeValueHolder = Int(value)
                }
                notifier?()
            }
        )
        portal.sendAttributeCommand(command, withOverride: true)
    }
    
    open func setVolume(portal: Portal, value: Int) {
        volumeValueHolder = value
        
        let command: Portal.AttributeCommand = (
            server: self.server,
            attribute: attribute,
            value: String(value),
            callback: nil
        )
        portal.sendAttributeCommand(command, withOverride: true)
    }
}


