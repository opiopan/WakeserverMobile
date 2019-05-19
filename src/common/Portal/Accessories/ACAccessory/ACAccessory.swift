//
//  ACAccessory.swift
//  WakeserverMobile
//
//  Created by Hiroshi Murayama on 2018/12/01.
//  Copyright © 2018 opiopan. All rights reserved.
//

import Foundation

enum ACFunctionType: String{
    case mode = "ac-mode"
    case temperature = "ac-temp"
}

private struct FunctionDef{
    typealias CreateClosure = ([String : Any]) throws -> PortalAccessory
    let type: ACFunctionType
    let create: CreateClosure
    init(type: ACFunctionType, create: @escaping CreateClosure){
        self.type = type
        self.create = create
    }
}
/*
private let fucntionDefs: [ACFunctionType: FunctionDef] = [
    .mode: FunctionDef(type: .mode, create: {try ACModeFunction($0)}),
    .temperature: FunctionDef(type: .temperature, create: nil),
]

open class ACAccessory : PortalAccessoryCorrespondsServer {
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            return dict
        }
    }
    
    override func reflectServerConfig(servers : [String : ServerDefinition]) {
        super.reflectServerConfig(servers: servers)
        if let serverName = self.server, let serverDef = servers[serverName]{
        }
    }

    override open func updateCharacteristicStatus(portal: Portal, notifier: (() -> Void)?) {
        notifier?()
    }
}
*/
