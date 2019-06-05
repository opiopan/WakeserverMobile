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

private let UPDATE_PERIOD_PLACE_INHOME = 30.0 * 60.0
private let UPDATE_PERIOD_STATE_INHOME = 10.0
private let UPDATE_PERIOD_CHARACTERISTICS_INHOME = 60.0
private let UPDATE_PERIOD_PLACE_OUTDOORS = 30.0 * 60.0
private let UPDATE_PERIOD_STATE_OUTDOORS = 10.0 * 60.0
private let UPDATE_PERIOD_CHARACTERISTICS_OUTDOORS = 10.0 * 60.0

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
    
    func broadPortalObject() -> Portal? {
        switch self {
        case .portal(let portal):
            return portal
        case .outdoors:
            return ConfigurationController.sharedController.outdoorsPortal
        default:
            return nil
        }
    }
    
    func isOutdoors() -> Bool {
        switch self {
        case .outdoors:
            return true
        default:
            return false
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
        case invalidatingConfig
        case updatingConfig
    }
    
    private var refleshTransaction = RefleshPhase.none
    private var needRestart = false
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
    public typealias PortalRepresentation = (
        portalId: String?, service: ServiceRepresentation?,
        serversHash: String?, configHash: String?)
    
    open func setPlace(withPortal portalData: PortalRepresentation) {
        if portalData.portalId == nil {
            self.updateAndNotifyPlace(place: .outdoors)
        }else{
            let portals = ConfigurationController.sharedController.registeredPortals
            if let index = portals.firstIndex(where: {$0.id == portalData.portalId}) {
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
        if (delegates.firstIndex{$0 === delegate}) == nil {
            delegates.append(delegate)
        }
    }
    
    open func unregister(delegate: PlaceRecognizerDelegate) {
        if let index = (delegates.firstIndex{$0 === delegate}) {
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
            if case .outdoors = place, !isDetecting {
                return
            }
        case .portal(let oldPortal):
            if let newPortal = place.portalObject(), newPortal.id == oldPortal.id,
               newPortal.serversHash == oldPortal.serversHash && newPortal.configHash == oldPortal.configHash,
               !isDetecting {
                return
            }
        }
        
        self.placeHolder = place
        self.placeHolder.portalObject()?.dashboardAccessory?.resetState()
        updateTimePlace = Date()
        updateTimeState = Date(timeIntervalSince1970: 0)
        updateTimeCharacteristics = Date(timeIntervalSince1970: 0)
        if needSetTimer {
            setTimer()
        }
        reflesh(nil)

        DispatchQueue.main.async {
            [unowned self] in
            self.delegates.forEach{$0.placeRecognizerDetectChangePortal(recognizer: self, place: self.place)}
            complicationDatastore.update()
            self.reorganizePages()
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
    
    open func refleshForce() {
        DispatchQueue.main.async {
            [unowned self] in
            self.updateTimePlace = Date(timeIntervalSince1970: 0)
            if self.refleshTransaction == .none {
                self.scheduleReflesh(.none, withError: false, withComplitionHandler: nil)
            }else{
                self.needRestart = true
            }
        }
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
            guard !self.needRestart else {
                self.finishTransaction()
                self.scheduleReflesh(.none, withError: false, withComplitionHandler: handler)
                return
            }
            
            switch self.refleshTransaction {
            case .none:
                self.refleshTransaction = .updatingPlace
                self.transactionHasUpdated = false
                self.tranTimeBegin = Date()
                self.tranTimeEnd = nil
                self.lastTransactionError = nil
                let now = Date()
                let interval = now.timeIntervalSince(self.updateTimePlace)
                if (self.place.isOutdoors() && interval > UPDATE_PERIOD_PLACE_OUTDOORS) ||
                    (!self.place.isOutdoors() && interval > UPDATE_PERIOD_PLACE_INHOME){
                    self.refleshPlace(handler)
                }else{
                    self.scheduleReflesh(.updatingPlace, withError: false, withComplitionHandler: handler)
                }
            case .updatingPlace:
                self.refleshTransaction = .updatingState
                let now = Date()
                let interval = now.timeIntervalSince(self.updateTimeState)
                if (self.place.isOutdoors() && interval > UPDATE_PERIOD_STATE_OUTDOORS) ||
                    (!self.place.isOutdoors() && interval > UPDATE_PERIOD_STATE_INHOME){
                    self.refleshState(handler)
                }else{
                    self.scheduleReflesh(.updatingState, withError: false, withComplitionHandler: handler)
                }
            case .updatingState:
                self.refleshTransaction = .updatingCharacteristics
                let now = Date()
                let interval = now.timeIntervalSince(self.updateTimeCharacteristics)
                if (self.place.isOutdoors() && interval > UPDATE_PERIOD_CHARACTERISTICS_OUTDOORS) ||
                    (!self.place.isOutdoors() && interval > UPDATE_PERIOD_CHARACTERISTICS_INHOME){
                    self.refleshCharacteristics(handler)
                }else{
                    self.scheduleReflesh(.updatingCharacteristics, withError: false, withComplitionHandler: handler)
                }
            case.updatingCharacteristics:
                complicationDatastore.update()
                self.finishTransaction()
                handler?()
                
            case .invalidatingConfig:
                self.refleshTransaction = .updatingConfig
                self.refleshConfig(handler)
            case.updatingConfig:
                self.finishTransaction()
                self.scheduleReflesh(.none, withError: false, withComplitionHandler: handler)
            }
        }
    }
    
    private func finishTransaction(){
        self.refleshTransaction = .none
        self.needRestart = false;
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
                    if let index = portals.firstIndex(where: {$0.id == result?.portalId}){
                        let portal = portals[index]
                        if portal.serversHash != result?.serversHash ||
                            portal.configHash != result?.configHash {
                            self.refleshTransaction = .invalidatingConfig
                            self.scheduleReflesh(.invalidatingConfig, withError: false, withComplitionHandler: handler)
                            return
                        }
                        portal.service = result?.service
                        self.updateAndNotifyPlace(place: .portal(portal))
                    }else{
                        self.refleshTransaction = .invalidatingConfig
                        self.scheduleReflesh(.invalidatingConfig, withError: false, withComplitionHandler: handler)
                        return
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
    
    private func refleshConfig(_ handler: (()->Void)?) {
        communicator.loadPortalConfig{
            [unowned self] error in
            self.scheduleReflesh(.updatingConfig, withError: false, withComplitionHandler: handler)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - pages collection generator
    //-----------------------------------------------------------------------------------------
    private var isDetecting = false
    
    public func reorganizePages() {
        guard let portal = place.broadPortalObject() else {
            return
        }
        
        isDetecting = false
        
        var names = ["homeSheetController"]
        var contexts: [Any] = [HomeSheetControllerContext(name: placeName, portal: portal)]
        
        portal.config?.pages.forEach{ page in
            let context: WSPageContext = (portal: portal, page: page)
            if page as? DashboardAccessory != nil {
                names.append("dashboardPageController")
                contexts.append(context)
            }else if page as? AVAccessory != nil {
                names.append("avPageController")
                contexts.append(context)
            }
        }
        
        names.append("avPageController")
        contexts.append("dummy")
        
        let initialPage = portal.isOutdoors ? 0 : portal.defaultPage + 1
        
        WKInterfaceController.reloadRootPageControllers(
            withNames: names, contexts: contexts, orientation: .horizontal, pageIndex: initialPage)
    }
    
    public func changeToDetectingPage() {
        isDetecting = true
        WKInterfaceController.reloadRootPageControllers(withNames:["detectingPortalController"], contexts: nil,
                                                        orientation: .horizontal, pageIndex: 0)
    }
}

public let placeRecognizer = PlaceRecognizer()
