//
//  Commuticator.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLibWatch

class Communicator : IPCDelegate {
    init() {
        IPC.session.delegate = self
        IPC.session.start()
    }
    
    func start(){
    }
    
    open func getLocation(handler: @escaping ((portalId: String?, service: (name: String, domain: String, port: Int)?)?, IPCError?) -> Void) {
        let sendData = [IPCKeyCommand: IPCCmd.getPosition.rawValue]
        IPC.session.sendMessage(sendData){
            data, error in
            guard error == nil else {
                handler(nil, error)
                return
            }
            var service : (name: String, domain: String, port: Int)? = nil
            if let sname = data?[IPCKeyServiceName] as? String,
                let sdomain = data?[IPCKeyServiceDomain] as? String,
                let sport = data?[IPCKeyServicePort] as? Int {
                service = (name: sname, domain: sdomain, port: sport)
            }
            
            let value = (portalId: data?[IPCKeyPortalId] as? String, service: service)
            handler(value, nil)
        }
    }

    func didRecieve(command: IPCCmd, withMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)?) {
        switch command {
        default:
            replyHandler?([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
        }
    }
}

var communicator = Communicator()
