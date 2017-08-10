//
//  AuxFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class AuxFunction : AVFunction {
    public var functions : [Button] = []

    public required init(type: String, server: String) {
        super.init(type: type, server: server)
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        functions = (dict["functions"] as! [[String : Any]]).map{try! Button(dict:$0)}
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            dict["functions"] = functions.map{$0.dictionary}
            return dict
        }
    }
    
    override open func refrectOption(option: [String : Any]) {
        super.refrectOption(option: option)
        
        if let functions = option["functions"] as? [Any] {
            functions.forEach{
                if let function = $0 as? [String : Any],
                    let label = function["label"] as? String,
                    let value = function["value"] as? String {
                    self.functions.append(Button(label: label, attribute: .aux, value: value))
                }
            }
        }
    }
    
    override open var isAvailable: Bool {
        get {
            return super.isAvailable && functions.count > 0
        }
    }

}
