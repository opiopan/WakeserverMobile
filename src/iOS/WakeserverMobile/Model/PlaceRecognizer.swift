//
//  PlaceRecognizer.swift
//  commonLib
//
//  Created by opiopan on 2017/10/28.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLib

public protocol PlaceRecognizerDelegate : AnyObject {
    func placeRecognizerDetectChangePortal(recognizer: PlaceRecognizer, portal: Portal)
}

open class PlaceRecognizer : WSPBrowserDelegate{
    private let SCAN_INTERVAL = 60.0
    private let SCAN_TIMEOUT = 2.0
    private let SCAN_MIN_INTERVAL = 0.5
    
    private let config = ConfigurationController.sharedController
    private let browser = WSPBrowser()
    private var currentPortalHolder : Portal = ConfigurationController.sharedController.outdoorsPortal
    private var delegates: [PlaceRecognizerDelegate] = []
    
    private var scanDate : Date = Date(timeIntervalSince1970: 0)
    private var scanIntervalTimer : Timer?
    private var scanTimeoutTimer : Timer?
    
    open var currentPortal : Portal {
        get {
            return currentPortalHolder
        }
    }

    public init() {
        browser.delegate = self
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - delegate manipulation
    //-----------------------------------------------------------------------------------------
    open func register(delegate: PlaceRecognizerDelegate) {
        if (delegates.firstIndex{$0 === delegate}) == nil {
            delegates.append(delegate)
        }
    }
    
    open func unregister(delegate: PlaceRecognizerDelegate) {
        if let index = (delegates.firstIndex{$0 === delegate}) {
            delegates.remove(at: index)
        }
    }
    
    private func invokeChangePortalOfDelegates() {
        let portal = currentPortalHolder
        portal.pages?.forEach{$0.resetState()}
        DispatchQueue.main.async {
            [unowned self] in
            self.delegates.forEach{$0.placeRecognizerDetectChangePortal(recognizer: self, portal: portal)}
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - controll detector
    //-----------------------------------------------------------------------------------------
    open func start(){
        guard scanIntervalTimer == nil && scanTimeoutTimer == nil else {
            return
        }

        scanIntervalTimer = Timer.scheduledTimer(withTimeInterval: SCAN_INTERVAL, repeats: true){
            [unowned self] _ in
            self.beginScanTransaction(handler: nil)
        }
        scanIntervalTimer?.fire()
    }
    
    open func stop(){
        browser.stop()
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
        scanIntervalTimer?.invalidate()
        scanIntervalTimer = nil
    }
    
    open func updatePortalConfig(){
        let currentID = currentPortalHolder.id
        if let index = (config.registeredPortals.firstIndex{$0.id == currentID}) {
            currentPortalHolder = config.registeredPortals[index]
        } else {
            currentPortalHolder = config.outdoorsPortal
        }
        invokeChangePortalOfDelegates()
    }
    
    open func rescan(){
        scanIntervalTimer?.fire()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - search place
    //-----------------------------------------------------------------------------------------
    public enum ScanError : Error {
        case busy
    }
    public typealias ScanCompleteHandler = (ScanError?)->Void
    private var isInTransaction = false
    private var scanCompleteHandler : ScanCompleteHandler?
    
    open func beginScanTransaction(handler : ScanCompleteHandler?) {
        DispatchQueue.main.async {
            [unowned self] in
            guard !self.isInTransaction else {
                handler?(ScanError.busy)
                return
            }
            self.isInTransaction = true
            self.scanCompleteHandler = handler
            
            let now = Date()
            guard now.timeIntervalSince(self.scanDate) > self.SCAN_MIN_INTERVAL else {
                self.endScanTransaction(error: nil)
                return
            }
            self.scanDate = now
            self.scanTimeoutTimer?.invalidate()
            self.browser.stop()
            self.browser.start()
            self.scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: self.SCAN_TIMEOUT, repeats: false){
                [unowned self] _ in
                self.stopBrowser()
                
                // Here is outdoors sinse no portal are found
                if !self.currentPortalHolder.isOutdoors {
                    self.currentPortalHolder = self.config.outdoorsPortal
                    self.invokeChangePortalOfDelegates()
                }
                self.endScanTransaction(error: nil)
            }
        }
    }
    
    private func endScanTransaction(error : ScanError?) {
        DispatchQueue.main.async {
            [unowned self] in
            self.isInTransaction = false
            self.scanCompleteHandler?(error)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - controll browser
    //-----------------------------------------------------------------------------------------
    private func stopBrowser() {
        browser.stop()
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - WSPBrowserProxy protocol
    //-----------------------------------------------------------------------------------------
    public func wspBrowserDetectPortalAdd(browser: WSPBrowser, portal: Portal) {
        let targetPortals = config.registeredPortals.filter{$0.id == portal.id}
        guard targetPortals.count != 0 else {
            return
        }
        
        stopBrowser()

        if targetPortals[0].configHash != portal.configHash || targetPortals[0].serversHash != portal.serversHash {
            portal.updateConfig{
                [unowned self] portal, error in
                if let portal = portal, let index = (self.config.registeredPortals.firstIndex{$0.id == portal.id}) {
                    var portals = self.config.registeredPortals
                    portal.reflectOption(of: portals[index])
                    portals.replaceSubrange(index..<index + 1, with: [portal])
                    self.config.registeredPortals = portals
                    self.currentPortalHolder = portal
                    self.invokeChangePortalOfDelegates()
                }else{
                    if !self.currentPortalHolder.isOutdoors {
                        self.currentPortalHolder = self.config.outdoorsPortal
                        self.invokeChangePortalOfDelegates()
                    }
                }
                self.endScanTransaction(error: nil)
            }
        }else{
            if currentPortalHolder.id != targetPortals[0].id {
                targetPortals[0].service = portal.service
                currentPortalHolder = targetPortals[0]
                invokeChangePortalOfDelegates()
            }
            self.endScanTransaction(error: nil)
        }
    }
    
    public func wspBrowserDetectPortalDel(browser: WSPBrowser, portal: Portal) {
        if portal.id == currentPortalHolder.id {
            stopBrowser()
            currentPortalHolder = config.outdoorsPortal
            invokeChangePortalOfDelegates()
            self.endScanTransaction(error: nil)
        }
    }
    
    public func wspBrowserDidNotSearch(browser: WSPBrowser, errorDict: [String : NSNumber]) {
        stopBrowser()
        if !currentPortalHolder.isOutdoors {
            currentPortalHolder = config.outdoorsPortal
            invokeChangePortalOfDelegates()
            self.endScanTransaction(error: nil)
        }
    }
    
}
