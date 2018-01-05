//
//  Communicator.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/12/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLib

class Communicator : IPCDelegate {
    init() {
        IPC.session.delegate = self
        IPC.session.start()
    }
    
    func start() {
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - send commands
    //-----------------------------------------------------------------------------------------
    func sendComplicationData(_ data: ComplicationData) -> IPCError? {
        guard let portal = data.place.portalObject() else {
            abort()
        }

        var message : [String:Any] = [
            IPCKeyCommand : IPCCmd.notifyComplicationUpdate.rawValue,
        ]
        
        if !portal.isOutdoors {
            message[IPCKeyPortalId] = portal.id!
        }
        if let service = portal.service {
            message[IPCKeyServiceName] = service.name
            message[IPCKeyServiceDomain] = service.domain
            message[IPCKeyServicePort] = service.port
        }
        if let value = data.accessory1Name {
            message[IPCKeyAccessory1Name] = value
        }
        if let value = data.accessory1Value {
            message[IPCKeyAccessory1Value] = value
        }
        if let value = data.accessory2Name {
            message[IPCKeyAccessory2Name] = value
        }
        if let value = data.accessory2Value {
            message[IPCKeyAccessory2Value] = value
        }
        
        let result = IPC.session.transferUserInfo(asComplication: true, whenConflict: .overrideAll, withData: message)
        
        return result.error
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - recieve commands & respond to commands
    //-----------------------------------------------------------------------------------------
    func didRecieve(command: IPCCmd, withMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)?) {
        switch command {
        case .getPosition:
            if let replyHandler = replyHandler {
                getPosition(replyHandler)
            }
        default:
            replyHandler?([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
        }
     }
    
    private var getPortalCmd : GetPortal?
    
    private func getPosition(_ replyHandler: @escaping ([String : Any]) -> Void) {
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
    }
 }

var communicator = Communicator()
