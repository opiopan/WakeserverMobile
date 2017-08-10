//
//  HomeKitSupport.swift
//  commonLib
//
//  Created by opiopan on 2017/11/09.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import HomeKit

public enum HomeKitServiceType : String {
    case switchService = "_switch"
    case temperatureService = "_thermometer"
    case lightbulbService = "_lightbulb"
}

private let supportedServices : [String : HomeKitServiceType] = [
    HMServiceTypeSwitch : .switchService,
    HMServiceTypeTemperatureSensor : .temperatureService,
    HMServiceTypeLightbulb : .lightbulbService,
]

open class HomeKitManager : NSObject, HMHomeManagerDelegate {
    public typealias Notifier = (HomeKitManager) -> Void

    open static var sharedManager = HomeKitManager()
    
    private let manager : HMHomeManager
    private var isInitialized = false
    private var notifierForInitialize = [Notifier]()
    
    override init() {
        manager = HMHomeManager()
        super.init()
        manager.delegate = self
    }
    
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager){
        isInitialized = true
        let closures = notifierForInitialize
        notifierForInitialize = [Notifier]()
        closures.forEach{$0(self)}
    }
    
    open func waitForInitialize(notifier: @escaping Notifier){
        if isInitialized {
            notifier(self)
        }else{
            notifierForInitialize.append(notifier)
        }
    }
    
    open var homes : [HMHome] {
        get{
            return manager.homes
        }
    }

    open func serviceAndReleatedObjects(homeId: String, accessoryId: String, serviceId: String)
        -> (home: HMHome, accessory: HMAccessory, service: HMService)? {
            guard let homeIndex = manager.homes.index(where: {$0.uniqueIdentifier.uuidString == homeId}) else {
                return nil
            }
            let home = manager.homes[homeIndex]
            guard let accessoryIndex = home.accessories.index(where: {$0.uniqueIdentifier.uuidString == accessoryId}) else {
                return nil
            }
            let accessory = home.accessories[accessoryIndex]
            guard let serviceIndex = accessory.services.index(where: {$0.uniqueIdentifier.uuidString == serviceId}) else {
                return nil
            }
            let service = accessory.services[serviceIndex]
            
            return (home, accessory, service)
    }
}

open class HomeKitNode{
    public enum NodeType : Int {
        case root = 1
        case home
        case zone
        case room
        case accessory
    }

    open let nodeType : NodeType
    open let nodeId : String
    open let children : [HomeKitNode]
    open var nodeName : String?
    open var homeId : String?
    open var home : HMHome?
    open var accessory : HMAccessory?
    open var service : HMService?
    
    init(type: NodeType, nodeId: String, children: [HomeKitNode]) {
        self.nodeType = type
        self.nodeId = nodeId
        self.children = children
    }
    
    open func portalAccessory() -> PortalAccessory? {
        var newacc : PortalAccessory? = nil
        if service?.serviceType == HMServiceTypeTemperatureSensor {
            newacc = ThermometerAccessory()
        }else if service?.characteristics.index(where: {$0.characteristicType == HMCharacteristicTypePowerState}) != nil {
            newacc = SwitchAccessory()
        }
        newacc?.reflectTypeInformation()
        if let service = service {newacc?.name = service.name}
        newacc?.hmHomeId = homeId
        newacc?.hmAccessoryId = accessory?.uniqueIdentifier.uuidString
        newacc?.hmServiceId = service?.uniqueIdentifier.uuidString
        newacc?.hmHome = home
        newacc?.hmService = service
        return newacc
    }
}

open class HomeKitNodeManager : NSObject {
    public typealias InitializedNotifier = (HomeKitNodeManager) -> Void
    
    private var notifier : InitializedNotifier?
    
    public init(notifier: InitializedNotifier?){
        self.notifier = notifier
        super.init()
        HomeKitManager.sharedManager.waitForInitialize{
            [unowned self] _ in
            self.notifier?(self)
            self.notifier = nil
        }
    }

    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager){
        notifier?(self)
    }
    
    open func homes() -> HomeKitNode {
        let children = HomeKitManager.sharedManager.homes.map{homeNode($0)}.filter{$0.children.count > 0}
        let homes = HomeKitNode(type: .root, nodeId: "", children: children)
        homes.nodeName = LocalizedString("HOMES_NAME")
        return homes
    }
    
    private func homeNode(_ home: HMHome) -> HomeKitNode {
        let homeId = home.uniqueIdentifier.uuidString
        var children = [HomeKitNode]()
        if home.zones.count > 0 {
            children = home.zones.map{zoneNode(zone: $0, home: home)}.filter{$0.children.count > 0}
            let others = home.rooms.filter{room in
                return children.map{$0.children}.flatMap{$0}.filter{$0.nodeName == room.name}.count == 0
            }
            let otherChildren = others.map{roomNode(room: $0, home: home)}.filter{$0.children.count > 0}
            if otherChildren.count > 0 {
                let otherRoom = HomeKitNode(type: .zone, nodeId: "", children: otherChildren)
                otherRoom.nodeName = LocalizedString("ZONE_NAME_FOR_OTHERS")
                children.append(otherRoom)
            }
        }else{
            children = home.rooms.map{roomNode(room: $0, home: home)}.filter{$0.children.count > 0}
        }
        let homeNode = HomeKitNode(type: .home, nodeId: home.uniqueIdentifier.uuidString, children: children)
        homeNode.nodeName = home.name
        homeNode.homeId = homeId
        homeNode.home = home
        return homeNode
    }
    
    private func zoneNode(zone: HMZone, home: HMHome) -> HomeKitNode {
        let children = zone.rooms.map{roomNode(room: $0, home: home)}.filter{$0.children.count > 0}
        let zoneNode = HomeKitNode(type: .zone, nodeId: zone.uniqueIdentifier.uuidString, children: children)
        zoneNode.nodeName = zone.name
        zoneNode.homeId = home.uniqueIdentifier.uuidString
        zoneNode.home = home
        return zoneNode
    }

    private func roomNode(room: HMRoom, home: HMHome) -> HomeKitNode {
        let children = room.accessories.map{accessoryNode(accessory: $0, home: home)}.flatMap{$0}
        let roomNode = HomeKitNode(type: .room, nodeId: room.uniqueIdentifier.uuidString, children: children)
        roomNode.nodeName = room.name
        roomNode.homeId = home.uniqueIdentifier.uuidString
        roomNode.home = home
        return roomNode
    }

    private func accessoryNode(accessory: HMAccessory, home: HMHome) -> [HomeKitNode] {
        return accessory.services.flatMap{service in
            if let _ = supportedServices[service.serviceType] {
                let accessoryNode = HomeKitNode(type: .accessory,
                                                nodeId: accessory.uniqueIdentifier.uuidString,
                                                children: [])
                accessoryNode.nodeName = service.name
                accessoryNode.homeId = home.uniqueIdentifier.uuidString
                accessoryNode.home = home
                accessoryNode.accessory = accessory
                accessoryNode.service = service
                return accessoryNode
            }else{
                return nil
            }
        }
    }
}
