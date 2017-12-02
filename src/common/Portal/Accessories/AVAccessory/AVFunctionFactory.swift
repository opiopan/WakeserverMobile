//
//  AVFunctionFactory.swift
//  commonLib
//
//  Created by opiopan on 2017/10/21.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

private typealias CreateClosure = (String, String) -> AVFunction
private typealias DeserializeClosure = ([String : Any]) throws -> AVFunction

private let functionCreator : [String : CreateClosure] = [
    "volume" : {VolumeFunction(type: $0, server: $1)},
    "tvchannel" : {TVChannelFunction(type: $0, server: $1)},
    "tvchannelname" : {TVChannelNameFunction(type: $0, server: $1)},
    "player" : {PlayerFunction(type: $0, server: $1)},
    "altskip" : {AltSkipFunction(type: $0, server: $1)},
    "cursor" : {CursorFunction(type: $0, server: $1)},
    "outercursor" : {OuterCursorFunction(type: $0, server: $1)},
    "4color" : {FourColorFunction(type: $0, server: $1)},
    "aux" : {AuxFunction(type: $0, server: $1)},
]

private let functionDeserializer : [String : DeserializeClosure] = [
    "volume" : {try VolumeFunction(dict:$0)},
    "tvchannel" : {try TVChannelFunction(dict:$0)},
    "tvchannelname" : {try TVChannelNameFunction(dict:$0)},
    "player" : {try PlayerFunction(dict:$0)},
    "altskip" : {try AltSkipFunction(dict:$0)},
    "cursor" : {try CursorFunction(dict:$0)},
    "outercursor" : {try OuterCursorFunction(dict:$0)},
    "4color" : {try FourColorFunction(dict:$0)},
    "aux" : {try AuxFunction(dict:$0)},
]

func createAVFunction(type: String, server: String) -> AVFunction? {
    if let create = functionCreator[type] {
        return create(type, server)
    }else{
        return nil
    }
}

func deserializeAVFunction(dict: [String : Any]) throws -> AVFunction? {
    if let type = dict["type"] as? String,  let deserialize = functionDeserializer[type] {
        return try deserialize(dict)
    }else{
        return nil
    }
}
