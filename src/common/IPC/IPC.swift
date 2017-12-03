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
public let IPCKeyServiceName = "IPCKeyServiceName"
public let IPCKeyServiceDomain = "IPCKeyServiceDomain"
public let IPCKeyServicePort = "IPCKeyServicePort"

public enum IPCResponse : Int {
    case succeed = 0
    case unreachable
    case protocolError
    case bussy
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
    
    open func getLocation(handler: @escaping ((portalId: String?, service: (name: String, domain: String, port: Int)?)?, IPCError?) -> Void) {
        let sendData = [IPCKeyCommand: IPCCmd.getPosition.rawValue]
        guard let session = wcSession, session.isReachable else{
            print("ERROR: IPC unreachable")
            handler(nil, .IPCError(.unreachable))
            return
        }
        session.sendMessage(sendData, replyHandler: {
            data in
            guard let resp = data[IPCKeyResponse] as? Int, let error = IPCResponse(rawValue: resp) else {
                print("ERROR: IPC protocol error")
                handler(nil, .IPCError(.protocolError))
                return
            }
            guard error == .succeed else{
                print("ERROR: IPC other error")
                handler(nil, .IPCError(error))
                return
            }
            var service : (name: String, domain: String, port: Int)? = nil
            if let sname = data[IPCKeyServiceName] as? String,
                let sdomain = data[IPCKeyServiceDomain] as? String,
                let sport = data[IPCKeyServicePort] as? Int {
                service = (name: sname, domain: sdomain, port: sport)
            }
            
            let value = (portalId: data[IPCKeyPortalId] as? String, service: service)
            handler(value, nil)
        }, errorHandler: {
            error in
            print("ERROR: IPC OS error")
            handler(nil, .OSError(error))
        })
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

#if os(iOS)
    private var getPortalCmd : GetPortal?
#endif
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        guard let cmdCode = message[IPCKeyCommand] as? Int, let cmd = IPCCmd(rawValue: cmdCode) else {
            replyHandler([IPCKeyResponse: IPCResponse.protocolError.rawValue])
            return
        }
        
        switch cmd {
        case .getPosition:
            #if os(iOS)
                DispatchQueue.main.async {
                    [unowned self] in
                    guard self.getPortalCmd == nil else {
                        replyHandler([IPCKeyResponse: IPCResponse.bussy.rawValue])
                        return
                    }
                    self.getPortalCmd = GetPortal()
                    self.getPortalCmd?.run{
                        [unowned self] portal, error in
                        guard let portal = portal, error == nil, let service = portal.service, let id = portal.id else {
                            replyHandler([IPCKeyResponse: IPCResponse.succeed.rawValue])
                            self.getPortalCmd = nil
                            return
                        }
                        let data : [String:Any] = [
                            IPCKeyResponse: IPCResponse.succeed.rawValue,
                            IPCKeyPortalId: id,
                            IPCKeyServiceName: service.name,
                            IPCKeyServiceDomain: service.domain,
                            IPCKeyServicePort: service.port,
                            ]
                        replyHandler(data)
                        self.getPortalCmd = nil
                    }
                }
            #elseif os(watchOS)
                replyHandler([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
            #endif
        }
    }
}

