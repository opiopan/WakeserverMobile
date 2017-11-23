//
//  GetPortal.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/19.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

class GetPortal : WSPBrowserDelegate{
    typealias ResultHandler = (Portal?, [String : NSNumber]?) -> Void
    private var handler : ResultHandler?
    private let browser : WSPBrowser
    private var timer : Timer?
    
    init() {
        self.browser = WSPBrowser()
    }
    
    func run(_ handler: @escaping ResultHandler){
        self.handler = handler
        self.timer = Timer(timeInterval: 2, repeats: false){
            [unowned self] _ in
            self.stop()
            self.handler?(nil, nil)
            self.handler = nil
        }
        browser.start()
    }
    
    private func stop() {
        browser.stop()
        timer?.invalidate()
        timer = nil
    }
    
    func wspBrowserDetectPortalAdd(browser: WSPBrowser, portal: Portal) {
        guard ConfigurationController.sharedController.registeredPortals.index(where:{$0.id == portal.id}) != nil else {
            return
        }
        stop()
        handler?(portal, nil)
        handler = nil
    }
    
    func wspBrowserDetectPortalDel(browser: WSPBrowser, portal: Portal) {
    }
    
    func wspBrowserDidNotSearch(browser: WSPBrowser, errorDict: [String : NSNumber]) {
        stop()
        handler?(nil, errorDict)
    }
}
