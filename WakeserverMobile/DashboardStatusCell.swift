//
//  DashboardStatusCell.swift
//  commonLib
//
//  Created by opiopan on 2017/10/28.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class DashboardStatusCell: UITableViewCell, PortalAccessoryDelegate{
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var indicator1: AccessoryStatusView!
    @IBOutlet weak var indicator2: AccessoryStatusView!
    @IBOutlet weak var indicator3: AccessoryStatusView!
    @IBOutlet weak var indicator4: AccessoryStatusView!
    
    private let dashboardItemNum = 4
    private var dashboardAccessory : DashboardAccessory?
    private var isObservating = false
    
    private let outdoorsNameColor = UIColor(red: 255.0/255.0, green: 114.0/255.0, blue: 0, alpha: 1.0)
    private let indoorsNameColor = UIColor(red: 0, green: 97.0/255.0, blue: 1.0, alpha: 1.0)
    
    private var updateStatusTimer : Timer?
    private var updateStatusCounter = 0

    private var portalId: String?
    private var portalServersHash: String?
    private var portalConfigHash: String?
    
    private var accessoryInAnimation = [false, false, false, false]

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.text = nil
    }
    
    deinit {
        endObservation()
    }
    
    var portal : Portal? {
        didSet {
            endObservation()
            dashboardAccessory = portal?.dashboardAccessory
            startObservation()

            var duration = 0.0
            if portalId != portal?.id || portalConfigHash != portal?.configHash ||
                portalServersHash != portal?.serversHash {
                duration = 1.0
            }
            let color = (portal?.isOutdoors ?? false) ? outdoorsNameColor : indoorsNameColor
            UIView.transition(with: nameLabel, duration: duration, options:.transitionCrossDissolve, animations: {
                [unowned self] in
                self.nameLabel.text = self.portal?.displayName
                self.nameLabel.textColor = color
                }, completion: {
                    [unowned self] _ in
                    self.portal?.updateStatus(notifier: nil)
                    self.portal?.updateCharacteristicStatus(notifier: nil)
            })
            UIView.transition(with: backgroundImageView, duration: duration, options:.transitionCrossDissolve, animations: {
                [unowned self] in
                self.backgroundImageView.image = self.portal?.backgroundImage
                }, completion: nil)

            let indicators = [indicator1, indicator2, indicator3, indicator4]
            if let dashboard = dashboardAccessory {
                for i in 0..<indicators.count {
                    guard let indicator = indicators[i], !accessoryInAnimation[i] else {continue}
                    accessoryInAnimation[i] = true
                    UIView.transition(with: indicator, duration: duration, options:.transitionFlipFromRight, animations: {
                        indicator.inhibitUpdateStatus(true)
                        indicator.themeColor = color
                        indicator.accessory = i < dashboard.units.count ? dashboard.units[i] : nil
                    }, completion: {
                        [unowned self] result in
                        self.accessoryInAnimation[i] = false
                        indicator.inhibitUpdateStatus(false)
                        if result {
                            indicator.updateStatus()
                        }
                    })
                }
            }else{
                indicators.forEach{
                    guard let indicator = $0 else {return}
                    UIView.transition(with: indicator, duration: duration, options:.transitionFlipFromLeft, animations: {
                        indicator.inhibitUpdateStatus(true)
                        indicator.accessory = nil
                    }, completion: {_ in
                        indicator.inhibitUpdateStatus(false)
                    })
                }
            }
            
            portalId = portal?.id
            portalConfigHash = portal?.configHash
            portalServersHash = portal?.serversHash
        }
    }
    
    func startObservation() {
        isObservating = true
        updateStatusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true){
            [unowned self] _ in
            self.updateStatusCounter += 1
            self.portal?.updateStatus(notifier: nil)
            if self.updateStatusCounter % 30 == 0 {
                self.portal?.updateCharacteristicStatus(notifier: nil)
            }
        }
        if let dashboard = dashboardAccessory {
            for i in 0..<min(dashboard.units.count, dashboardItemNum) {
                dashboard.units[i].register(delegate: self)
            }
            updateState()
        }
    }
    
    func endObservation(){
        if let dashboard = dashboardAccessory {
            for i in 0..<min(dashboard.units.count, dashboardItemNum) {
                dashboard.units[i].unregister(delegate: self)
            }
        }
        updateStatusTimer?.invalidate()
        updateStatusTimer = nil
        isObservating = false
    }
    
    func updateState(){
        [indicator1, indicator2, indicator3, indicator4].forEach{
            $0?.updateStatus()
        }
    }

    func changeStatus(accessory: PortalAccessory) {
        if isObservating {
            updateState()
        }
    }
}
