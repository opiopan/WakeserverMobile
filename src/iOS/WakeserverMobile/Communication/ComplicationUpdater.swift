//
//  ComplicationUpdater.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/12/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLib

private let UPDATE_PERIOD_PLACE = 30.0
private let UPDATE_PERIOD_STATE = 5.0
private let UPDATE_PERIOD_CHARACTERISTICS = 60.0

enum PlaceType {
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
}

enum ComplicationUpdateError : Int {
    case busy
    case overtaken
    case invalidCondition
    case scanningNetworkfail
}

class ComplicationUpdater {
    private var currentPlaceHolder : PlaceType = .unknown
    public var currentPlace : PlaceType {
        get {return currentPlaceHolder}
    }
    
    public var currentPortal : Portal? {
        get {
            switch currentPlace {
            case .outdoors:
                return ConfigurationController.sharedController.outdoorsPortal
            case .portal(let portal):
                return portal
            default:
                return nil
            }
        }
    }
    
    private enum TaskPhase {
        case none
        case updatingPlace
        case updatingState
        case updatingCharacteristics
    }

    private enum TaskPriority : Int {
        case realtime = 0
        case background = 1000
    }

    private typealias CompleteHandlers = (
        priority : TaskPriority,
        completePlaceUpdate: (() -> Void)?,
        completeStatusUpdate: (()-> Void)?,
        error: ((ComplicationUpdateError) -> Void)?
    )

    private var transaction = TaskPhase.none
    private var transactionCompleteHandlers : CompleteHandlers?
    public var isInTransaction : Bool {
        get {
            return transaction != .none
        }
    }
    
    private var tranTimeBegin = Date(timeIntervalSince1970: 0)
    private var tranTimeEnd : Date?
    private var updateTimePlace = Date(timeIntervalSince1970: 0)
    private var updateTimeState = Date(timeIntervalSince1970: 0)
    private var updateTimeCharacteristics = Date(timeIntervalSince1970: 0)
    public var updateTime : (begin: Date, end: Date?, place: Date, state: Date, characeristics: Date) {
        get {
            return (
                begin: tranTimeBegin,
                end: tranTimeEnd,
                place: updateTimePlace,
                state: updateTimeState,
                characeristics: updateTimeCharacteristics
            )
        }
    }
    
    open var placeName : String {
        get {
            switch currentPlace {
            case .unknown:
                return NSLocalizedString("PLACENAME_DETECTING", comment: "")
            case .outdoors:
                return ConfigurationController.sharedController.outdoorsPortal.displayName
            case .portal(let portal):
                return portal.displayName
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - reflesh data
    //-----------------------------------------------------------------------------------------
    open func reflesh(asBackground background: Bool,
                      whenCompletePlaceUpdate updatePlaceHandler: (()->Void)?,
                      whenCompleteStatusUpdate updateStatusHandler: (()->Void)?,
                      onError errorHandler: ((ComplicationUpdateError)->Void)?) {
        let handlers : CompleteHandlers = (
            priority : background ? .background : .realtime,
            completePlaceUpdate: updatePlaceHandler,
            completeStatusUpdate: updateStatusHandler,
            error: errorHandler
        )
        
        scheduleReflesh(.none, withError: nil, withComplitionHandlers: handlers)
    }
    
    private func scheduleReflesh(_ phase: TaskPhase, withError error: ComplicationUpdateError?,
                                 withComplitionHandlers handlers: CompleteHandlers?) {
        DispatchQueue.main.async {
            [unowned self] in
            guard self.transaction == phase else {
                if phase != .none {
                    abort()
                }
                if handlers?.priority.rawValue ?? 9999 < self.transactionCompleteHandlers?.priority.rawValue ?? 9999 {
                    self.transactionCompleteHandlers?.error?(.overtaken)
                    self.transactionCompleteHandlers = handlers
                    if self.transaction != .updatingPlace {
                        self.transactionCompleteHandlers?.completePlaceUpdate?()
                    }
                }else{
                    handlers?.error?(.busy)
                }
                return
            }
            guard error != nil else {
                self.finishTransaction()
                handlers?.error?(error!)
                return
            }
            
            switch self.transaction {
            case .none:
                self.transaction = .updatingPlace
                self.transactionCompleteHandlers = handlers
                self.tranTimeBegin = Date()
                self.tranTimeEnd = nil
                if self.updateTimePlace.timeIntervalSinceNow < -UPDATE_PERIOD_PLACE {
                    self.refleshPlace()
                }else{
                    self.scheduleReflesh(.updatingPlace, withError: nil, withComplitionHandlers:nil)
                }
            case .updatingPlace:
                self.transactionCompleteHandlers?.completePlaceUpdate?()
                self.transaction = .updatingState
                if self.updateTimeState.timeIntervalSinceNow < -UPDATE_PERIOD_STATE {
                    self.refleshState()
                }else{
                    self.scheduleReflesh(.updatingState, withError: nil, withComplitionHandlers: nil)
                }
            case .updatingState:
                self.transaction = .updatingCharacteristics
                if self.updateTimeCharacteristics.timeIntervalSinceNow < -UPDATE_PERIOD_CHARACTERISTICS {
                    self.refleshCharacteristics()
                }else{
                    self.scheduleReflesh(.updatingCharacteristics, withError: nil, withComplitionHandlers: nil)
                }
            case.updatingCharacteristics:
                self.transactionCompleteHandlers?.completeStatusUpdate?()
                self.finishTransaction()
            }
        }
    }
    
    private func finishTransaction(){
        self.transaction = .none
        self.tranTimeEnd = Date()
    }

    private var getPortalCommand : GetPortal?
    private func refleshPlace() {
        guard getPortalCommand == nil else {
            abort()
        }
        
        getPortalCommand = GetPortal()
        getPortalCommand?.run{
            [unowned self] portal, error in
            self.getPortalCommand = nil
            if error == nil {
                self.currentPlaceHolder = portal == nil ? .outdoors : .portal(portal!)
                self.scheduleReflesh(.updatingPlace, withError: nil, withComplitionHandlers: nil)
            }else{
                self.scheduleReflesh(.updatingPlace, withError: .scanningNetworkfail, withComplitionHandlers: nil)
            }
        }
    }
    
    private func refleshState() {
        currentPortal?.updateStatus{
            [unowned self] in
            self.scheduleReflesh(.updatingState, withError: nil, withComplitionHandlers: nil)
            DispatchQueue.main.async{
                self.updateTimeState = Date()
            }
        }
    }
    
    private func refleshCharacteristics() {
        if let portal = currentPortal {
            portal.dashboardAccessory?.updateCharacteristicStatus(portal: portal){
                [unowned self] in
                self.scheduleReflesh(.updatingCharacteristics, withError: nil, withComplitionHandlers: nil)
                DispatchQueue.main.async{
                    self.updateTimeCharacteristics = Date()
                }
            }
        }else{
            scheduleReflesh(.updatingCharacteristics, withError: .invalidCondition, withComplitionHandlers: nil)
        }
    }
}

let complicationUpdater = ComplicationUpdater()
