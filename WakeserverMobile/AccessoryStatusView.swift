//
//  AccessoryStatusView.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/10/29.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class AccessoryStatusView: UIView {
    @IBOutlet weak var accessoryView: AccessoryStatusUnitView! /*{
        didSet {
            accessoryView?.themeColor = themeColor
        }
    }*/
    
    @IBOutlet weak var nameLabel: UILabel! /*{
        didSet{
            nameLabel?.textColor = themeColor ?? UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            nameLabel?.text = accessory?.name
        }
    }*/
    
    var themeColor : UIColor? {
        didSet {
            nameLabel?.textColor = themeColor ?? UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            accessoryView?.themeColor = themeColor
        }
    }
    
    var accessory : PortalAccessory? {
        didSet {
            nameLabel?.text = accessory?.name
            if let accessory = accessory {
                if let accessory = accessory as? ThermometerAccessory {
                    accessoryView?.viewType = .thermometer
                    accessoryView?.setTemperatureWithAnimation(temperature: accessory.temperature, duration: 0)
                }else{
                    accessoryView?.viewType = .powerState
                    accessoryView?.powerStatus = accessory.powerState
                    accessoryView?.image = accessory.dashboardIcon
                }
            }else{
                accessoryView?.viewType = .none
            }
        }
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        loadNib()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    func loadNib(){
        let view = Bundle.main.loadNibNamed("AccessoryStatusView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    private var isInhibitedUpdateStatus = 0
    
    func inhibitUpdateStatus(_ inhibit : Bool){
        isInhibitedUpdateStatus += inhibit ? 1 : -1
        if isInhibitedUpdateStatus < 0 {
            abort()
        }
    }
    
    func updateStatus(){
        guard isInhibitedUpdateStatus == 0, let accessory = accessory else {
            return
        }
        
        let duration = 1.0
        
        if let accessory = accessory as? ThermometerAccessory {
            if accessory.temperature?.rounded(.toNearestOrEven) != accessoryView?.temperatureRef?.rounded(.toNearestOrEven) {
                accessoryView?.setTemperatureWithAnimation(temperature: accessory.temperature, duration: duration)
            }
        }else{
            if accessory.powerState != accessoryView?.powerStatus {
                UIView.transition(with: accessoryView, duration: duration, options:.transitionCrossDissolve, animations: {
                    [unowned self] in
                    self.accessoryView?.powerStatus = (self.accessory?.powerState)!
                    }, completion: nil)
            }
        }
    }
}
