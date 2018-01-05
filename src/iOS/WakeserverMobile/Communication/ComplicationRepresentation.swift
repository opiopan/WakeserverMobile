//
//  ComplicationRepresentation.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/12.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import commonLib

typealias ComplicationData = (
    place: PlaceType,
    accessory1Name: String?,
    accessory1Value: String?,
    accessory2Name: String?,
    accessory2Value: String?
)

class ComplicationRepresentation {
    private let MIN_INTERVAL_PLACE_CHANGE = 5.0 * 60.0
    private let MIN_INTERVAL_ACCESSORY_UPDATE = 20.0 * 60.0
    
    private var holdDataHolder: ComplicationData = (
        place: .unknown,
        accessory1Name: nil,
        accessory1Value: nil,
        accessory2Name: nil,
        accessory2Value: nil
    )
    private var transferDate = Date(timeIntervalSince1970: 0)
    private var placeUpdateDate = Date(timeIntervalSince1970: 0)
    private var accessoryUpdateDate = Date(timeIntervalSince1970: 0)
    private var lastTransferError : IPCError?
    
    typealias Statistics = (
        transferDate: Date,
        placeUpdateDate: Date,
        accessoryUpdateDate: Date,
        lastTransferError: IPCError?
    )
    var stats : Statistics {
        return (
            transferDate: transferDate,
            placeUpdateDate: placeUpdateDate,
            accessoryUpdateDate: accessoryUpdateDate,
            lastTransferError: lastTransferError
        )
    }
    
    var holdData : ComplicationData {
        return holdDataHolder
    }

    var currentData: ComplicationData {
        let place = complicationUpdater.currentPlace
        let dashboard = complicationUpdater.currentPortal?.dashboardAccessory
        var accessory1: PortalAccessory?
        var accessory2: PortalAccessory?
        if let dashboard = dashboard{
            if dashboard.units.count >= 1 {
                accessory1 = dashboard.units[0]
            }
            if dashboard.units.count >= 2 {
                accessory2 = dashboard.units[1]
            }
        }
        
        return (
            place: place,
            accessory1Name: accessory1?.name,
            accessory1Value: accessory1?.complicationStatusString,
            accessory2Name: accessory2?.name,
            accessory2Value: accessory2?.complicationStatusString
        )
    }
    
    func holdDataEqualTo(_ data: ComplicationData) -> Bool {
        if let lPlace = holdDataHolder.place.portalObject(), let rPlace = data.place.portalObject(),
            lPlace.id == rPlace.id,
            holdDataHolder.accessory1Name == data.accessory1Name,
            holdDataHolder.accessory1Value == data.accessory1Value,
            holdDataHolder.accessory2Name == data.accessory2Name,
            holdDataHolder.accessory2Value == data.accessory2Value{
            return true
        }else{
            return false
        }
    }
    
    func setHoldData(_ data: ComplicationData) {
        var needUpdate = false
        if let lPlace = holdDataHolder.place.portalObject() {
            if let rPlace = data.place.portalObject(), lPlace.id != rPlace.id {
                needUpdate = true
                placeUpdateDate = Date()
            }
        }else if data.place.portalObject() != nil {
            needUpdate = true
            placeUpdateDate = Date()
        }
        if holdDataHolder.accessory1Name != data.accessory1Name ||
            holdDataHolder.accessory1Value != data.accessory1Value ||
            holdDataHolder.accessory2Name != data.accessory2Name ||
            holdDataHolder.accessory2Value != data.accessory2Value{
            needUpdate = true
            accessoryUpdateDate = Date()
        }
        if needUpdate {
            holdDataHolder = data
        }
    }
    
    func tranferHoldDate(force: Bool) {
        let intervalSinceLastTransfer = Date().timeIntervalSince(transferDate)
        if (force ||
            transferDate < placeUpdateDate && intervalSinceLastTransfer > MIN_INTERVAL_PLACE_CHANGE) ||
            (transferDate < accessoryUpdateDate && intervalSinceLastTransfer > MIN_INTERVAL_ACCESSORY_UPDATE){
            lastTransferError = communicator.sendComplicationData(holdData)
            transferDate = Date()
        }
    }
    
    func updateAndSyncWithWatch(force: Bool) {
        setHoldData(currentData)
        tranferHoldDate(force: force)
    }
}

let complicationRepresentation = ComplicationRepresentation()
