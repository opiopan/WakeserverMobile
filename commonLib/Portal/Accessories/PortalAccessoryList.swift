//
//  PortalAccessoryList.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

struct PortalAccessoryImage{
    static func preference(_ type: String) -> UIImage?{
        return libBundleImage(name: "accessory_icon_\(type)")
    }
    static func dashboard(_ type: String) -> UIImage?{
        return libBundleImage(name: "dashboard_icon_\(type)")
    }
}

open class PortalAccessoryAttribute {
    public typealias CreateClosure = ([String : Any]) throws -> PortalAccessory
    
    private static var counter = 0

    open let seqid : Int
    open let type : String
    open let typeName : String?
    open let create : CreateClosure?
    open var preferenceIcon : UIImage? {
        get {return PortalAccessoryImage.preference(type)}
    }
    open var dashboardIcon : UIImage? {
        get {return PortalAccessoryImage.dashboard(type)}
    }
    open var description : String? {
        get {return LocalizedString("ACCESSORY_DEC_" + type)}
    }

    init(type: String, typeName: String?, create: CreateClosure?){
        seqid = PortalAccessoryAttribute.counter
        PortalAccessoryAttribute.counter += 1
        self.type = type
        self.typeName = typeName
        self.create = create
    }
}

public let portalAccessories : [String : PortalAccessoryAttribute] = [
    "switch" : PortalAccessoryAttribute(
        type: "switch",
        typeName: String(describing: SwitchAccessory.self),
        create: {try SwitchAccessory(dict: $0)}),
    "lightbulb" : PortalAccessoryAttribute(
        type: "lightbulb",
        typeName: nil,
        create: nil),
    "thermometer" : PortalAccessoryAttribute(
        type: "thermometer",
        typeName: String(describing: ThermometerAccessory.self),
        create: {try ThermometerAccessory(dict: $0)}),
    "av" : PortalAccessoryAttribute(
        type: "av",
        typeName: String(describing: AVAccessory.self),
        create: {try AVAccessory(dict: $0)}),
    "storage" : PortalAccessoryAttribute(
        type: "storage",
        typeName: nil,
        create: nil),
    "server" : PortalAccessoryAttribute(
        type: "server",
        typeName: nil,
        create: nil),
    "dashboard" : PortalAccessoryAttribute(
        type: "dashboard",
        typeName: String(describing: DashboardAccessory.self),
        create: {try DashboardAccessory(dict: $0)}),
    "home" : PortalAccessoryAttribute(
        type: "home",
        typeName: nil,
        create: nil),
    "room" : PortalAccessoryAttribute(
        type: "room",
        typeName: nil,
        create: nil),
]

public let sortedPortalAccessoryTypes = portalAccessories.values.sorted{$0.seqid < $1.seqid}.map{$0.type}

public func portalAccessoryAttribute(correspondTo object: Any) -> PortalAccessoryAttribute? {
    let typeName = String(describing: type(of: object))
    let candidates = portalAccessories.values.filter{$0.typeName == typeName}
    if candidates.count > 0 {
        return candidates[0]
    }else{
        return nil
    }
}
