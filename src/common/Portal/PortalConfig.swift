//
//  PortalConfig.swift
//  commonLib
//
//  Created by opiopan on 2017/10/12.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

public enum PortalConfigError : Error {
    case serverAccessFailed(String)
    case invalidFormat(String)
    case partialyInconsistentData(String)
    case otherError(String)
}

open class PortalConfig : LooseSerializable{
    open class TVChannel : LooseSerializable{
        open let name : String
        open let description : String
        
        init(){name = ""; description = ""}

        public required init(dict: [String : Any]) throws {
            if let name = dict["name"] as? String, let description = dict["description"] as? String {
                self.name = name
                self.description = description
            }else{
                self.name = ""
                self.description = ""
            }
        }
        
        public var dictionary: [String : Any] {
            get {return ["name" : name, "description" : description]}
        }
    }
    
    open let pages : [PortalAccessory]
    open let tvchannels : [TVChannel]
    open let background: String?

    //-----------------------------------------------------------------------------------------
    // MARK: - Initializing / Serializing / Deserializing
    //-----------------------------------------------------------------------------------------
    public convenience init (_ data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let config = json as? [String : Any] else {
            throw PortalConfigError.invalidFormat("MSG_ERR_PERSE_CONFIG")
        }
        
        try self.init(dict: config)
    }

    public required init(dict: [String : Any]) throws {
        guard let nativeApp = dict["nativeApp"] as? [String:Any],
              let pages = nativeApp["pages"] as? [Any],
              pages.count > 0 else {
                throw PortalConfigError.invalidFormat("MSG_ERR_NO_NATIVE_APP")
        }

        self.pages = pages.map{
            do {
                guard let dict = $0 as? [String:Any],
                      let type = dict["type"] as? String,
                      let create = portalAccessories[type]?.create else{
                        return PortalAccessory()
                }
                return try create(dict)
            }catch{
                return PortalAccessory()
            }
        }.filter{$0.type != ""}
        
        guard self.pages.count > 0 else {
            throw PortalConfigError.invalidFormat("MSG_ERR_NO_NATIVE_APP")
        }
        
        if let tvchannels = dict["tvchannels"] as? [Any] {
            self.tvchannels = tvchannels.map{
                guard let tvchannel = $0 as? [String:Any] else {
                    return TVChannel()
                }
                return try! TVChannel(dict: tvchannel)
            }.filter{$0.name != ""}
        }else{
            tvchannels = []
        }
        
        self.background = dict["background"] as? String
    }

    public var dictionary: [String : Any]{
        get{
            var dict : [String : Any] = [
                "nativeApp": [
                    "pages": pages.map{$0.dictionary},
                ],
                "tvchannels": tvchannels.map{$0.dictionary}
            ]
            
            if let value = background {
                dict["background"] = value
            }
            
            return dict
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Reflecting servers.config
    //-----------------------------------------------------------------------------------------
    open func reflectServersConfig(_ data: Data) throws {
        let root = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [Any]
        
        var serverIndexContext = 0
        let serverIndex : ()->Int = {let rc = serverIndexContext; serverIndexContext += 1; return rc}
        
        let enumlateServer = {
            (callback : (Int, [String : Any]) throws -> Void) in
            try root.forEach{
                if let dict = $0 as? [String: Any] {
                    if let servers = dict["servers"] as? [Any]  {
                        try servers.forEach{
                            if let dict = $0 as? [String:Any]{
                                try callback(serverIndex(), dict)
                            }
                        }
                    }else{
                        try callback(serverIndex(), dict)
                    }
                }
            }
        }
        
        var servers : [String : ServerDefinition] = [:]
        try enumlateServer(){
            index, dict in
            do {
                let server = try ServerDefinition(index: index, dict: dict)
                servers[server.name] = server
            }catch PortalConfigError.partialyInconsistentData(_) {
            }
        }
        
        pages.forEach{$0.reflectServerConfig(servers: servers)}
    }
}
