//
//  WSProtocols.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/10/01.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

let WSP_TYPE_NAME = "_wakeserver._tcp."

//-----------------------------------------------------------------------------------------
// MARK: - object to browse service
//-----------------------------------------------------------------------------------------
public protocol WSPBrowserDelegate : AnyObject {
    func wspBrowserDetectPortalAdd(browser : WSPBrowser, portal : Portal)
    func wspBrowserDetectPortalDel(browser : WSPBrowser, portal : Portal)
    func wspBrowserDidNotSearch(browser : WSPBrowser, errorDict: [String : NSNumber])
}

open class WSPBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let browser : NetServiceBrowser = NetServiceBrowser()
    private var resolvingServices : [NetService] = []
    private var stoppingServices : [NetService] = []
    private var portals : [(NetService, Portal)] = []
    
    open weak var delegate : WSPBrowserDelegate?
    
    public override init() {
        super.init()
        browser.delegate = self
    }
    
    deinit {
        stop()
    }
    
    open func start() {
        browser.searchForServices(ofType: WSP_TYPE_NAME, inDomain: "")
    }
    
    open func stop() {
        browser.stop()
        for service in resolvingServices {
            stoppingServices.append(service)
            service.delegate = self
            service.stop()
        }
        resolvingServices.removeAll()
    }

    //-----------------------------------------------------------------------------------------
    // Delegate methods for NetServiceBrowser
    //-----------------------------------------------------------------------------------------
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if resolvingServices.index(where:{$0 === service}) == nil {
            resolvingServices.append(service)
            service.delegate = self
            service.resolve(withTimeout: 0)
        }
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = resolvingServices.index(where: {$0 === service}){
            resolvingServices.remove(at: index)
            stoppingServices.append(service)
            service.delegate = self
            service.stop()
        }else if let index = portals.index(where:{$0.0 === service}) {
            let portal = portals[index]
            portals.remove(at: index)
            delegate?.wspBrowserDetectPortalDel(browser: self, portal: portal.1)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        delegate?.wspBrowserDidNotSearch(browser: self, errorDict: errorDict)
    }

    //-----------------------------------------------------------------------------------------
    // Delegate methods for NetService
    //-----------------------------------------------------------------------------------------
    public func netServiceDidResolveAddress(_ service: NetService) {
        if let index = resolvingServices.index(where:{$0 === service}) {
            resolvingServices.remove(at: index)
            service.delegate = nil
            service.stop()
            let portal = (service, Portal(service: service))
            portals.append(portal)
            delegate?.wspBrowserDetectPortalAdd(browser: self, portal: portal.1)
        }
    }
    
    public func netServiceDidStop(_ service: NetService) {
        if let index = stoppingServices.index(where: {$0 === service}){
            stoppingServices.remove(at: index)
        }
    }

}

