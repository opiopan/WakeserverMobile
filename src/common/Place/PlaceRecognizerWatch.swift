//
//  PlaceRecognizerWatch.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/30.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

private let INITIAL_INTERVAL = 1.0
private let NORMAL_INTERVAL = 60.0

public enum PlaceType {
    case unknown
    case outdoors
    case portal(Portal)
    
    func portalObject() -> Portal? {
        switch self {
        case .portal(let portal):
            return portal
        default:
            return nil
        }
    }
    
    func scanInterval() -> Double{
        switch self {
        case .unknown:
            return INITIAL_INTERVAL
        default:
            return NORMAL_INTERVAL
        }
    }
}

public protocol PlaceRecognizerDelegate : AnyObject {
    func placeRecognizerDetectChangePortal(recognizer: PlaceRecognizer, place: PlaceType)
}

open class PlaceRecognizer {
    private var placeHolder : PlaceType = .unknown
    public var place : PlaceType {
        get {return placeHolder}
    }
    
    private var ipc : IPC?
    private var timer : Timer?

    private var delegates: [PlaceRecognizerDelegate] = []
    
    open var placeName : String {
        get {
            switch place {
            case .unknown:
                return LocalizedString("PLACENAME_DETECTING")
            case .outdoors:
                return ConfigurationController.sharedController.outdoorsPortal.displayName
            case .portal(let portal):
                return portal.displayName
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - delegate manipulation
    //-----------------------------------------------------------------------------------------
    open func register(delegate: PlaceRecognizerDelegate) {
        if (delegates.index{$0 === delegate}) == nil {
            delegates.append(delegate)
        }
    }
    
    open func unregister(delegate: PlaceRecognizerDelegate) {
        if let index = (delegates.index{$0 === delegate}) {
            delegates.remove(at: index)
        }
    }
    
    private func updateAndNotifyPlace(place: PlaceType) {
        var needSetTimer = false
        switch self.place {
        case .unknown:
            if case .unknown = place {
                return
            }
            needSetTimer = (timer != nil)
        case .outdoors:
            if case .outdoors = place {
                return
            }
        case .portal(let oldPortal):
            if let newPortal = place.portalObject(), newPortal.id == oldPortal.id {
                return
            }
        }
        
        self.placeHolder = place
        if needSetTimer {
            setTimer()
        }
        
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach{server.reloadTimeline(for: $0)}

        DispatchQueue.main.async {
            [unowned self] in
            self.delegates.forEach{$0.placeRecognizerDetectChangePortal(recognizer: self, place: self.place)}
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - controll detector
    //-----------------------------------------------------------------------------------------
    open func start() {
        guard timer == nil else {
            return
        }
        setTimer()
        timer?.fire()
    }
    
    open func stop() {
        guard timer != nil else {
            return
        }
        resetTimer()
    }
    
    open func reflesh() {
        DispatchQueue.main.async {
            [unowned self] in
            guard self.ipc == nil else{
                return
            }
            self.ipc = IPC.session
            self.ipc?.getLocation{ result, error in
                DispatchQueue.main.async{
                    [unowned self] in
                    self.ipc = nil
                    guard error == nil else{
                        return
                    }
                    if result?.portalId == nil {
                        self.updateAndNotifyPlace(place: .outdoors)
                    }else{
                        let portals = ConfigurationController.sharedController.registeredPortals
                        if let index = portals.index(where: {$0.id == result?.portalId}) {
                            let portal = portals[index]
                            portal.service = result?.service
                            self.updateAndNotifyPlace(place: .portal(portal))
                        }
                    }
                    
                }
            }
        }
    }
    
    private func setTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: place.scanInterval(), repeats: true){
            [unowned self] _ in
            self.reflesh()
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
    }
}

public let placeRecognizer = PlaceRecognizer()
