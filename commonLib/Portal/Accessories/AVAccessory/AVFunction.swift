//
//  AVFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class AVFunction : LooseSerializable {
    public enum AttributeType : String {
        case volume = "volume"
        case volumeRelative = "volumerelative"
        case tvChannel = "tvchannel"
        case tvChannelName = "tvchannelname"
        case player = "player"
        case aux = "aux"
    }
    
    public class Button : LooseSerializable{
        let label : String
        let attribute : AttributeType
        let value : String
        
        init(label: String, attribute: AttributeType, value: String){
            self.label = label
            self.attribute = attribute
            self.value = value
        }
        
        public required init(dict: [String : Any]) throws {
            label = dict["label"] as! String
            attribute = AttributeType(rawValue: dict["attribute"] as! String)!
            value = dict["value"] as! String
        }
        
        public var dictionary: [String : Any] {
            get{
                return [
                    "label" : label,
                    "attribute" : attribute.rawValue,
                    "value" : value,
                ]
            }
        }
        
    }
    
    let type: String
    let server: String
    
    public required init (type: String, server: String) {
        self.type = type
        self.server = server
    }
    
    public required init(dict: [String : Any]) throws {
        type = dict["type"] as! String
        server = dict["server"] as! String
    }
    
    public var dictionary: [String : Any] {
        get {
            return [
                "type": type,
                "server": server
            ]
        }
    }

    open func refrectOption(option: [String: Any]) {
    }
    
    open var isAvailable : Bool {
        get {
            return true
        }
    }
}

