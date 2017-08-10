//
//  CursorFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class CursorFunction : AVFunction {
    public enum Shape : String {
        case square = "square"
        case circle = "circle"
    }
    
    var shape : Shape = .circle
    var center : Button? = nil

    public required init(type: String, server: String) {
        super.init(type: type, server: server)
    }

    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        shape = Shape(rawValue: dict["shape"] as! String)!
        if let center = dict["center"] as? [String : Any] {
            self.center = try Button(dict: center)
        }
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            dict["shape"] = shape.rawValue
            if center != nil {
                dict["center"] = center?.dictionary
            }
            return dict
        }
    }
    
    override open func refrectOption(option: [String : Any]) {
        super.refrectOption(option: option)
        if let strValue = option["shape"] as? String, let shape = Shape(rawValue: strValue) {
            self.shape = shape
        }
        if let center = option["center"] as? [String : Any],
            let label = center["label"] as? String,
            let value = center["value"] as? String {
                self.center = Button(label: label, attribute: .aux, value: value)
        }
    }
}
