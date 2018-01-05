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
    
    open var tvChannel: TVChannelFunction?
    open var tvChannelName: TVChannelNameFunction?
    open var volume: VolumeFunction?
    open var player: PlayerFunction?
    open var altSkip: AltSkipFunction?
    open var cursor: CursorFunction?
    open var outerCursor: OuterCursorFunction?
    open var fourColor: FourColorFunction?
    open var aux: AuxFunction?

    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        if let functions = dict["ios_functions"] as? [[String : Any]] {
            iosFunctions = functions.map{try! deserializeAVFunction(dict: $0)!}
        }
        if let functions = dict["watch_functions"] as? [[String : Any]] {
            watchFunctions = functions.map{try! deserializeAVFunction(dict: $0)!}
        }
        makeFunctionReferences()
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
            makeFunctionReferences()
        }
    }
    
    private func makeFunctionReferences() {
        #if os(iOS)
            let functions = iosFunctions
        #elseif os(watchOS)
            let functions = watchFunctions
        #endif
        
        functions.forEach{
            function in
            if let function = function as? VolumeFunction {
                volume = function
            }else if let function = function as? TVChannelFunction {
                tvChannel = function
            }else if let function = function as? TVChannelNameFunction {
                tvChannelName = function
            }else if let function = function as? PlayerFunction {
                player = function
            }else if let function = function as? AltSkipFunction {
                altSkip = function
            }else if let function = function as? CursorFunction {
                cursor = function
            }else if let function = function as? OuterCursorFunction {
                outerCursor = function
            }else if let function = function as? FourColorFunction {
                fourColor = function
            }else if let function = function as? AuxFunction {
                aux = function
            }
        }
    }
    
    override open func updateCharacteristicStatus(portal: Portal, notifier: (() -> Void)?) {
        if let volume = self.volume {
            volume.updateCharacteristics(portal: portal, notifier: notifier)
        }else{
            notifier?()
        }
    }
}
