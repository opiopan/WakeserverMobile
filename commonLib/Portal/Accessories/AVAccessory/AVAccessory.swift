//
//  AVAccessory.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

private let iosFunctionCaps = [
    "tvchannel",
    "volume",
    "cursor",
    "outercursor",
    "4color",
    "player",
    "altskip",
    "aux",
]

private let watchFunctionCaps = [
    "tvchannelname",
    "player",
    "volume",
    "altskip",
]

open class AVAccessory : PortalAccessoryCorrespondsServer {
    var iosFunctions : [AVFunction] = []
    var watchFunctions : [AVFunction] = []

    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        if let functions = dict["ios_functions"] as? [[String : Any]] {
            iosFunctions = functions.map{try! deserializeAVFunction(dict: $0)!}
        }
        if let functions = dict["watch_functions"] as? [[String : Any]] {
            watchFunctions = functions.map{try! deserializeAVFunction(dict: $0)!}
        }
    }
    
    override public var dictionary: [String : Any] {
        get{
            var dict = super.dictionary
            dict["ios_functions"] = iosFunctions.map{$0.dictionary}
            dict["watch_functions"] = watchFunctions.map{$0.dictionary}
            return dict
        }
    }
    
    override func reflectServerConfig(servers : [String : ServerDefinition]) {
        super.reflectServerConfig(servers: servers)
        if let serverName = self.server, let serverDef = servers[serverName]{
            let createFunctionList = {(caps: [String]) -> [AVFunction] in
                var list : [AVFunction] = []
                caps.forEach{
                    if let server = serverDef.schemes[$0], let function = createAVFunction(type: $0, server: server){
                        list.append(function)
                    }
                }
                var excludeList : [String : Bool] = [:]
                list.forEach{
                    if let option = serverDef.schemeOptions[$0.type] as? [String : Any]{
                        $0.refrectOption(option: option)
                        if let target = option["override"] as? String {
                            excludeList[target] = true
                        }
                    }
                }
                return list.filter{$0.isAvailable && excludeList[$0.type] == nil}
            }
            iosFunctions = createFunctionList(iosFunctionCaps)
            watchFunctions = createFunctionList(watchFunctionCaps)
        }
    }
}
