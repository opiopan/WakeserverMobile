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

    //-----------------------------------------------------------------------------------------
    // MARK: - background communication context management
    //-----------------------------------------------------------------------------------------
    private var backgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()
    
    func registerBackgroundTask(_ task: WKWatchConnectivityRefreshBackgroundTask){
        backgroundTasks.append(task)
    }
    
    func removeAllBackgroundTask(){
        backgroundTasks.forEach{$0.setTaskCompletedWithSnapshot(false)}
        backgroundTasks.removeAll()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - send commands
    //-----------------------------------------------------------------------------------------
    func getLocation(handler: @escaping (PlaceRecognizer.PortalRepresentation?, IPCError?) -> Void) {
        let sendData = [IPCKeyCommand: IPCCmd.getPosition.rawValue]
        IPC.session.sendMessage(sendData){
            [unowned self] data, error in
            guard error == nil, let data = data else {
                handler(nil, error)
                return
            }
            handler(self.retrievePortalRepresentation(fromMessage: data), nil)
        }
    }

    func loadPortalConfig(handler: @escaping (IPCError?) -> Void) {
        let sendData = [IPCKeyCommand: IPCCmd.getPortalConfig.rawValue]
        IPC.session.sendMessage(sendData){
            data, error in
            guard error == nil, let data = data else {
                handler(error)
                return
            }
            if let config = data[IPCKeyPortalConfig] as? [String: Any] {
                ConfigurationController.sharedController.updagteAll(with: config)
            }
            handler(nil)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - recieve commands & respond to commands
    //-----------------------------------------------------------------------------------------
    func didRecieve(command: IPCCmd, withMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)?) {
        switch command {
        case .notifyComplicationUpdate:
            reviceveComplicationUpdate(message)
        default:
            replyHandler?([IPCKeyResponse: IPCResponse.notSupportedFunction.rawValue])
        }
    }
    
    private func reviceveComplicationUpdate(_ data: [String:Any]) {
        let portal = retrievePortalRepresentation(fromMessage: data)
        placeRecognizer.setPlace(withPortal: portal)
        complicationDatastore.update(withAccessoriesInMessage: data)
        removeAllBackgroundTask()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - utilities
    //-----------------------------------------------------------------------------------------
    private func retrievePortalRepresentation(fromMessage data: [String:Any]) -> PlaceRecognizer.PortalRepresentation {
        var service : (name: String, domain: String, port: Int)? = nil
        if let sname = data[IPCKeyServiceName] as? String,
            let sdomain = data[IPCKeyServiceDomain] as? String,
            let sport = data[IPCKeyServicePort] as? Int {
            service = (name: sname, domain: sdomain, port: sport)
        }
        return (portalId: data[IPCKeyPortalId] as? String, service: service)
    }
}

var communicator = Communicator()
