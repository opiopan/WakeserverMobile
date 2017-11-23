//
//  IPC.swift
//  commonLib
//
//  Created by opiopan on 2017/11/18.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import WatchConnectivity

private enum IPCCmd: Int{
    case getPosition = 1
}

public let IPCKeyCommand = "IPCKeyCmd"
public let IPCKeyResponse = "IPCKeyRsp"
public let IPCKeyPortalId = "IPCKeyPortalId"
public let IPCKeyPortalUrl = "IPCKeyIPUrl"

public enum IPCResponse : Int {
    case succeed = 0
    case protocolError
    case notSupportedFunction
}

public enum IPCError {
    case IPCError(IPCResponse)
    case OSError(Error)
}


open class IPC : NSObject, WCSessionDelegate {
    private static var sessionObject = IPC()
    
    open static var session : IPC {
        get {
            if sessionObject.wcSession == nil {
                sessionObject.startObject()
            }
            return sessionObject
        }
    }
    
    private var wcSession : WCSession?
    
    public override init(){
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - start session
    //-----------------------------------------------------------------------------------------
    open func start() {
    }
    
    private func startObject() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - send data
    //-----------------------------------------------------------------------------------------
    open func syncConfiguration() {
        if let session = wcSession, session.isReachable {
            do {
                try session.updateApplicationContext(ConfigurationController.sharedController.dictionaryRepresentation)
            }catch {
                
            }
        }
    }
    
    open func getLocation(handler: @escaping ((portalId: String?, portalUrl: String?)?, IPCError?) -> Void) {
        let sendData = [IPCKeyCommand: IPCCmd.getPosition.rawValue]
        if let session = wcSession, session.isReachable {
            session.sendMessage(sendData, replyHandler: {
                data in
                guard let resp = data[IPCKeyResponse] as? Int, let error = IPCResponse(rawValue: resp) else {
                    handler(nil, .IPCError(.protocolError))
                    return
                }
                guard error == .succeed else{
                    handler(nil, .IPCError(error))
                    return
                }
                let value = (portalId: data[IPCKeyPortalId] as? String, portalUrl: data[IPCKeyPortalUrl] as? String)
                handler(value, nil)
            }, errorHandler: {
                error in
                handler(nil, .OSError(error))
            })
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - WCSessionDelegate methods
    //-----------------------------------------------------------------------------------------
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

#if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
#endif
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        ConfigurationController.sharedController.updagteAll(with: applicationContext)
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        guard let cmdCode = message[IPCKeyCommand] as? Int, let cmd = IPCCmd(rawValue: cmdCode) else {
            replyHandler([IPCKeyResponse: IPCResponse.protocolError.rawValue])
            return
        }
        
        switch cmd {
        case .getPosition:
            #if os(iOS)
                let command = GetPortal()
                command.run{
                    portal, error in
                    guard let portal = portal, error != nil, let service = portal.service, let id = portal.id else {
                        replyHandler([IPCKeyResponse: IPCResponse.succeed])
                        return
                    }
                    let url = "http://\(service.name).\(service.domain):\(service.port)"
                    let data : [String:Any] = [
                        IPCKeyResponse: IPCResponse.succeed.rawValue,
                        IPCKeyPortalId: id,
                        IPCKeyPortalUrl: url,
                    ]
                    replyHandler(data)
                }
            #elseif os(watchOS)
                replyHandler([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
            #endif
        }
    }
}

