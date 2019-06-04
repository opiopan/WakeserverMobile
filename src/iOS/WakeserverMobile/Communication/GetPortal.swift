//
//  GetPortal.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/19.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLib

open class GetPortal : WSPBrowserDelegate{
    public typealias ResultHandler = (Portal?, [String : NSNumber]?) -> Void
    private var handler : ResultHandler?
    private let browser : WSPBrowser
    private var timer : Timer?
    
    public init() {
        browser = WSPBrowser()
        browser.delegate = self
    }
    
    open func run(_ handler: @escaping ResultHandler){
        self.handler = handler
        self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false){
            [unowned self] _ in
            self.stop()
            let handler = self.handler
            self.handler = nil
            handler?(nil, nil)
        }
        browser.start()
    }
    
    private func stop() {
        browser.stop()
        timer?.invalidate()
        timer = nil
    }
    
    public func wspBrowserDetectPortalAdd(browser: WSPBrowser, portal: Portal) {
        let portals = ConfigurationController.sharedController.registeredPortals
        guard let index = portals.firstIndex(where:{$0.id == portal.id}) else {
            return
        }
        stop()
        let handler = self.handler
        self.handler = nil
        let target = portals[index]
        if target.service == nil {
            target.service = portal.service
        }
        handler?(target, nil)
    }
    
    public func wspBrowserDetectPortalDel(browser: WSPBrowser, portal: Portal) {
    }
    
    public func wspBrowserDidNotSearch(browser: WSPBrowser, errorDict: [String : NSNumber]) {
        stop()
        handler?(nil, errorDict)
    }
}
