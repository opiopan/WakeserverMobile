//
//  PlaceRecognizerWatch.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/30.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLibWatch

private let INITIAL_INTERVAL = 1.0
private let NORMAL_INTERVAL = 60.0

private let UPDATE_PERIOD_PLACE = 30.0
private let UPDATE_PERIOD_STATE = 5.0
private let UPDATE_PERIOD_CHARACTERISTICS = 60.0

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
    
    public var currentPortal : Portal? {
        get {
            switch place {
            case .outdoors:
                return ConfigurationController.sharedController.outdoorsPortal
            case .portal(let portal):
                return portal
            default:
                return nil
            }
        }
    }
    
    private enum RefleshPhase {
        case none
        case updatingPlace
        case updatingState
        case updatingCharacteristics
    }
    
    private var refleshTransaction = RefleshPhase.none
    private var transactionHasUpdated = false
    public var isInTransaction : Bool {
        get {
            return refleshTransaction != .none
        }
    }
    
    private var ipc : Communicator?
    private var timer : Timer?
    
    private var lastTransactionError : IPCError?
    
    private var tranTimeBegin = Date(timeIntervalSince1970: 0)
    private var tranTimeEnd : Date?
    private var updateTimePlace = Date(timeIntervalSince1970: 0)
    private var updateTimeState = Date(timeIntervalSince1970: 0)
    private var updateTimeCharacteristics = Date(timeIntervalSince1970: 0)
    public var updateTime : (begin: Date, end: Date?, place: Date, state: Date, characeristics: Date, error: IPCError?) {
        get {
            return (
                begin: tranTimeBegin,
                end: tranTimeEnd,
                place: updateTimePlace,
                state: updateTimeState,
                characeristics: updateTimeCharacteristics,
                error: lastTransactionError
            )
        }
    }

    private var delegates: [PlaceRecognizerDelegate] = []
    
    open var placeName : String {
        get {
            switch place {
            case .unknown:
                return NSLocalizedString("PLACENAME_DETECTING", comment: "")
            case .outdoors:
                return ConfigurationController.sharedController.outdoorsPortal.displayName
            case .portal(let portal):
                return portal.displayName
            }
        }
    }

    public typealias ServiceRepresentation = (name: String, domain: String, port: Int)
    public typealias PortalRepresentation = (portalId: String?, service: ServiceRepresentation?)
    
    open func setPlace(withPortal portalData: PortalRepresentation) {
        if portalData.portalId == nil {
            self.updateAndNotifyPlace(place: .outdoors)
        }else{
            let portals = ConfigurationController.sharedController.registeredPortals
            if let index = portals.index(where: {$0.id == portalData.portalId}) {
                let portal = portals[index]
                portal.service = portalData.service
                self.updateAndNotifyPlace(place: .portal(portal))
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
    
    public func updateAndNotifyPlace(place: PlaceType) {
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
        self.placeHolder.portalObject()?.dashboardAccessory?.resetState()
        if needSetTimer {
            setTimer()
        }

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
    
    private func setTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: place.scanInterval(), repeats: true){
            [unowned self] _ in
            self.reflesh(nil)
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - reflesh data
    //-----------------------------------------------------------------------------------------
    open func reflesh(_ handler: (()->Void)?) {
        scheduleReflesh(.none, withError: false, withComplitionHandler: handler)
    }
    
    private func scheduleReflesh(_ phase: RefleshPhase, withError error: Bool, withComplitionHandler handler: (()->Void)?) {
        DispatchQueue.main.async {
            [unowned self] in
            guard self.refleshTransaction == phase else {
                if phase != .none {
                    abort()
                }
                handler?()
                return
            }
            guard !error else {
                self.finishTransaction()
                handler?()
                return
            }
            
            switch self.refleshTransaction {
            case .none:
                self.refleshTransaction = .updatingPlace
                self.transactionHasUpdated = false
                self.tranTimeBegin = Date()
                self.tranTimeEnd = nil
                self.lastTransactionError = nil
                if self.updateTimePlace.timeIntervalSinceNow < -UPDATE_PERIOD_PLACE {
                    self.refleshPlace(handler)
                }else{
                    self.scheduleReflesh(.updatingPlace, withError: false, withComplitionHandler: handler)
                }
            case .updatingPlace:
                self.refleshTransaction = .updatingState
                if self.updateTimeState.timeIntervalSinceNow < -UPDATE_PERIOD_STATE {
                    self.refleshState(handler)
                }else{
                    self.scheduleReflesh(.updatingState, withError: false, withComplitionHandler: handler)
                }
            case .updatingState:
                self.refleshTransaction = .updatingCharacteristics
                if self.updateTimeCharacteristics.timeIntervalSinceNow < -UPDATE_PERIOD_CHARACTERISTICS {
                    self.refleshCharacteristics(handler)
                }else{
                    self.scheduleReflesh(.updatingCharacteristics, withError: false, withComplitionHandler: handler)
                }
            case.updatingCharacteristics:
                complicationDatastore.update()
                self.finishTransaction()
                handler?()
            }
        }
    }
    
    private func finishTransaction(){
        self.refleshTransaction = .none
        self.tranTimeEnd = Date()
    }
    
    private func refleshPlace(_ handler: (()->Void)?) {
        guard self.ipc == nil else{
            self.scheduleReflesh(.updatingPlace, withError: true, withComplitionHandler: handler)
            return
        }
        self.ipc = communicator
        self.ipc?.getLocation{ result, error in
            DispatchQueue.main.async{
                [unowned self] in
                self.ipc = nil
                self.lastTransactionError = error
                guard error == nil else{
                    self.scheduleReflesh(.updatingPlace, withError: true, withComplitionHandler: handler)
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
                self.updateTimePlace = Date()
                self.scheduleReflesh(.updatingPlace, withError: false, withComplitionHandler: handler)
            }
        }
    }
    
    private func refleshState(_ handler: (()->Void)?) {
        currentPortal?.updateStatus{
            [unowned self] in
            self.scheduleReflesh(.updatingState, withError: false, withComplitionHandler: handler)
            DispatchQueue.main.async{
                self.updateTimeState = Date()
            }
        }
    }

    private func refleshCharacteristics(_ handler: (()->Void)?) {
        if let portal = currentPortal {
            portal.dashboardAccessory?.updateCharacteristicStatus(portal: portal){
                [unowned self] in
                self.scheduleReflesh(.updatingCharacteristics, withError: false, withComplitionHandler: handler)
                DispatchQueue.main.async{
                    self.updateTimeCharacteristics = Date()
                }
            }
        }else{
            scheduleReflesh(.updatingCharacteristics, withError: true, withComplitionHandler: handler)
        }
    }
}

public let placeRecognizer = PlaceRecognizer()
