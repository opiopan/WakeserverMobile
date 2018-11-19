//
//  PortalAccessory.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import HomeKit

public protocol PortalAccessoryDelegate : AnyObject {
    func changeStatus(accessory: PortalAccessory)
}

open class PortalAccessory : LooseSerializable {
    public enum PowerState {
        case unknown
        case on
        case off
    }
    
    open var name : String
    open var type : String
    public let server : String?
    open var iconName : String?
    
    open var model : String = ""
    open var isDiagnosable : Bool = false
    open var isWakeable : Bool = false
    open var isSleepable : Bool = false
    open var isRebootable : Bool = false
    open var index : Int?
    
    open var hmHomeId : String?
    open var hmAccessoryId : String?
    open var hmServiceId : String?
    open var hmHome : HMHome?
    open var hmService : HMService?
    
    open var powerState : PowerState = .unknown
    
    open var complicationStatusString : String {
        get {
            switch powerState {
            case .unknown:
                return LocalizedString("POWER_STATE_UNKNOWN")
            case .on:
                return LocalizedString("POWER_STATE_ON")
            case .off:
                return LocalizedString("POWER_STATE_OFF")
            }
        }
    }

    private var delegates = [PortalAccessoryDelegate]()

    public init() {
        name = ""
        type = ""
        server = nil
        iconName = nil
    }
    
    open func reflectTypeInformation(){
        if let attribute = portalAccessoryAttribute(correspondTo: self) {
            self.type = attribute.type
        }
    }
    
    public required init(dict: [String : Any]) throws {
        guard let name = dict["name"] as! String?, let type = dict["type"] as! String? else {
            throw PortalConfigError.partialyInconsistentData(LocalizedString("MSG_ERR_NO_REQ_PARAM_ACCESSORY"))
        }
        self.name = name
        self.type = type
        self.server = dict["server"] as! String?
        self.iconName = dict["icon"] as! String?
        if let value = dict["model_name"] as? String {model = value}
        if let value = dict["is_diagnosable"] as? Bool {isDiagnosable = value}
        if let value = dict["is_wakeable"] as? Bool {isWakeable = value}
        if let value = dict["is_sleepable"] as? Bool {isSleepable = value}
        if let value = dict["is_rebootable"] as? Bool {isRebootable = value}
        if let value = dict["index"] as? Int {index = value}
        if let value = dict["hm_home_id"] as? String {hmHomeId = value}
        if let value = dict["hm_accessory_id"] as? String {hmAccessoryId = value}
        if let value = dict["hm_service_id"] as? String {hmServiceId = value}
        
        if let homeid = hmHomeId, let accessoryId = hmAccessoryId, let serviceId = hmServiceId {
            HomeKitManager.sharedManager.waitForInitialize{
                [unowned self] manager in
                if let obj = manager.serviceAndReleatedObjects(
                    homeId: homeid, accessoryId: accessoryId, serviceId: serviceId) {
                    self.hmHome = obj.home
                    self.hmService = obj.service
                    self.invokeChangeState()
                }
            }
        }
    }
    
    public var dictionary: [String : Any] {
        get {
            let attributes = portalAccessoryAttribute(correspondTo: self)

            var dict : [String : Any] = [
                "name": name,
                "type" : attributes!.type,
                "model_name" : model,
                "is_diagnosable" : isDiagnosable,
                "is_wakeable" : isWakeable,
                "is_sleepable" : isSleepable,
                "is_rebootable" : isRebootable,
            ]
            if let value = server {dict["server"] = value}
            if let value = iconName {dict["icon"] = value}
            if let value = index {dict["index"] = value}
            if let value = hmHomeId {dict["hm_home_id"] = value}
            if let value = hmAccessoryId {dict["hm_accessory_id"] = value}
            if let value = hmServiceId {dict["hm_service_id"] = value}

            return dict
        }
    }
    
    open func register(delegate: PortalAccessoryDelegate) {
        if (delegates.index{$0 === delegate}) == nil {
            delegates.append(delegate)
        }
    }
    
    open func unregister(delegate: PortalAccessoryDelegate) {
        if let index = (delegates.index{$0 === delegate}) {
            delegates.remove(at: index)
        }
    }
    
    func invokeChangeState() {
        DispatchQueue.main.async {
            [unowned self] in
            self.delegates.forEach{$0.changeStatus(accessory: self)}
        }
    }

    func reflectServerConfig(servers : [String : ServerDefinition]) {
        if let serverName = self.server, let serverDef = servers[serverName] {
            if let value = serverDef.comment {model = value}
            isDiagnosable = serverDef.isDiagnosable
            isWakeable = serverDef.isWakeable
            isSleepable = serverDef.isSleepable
            isRebootable = serverDef.isSleepable
            index = serverDef.index
        }
    }
    
    func reflectPowerStatus(statuses: [Any]) {
    }

    open func updateCharacteristicStatus(portal: Portal, notifier: (()->Void)?) {
        if let service = hmService {
            service.characteristics.filter{$0.characteristicType == HMCharacteristicTypePowerState}.forEach{
                characteristic in
                weak var weakSelf = self
                characteristic.readValue{
                    error in
                    if error == nil, let power = characteristic.value as? Bool {
                        let oldState = weakSelf?.powerState
                        weakSelf?.powerState = power ? .on : .off
                        if oldState != weakSelf?.powerState {
                            self.invokeChangeState()
                        }
                    }
                }
            }
        }
        notifier?()
    }

    open var preferenceIcon : UIImage? {
        get {
            let icon = iconName == nil ? type : iconName!
            return portalAccessories[icon]?.preferenceIcon
        }
    }
    
    open var dashboardIcon : UIImage? {
        get {
            let icon = iconName == nil ? type : iconName!
            return portalAccessories[icon]?.dashboardIcon
        }
    }
    
    open func reflectOption(of accessory: PortalAccessory) {
    }
    
    open func resetState(){
        powerState = .unknown
    }
}

open class PortalAccessoryCorrespondsServer : PortalAccessory {
    public override init() {
        super.init()
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        guard server != nil || (hmHomeId != nil && hmAccessoryId != nil && hmServiceId != nil) else{
            throw PortalConfigError.partialyInconsistentData(LocalizedString("MSG_ERR_NO_REQ_PARAM_ACCESSORY"))
        }
    }
    
    override func reflectPowerStatus(statuses: [Any]) {
        if let index = index, statuses.count > index,
            let conf = statuses[index] as? [String:Any], let status = conf["status"] as? String {
            var powerState = PowerState.unknown
            switch status {
            case "on":
                powerState = .on
            case "off":
                powerState = .off
            default:
                powerState = .unknown
            }
            if self.powerState != powerState {
                self.powerState = powerState
                self.invokeChangeState()
            }
        }
    }
    
    open func togglePowerStatus(viaPortal portal: Portal) {
        switch powerState {
        case .off:
            if isWakeable {
                powerState = .on
                portal.sendPowerControllCommand(forAccessory: self, power: true){
                    [unowned self] result in
                    if !result {
                        self.powerState = .off
                    }
                }
            }
        case .on:
            if isSleepable {
                powerState = .off
                portal.sendPowerControllCommand(forAccessory: self, power: false){
                    [unowned self] result in
                    if !result {
                        self.powerState = .on
                    }
                }
            }
        case .unknown:
            // TODO: should be implement sending toggle power command to portal
            break
        }
    }
}
