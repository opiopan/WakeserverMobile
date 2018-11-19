//
//  DashboardAccessory.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class DashboardAccessory : PortalAccessory {

    public let units : [PortalAccessory]
    
    public init(units: [PortalAccessory]) {
        self.units = units
        super.init()
    }
    
    public required init(dict: [String : Any]) throws {
        guard let units = dict["units"] as? [Any] else {
            throw PortalConfigError.partialyInconsistentData("MSG_ERR_NO_UNIT_IN_DASHBOARD")
        }
        
        self.units = units.map{
            do {
                guard let dict = $0 as? [String:Any],
                      let type = dict["type"] as? String,
                      let create = portalAccessories[type]?.create else{
                    return PortalAccessory()
                }
                return try create(dict)
            }catch{
                return PortalAccessory()
            }
        }.filter{$0.type != ""}
        
        guard self.units.count > 0 else {
            throw PortalConfigError.partialyInconsistentData("MSG_ERR_NO_UNIT_IN_DASHBOARD")
        }

        try super.init(dict: dict)
    }
    
    open override var dictionary: [String : Any]{
        get{
            var dict = super.dictionary
            dict["units"] = self.units.map{$0.dictionary}
            return dict
        }
    }

    override func reflectServerConfig(servers : [String : ServerDefinition]) {
        super.reflectServerConfig(servers: servers)
        units.forEach{$0.reflectServerConfig(servers: servers)}
    }
    
    override func reflectPowerStatus(statuses: [Any]) {
        units.forEach{$0.reflectPowerStatus(statuses: statuses)}
    }

    private var nextCharacteristicStatusUpdatee = -1
    
    override open func updateCharacteristicStatus(portal: Portal, notifier: (() -> Void)?) {
        guard nextCharacteristicStatusUpdatee < 0 else {
            notifier?()
            return
        }
        nextCharacteristicStatusUpdatee = 0
        updateUnitCharacteristicStatus(portal: portal, notifier: notifier)
    }
    
    private func updateUnitCharacteristicStatus(portal: Portal, notifier: (() -> Void)?) {
        guard nextCharacteristicStatusUpdatee < units.count else {
            nextCharacteristicStatusUpdatee = -1
            notifier?()
            return
        }
        let target = units[nextCharacteristicStatusUpdatee]
        nextCharacteristicStatusUpdatee += 1
        target.updateCharacteristicStatus(portal: portal){
            [unowned self] in
            self.updateUnitCharacteristicStatus(portal: portal, notifier: notifier)
        }
    }
    
    override open func resetState() {
        super.resetState()
        units.forEach{$0.resetState()}
    }
}
