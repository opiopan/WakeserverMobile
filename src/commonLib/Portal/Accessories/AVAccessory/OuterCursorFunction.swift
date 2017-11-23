//
//  OuterCursorFunction.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class OuterCursorFunction : AVFunction {
    public enum Kind : String {
        case equallyDivided = "equally-divided"
        case cursorAnd4Segments = "cursor+4segment"
    }
    
    public var kind : Kind = .equallyDivided
    public var begin : CGFloat = 0
    public var end: CGFloat = 0
    public var aux: [Button] = []

    public required init(type: String, server: String) {
        super.init(type: type, server: server)
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        kind = Kind(rawValue: dict["kind"] as! String)!
        begin = dict["begin"] as! CGFloat
        end = dict["end"] as! CGFloat
        aux = (dict["aux"] as! [[String : Any]]).map{try! Button(dict:$0)}
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            dict["kind"] = kind.rawValue
            dict["begin"] = begin
            dict["end"] = end
            dict["aux"] = aux.map{$0.dictionary}
            return dict
        }
    }
    
    override open func refrectOption(option: [String : Any]) {
        super.refrectOption(option: option)
        
        if let type = option["type"] as? String, let kind = Kind(rawValue: type) {
            self.kind = kind
        }
        if let begin = option["begin"] as? CGFloat {
            self.begin = begin
        }
        if let end = option["end"] as? CGFloat {
            self.end = end
        }
        if let auxs = option["aux"] as? [Any] {
            auxs.forEach{
                if let aux = $0 as? [String : Any],
                    let label = aux["label"] as? String,
                    let value = aux["value"] as? String {
                    self.aux.append(Button(label: label, attribute: .aux, value: value))
                }
            }
        }
    }
    
    override open var isAvailable: Bool {
        get {
            return super.isAvailable && (aux.count > 0 || kind == .cursorAnd4Segments)
        }
    }
}
