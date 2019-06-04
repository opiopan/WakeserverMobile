//
//  IPC.swift
//  commonLib
//
//  Created by opiopan on 2017/11/18.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import WatchConnectivity

public enum IPCCmd: Int{
    case getPosition = 1
    case getComplicationData
    case notifyComplicationUpdate
    case getPortalConfig
}

public let IPCKeyCommand = "IPCKeyCmd"
public let IPCKeyResponse = "IPCKeyRsp"
public let IPCKeyPortalId = "IPCKeyPortalId"
public let IPCKeyPortalUrl = "IPCKeyIPUrl"
public let IPCKeyServersHash = "IPCKeyServersHash"
public let IPCKeyConfigHash = "IPCKeyConfigHash"
public let IPCKeyServiceName = "IPCKeyServiceName"
public let IPCKeyServiceDomain = "IPCKeyServiceDomain"
public let IPCKeyServicePort = "IPCKeyServicePort"
public let IPCKeyAccessory1Name = "IPCKeyAccessory1Name"
public let IPCKeyAccessory1Value = "IPCKeyAccessory1Value"
public let IPCKeyAccessory2Name = "IPCKeyAccessory2Name"
public let IPCKeyAccessory2Value = "IPCKeyAccessory2Value"
public let IPCKeyAccessory3Name = "IPCKeyAccessory3Name"
public let IPCKeyAccessory3Value = "IPCKeyAccessory3Value"
public let IPCKeyAccessory4Name = "IPCKeyAccessory4Name"
public let IPCKeyAccessory4Value = "IPCKeyAccessory4Value"
public let IPCKeyPortalConfig = "IPCKeyPortalConfig"

public enum IPCResponse : Int {
    case succeed = 0
    case unreachable
    case protocolError
    case bussy
    case notSupportedFunction
    
    public func description() -> String {
        switch self {
        case .succeed:
            return "succeed"
        case .unreachable:
            return "unreachable"
        case .protocolError:
            return "protocol error"
        case .bussy:
            return "busy"
        case .notSupportedFunction:
            return "not supported"
        }
    }
}

public enum IPCError {
    case IPCError(IPCResponse)
    case OSError(Error)
    
    public func description() -> String {
        switch self {
        case .IPCError(let resp):
            return resp.description()
        case .OSError(let error):
            return error.localizedDescription
        }
    }
}

public protocol IPCDelegate {
    func didRecieve(command: IPCCmd, withMessage message: [String: Any], replyHandler: (([String : Any]) -> Void)?)
}

open class IPC : NSObject, WCSessionDelegate {
    private static var sessionObject = IPC()
    
    public static var session : IPC {
        get {
            if sessionObject.wcSession == nil {
                sessionObject.startObject()
            }
            return sessionObject
        }
    }

    private var wcSession : WCSession?
    
    open var delegate : IPCDelegate?
    
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
        }else{
            print("ERROR: IPC cannot start due to unsupported environment")
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - send data
    //-----------------------------------------------------------------------------------------
    open func sendMessage(_ sendData: [String:Any], handler: @escaping ([String : Any]?, IPCError?)->Void) {
        guard let session = wcSession, session.isReachable else{
            print("ERROR: IPC unreachable")
            handler(nil, .IPCError(.unreachable))
            return
        }
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
            handler(data, nil)
        }, errorHandler: {
            error in
            handler(nil, .OSError(error))
        })
    }
    
    public typealias TransferResult = (result: WCSessionUserInfoTransfer?, error: IPCError?)
    public enum ConflictBehavior {
        case alwaysSend
        case cancelAll
        case cancelSame
        case cancelOther
        case overrideAll
        case overrideSame
        case overrideOther
    }
    open func transferUserInfo(asComplication: Bool, whenConflict conflictBehavior: ConflictBehavior,
                               withData data: [String:Any]) -> TransferResult {
        guard let session = wcSession, session.isReachable else{
            return (result: nil, error: .IPCError(.unreachable))
        }
        guard let command = data[IPCKeyCommand] as? Int else {
            return (result: nil, error: .IPCError(.protocolError))
        }
        #if os(watchOS)
            guard !asComplication else {
                abort()
            }
        #endif

        if conflictBehavior != .alwaysSend {
            var conflictType: Bool?
            if conflictBehavior == .cancelSame || conflictBehavior == .overrideSame {
                conflictType = asComplication
            }else if conflictBehavior == .cancelOther || conflictBehavior == .overrideOther {
                conflictType = !asComplication
            }
            let conflicts = session.outstandingUserInfoTransfers.filter{
                if $0.isTransferring, let dcmd = $0.userInfo[IPCKeyCommand] as? Int, dcmd == command {
                    if let conflictType = conflictType {
                        #if os(watchOS)
                            return !conflictType
                        #else
                            return $0.isCurrentComplicationInfo == conflictType
                        #endif
                    }else{
                        return true
                    }
                }else{
                    return false
                }
            }
            if conflictBehavior == .cancelAll || conflictBehavior == .cancelSame || conflictBehavior == .cancelOther {
                return (result: nil, error: .IPCError(.bussy))
            }else{
                conflicts.forEach{$0.cancel()}
            }
        }
        
        var result: WCSessionUserInfoTransfer?
        if asComplication {
            #if os(watchOS)
                abort()
            #else
                result = session.transferCurrentComplicationUserInfo(data)
            #endif
        }else{
            result = session.transferUserInfo(data)
        }
        
        return (result:result, error:nil)
    }
    
    open func syncConfiguration() {
        if let session = wcSession, session.isReachable {
            do {
                try session.updateApplicationContext(ConfigurationController.sharedController.dictionaryRepresentation)
            }catch {
                
            }
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
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any],
                        replyHandler: @escaping ([String : Any]) -> Void) {
        guard let cmdCode = message[IPCKeyCommand] as? Int, let cmd = IPCCmd(rawValue: cmdCode) else {
            replyHandler([IPCKeyResponse: IPCResponse.protocolError.rawValue])
            return
        }
        
        if let delegate = delegate {
            delegate.didRecieve(command: cmd, withMessage: message, replyHandler: replyHandler)
        }else{
            replyHandler([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
        }
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let cmdCode = userInfo[IPCKeyCommand] as? Int, let cmd = IPCCmd(rawValue: cmdCode) else {
            return
        }

        delegate?.didRecieve(command: cmd, withMessage: userInfo, replyHandler: nil)
    }
}

