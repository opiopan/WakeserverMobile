//
//  ServerDefinition.swift
//  commonLib
//
//  Created by opiopan on 2017/10/15.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

class ServerDefinition : LooseSerializable{
    let name : String
    let index : Int
    
    let ipaddr : String?
    let macaddr : String?
    let maker : String?
    let comment : String?
    
    let isDiagnosable : Bool
    let isWakeable : Bool
    let isSleepable : Bool
    let isRebootable : Bool

    let schemes : [String : String]
    let schemeOptions : [String : Any]

    init(index: Int, dict: [String : Any]) throws {
        guard let name = dict["name"] as? String else {
            throw PortalConfigError.partialyInconsistentData(LocalizedString("MSG_ERR_NO_NAME_IN_SERVER"))
        }
        self.name = name
        self.index = index
        
        if let value = dict["ipaddr"] as? String {ipaddr = value} else {ipaddr = nil}
        if let value = dict["macaddr"] as? String {macaddr = value} else {macaddr = nil}
        if let value = dict["maker"] as? String {maker = value} else {maker = nil}
        if let value = dict["comment"] as? String {comment = value} else {comment = nil}

        if let scheme = dict["scheme"] as? [String : Any] {
            isDiagnosable = scheme["diag"] != nil
            isWakeable = scheme["on"] != nil
            isSleepable = scheme["off"] != nil
            isRebootable = scheme["reboot"] != nil

            let exclusion : [String : Any?] = [
                "type" : nil,
                "user" : nil,
                "ruser-off" : nil,
                "diag" : nil,
                "on" : nil,
                "off" : nil,
                "reboot" : nil,
                "services" : nil,
            ]

            let own = self.name
            
            schemes = scheme.filter{exclusion[$0.key] == nil}.reduce([:] as [String:String]){
                if let type = $1.value as? String {
                    let target = type.hasPrefix("relay:") ?
                                 String(type.suffix(type.count - 6)) : own
                    var dict = $0
                    dict[$1.key] = target
                    return dict
                }else{
                    return $0
                }
            }
            
            if let schemeOptions = dict["scheme-option"] as? [String : Any] {
                self.schemeOptions = schemeOptions
            }else{
                self.schemeOptions = [:]
            }
        }else{
            isDiagnosable = false
            isWakeable = false
            isSleepable = false
            isRebootable = false
            schemes = [:]
            schemeOptions = [:]
        }
    }
    
    required init(dict: [String : Any]) throws {
        name = dict["name"] as! String
        index = dict["index"] as! Int

        if let value = dict["ipaddr"] as? String {ipaddr = value} else {ipaddr = nil}
        if let value = dict["macaddr"] as? String {macaddr = value} else {macaddr = nil}
        if let value = dict["maker"] as? String {maker = value} else {maker = nil}
        if let value = dict["comment"] as? String {comment = value} else {comment = nil}
        
        isDiagnosable = dict["is_diagnosable"] as! Bool
        isWakeable = dict["is_wakeable"] as! Bool
        isSleepable = dict["is_sleepable"] as! Bool
        isRebootable = dict["is_rebootable"] as! Bool
        
        schemes = dict["schemes"] as! [String:String]
        schemeOptions = dict["scheme_options"] as! [String:Any]
    }
    
    var dictionary: [String : Any]{
        get {
            var dict : [String:Any] = [
                "name" : name,
                "index" : index,
                "is_diagnosable" : isDiagnosable,
                "is_wakeable" : isWakeable,
                "is_sleepable" : isSleepable,
                "is_rebootable" : isRebootable,
                "schemes" : schemes,
                "scheme_options" : schemeOptions,
            ]

            if let value = ipaddr {dict["ipaddr"] = value}
            if let value = macaddr {dict["macaddr"] = value}
            if let value = maker {dict["maker"] = value}
            if let value = comment {dict["comment"] = value}
            
            return dict
        }
    }
    
}
