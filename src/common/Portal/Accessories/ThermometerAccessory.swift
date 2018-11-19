//
//  ThermometerAccessory.swift
//  commonLib
//
//  Created by oiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import HomeKit

open class ThermometerAccessory : PortalAccessoryCorrespondsServer {
    public let attribute : String
    
    open var temperature : Double?
    
    override open var complicationStatusString : String {
        get {
            if let temperature = temperature {
                return String(format: "%.1f °C", temperature)
            }else{
                return LocalizedString("POWER_STATE_UNKNOWN")
            }
        }
    }
    
    override public init() {
        attribute = ""
        super.init()
    }
    
    public required init(dict: [String : Any]) throws {
        guard let attribute = dict["attribute"] as! String? else {
            throw PortalConfigError.partialyInconsistentData(LocalizedString("MSG_ERR_NO_ATTRIBUTE_IN_THERMOMETER"))
        }
        self.attribute = attribute
        try super.init(dict: dict)
    }
    
    override open var dictionary: [String : Any] {
        get {
            var dict = super.dictionary
            dict["attribute"] = attribute
            return dict
        }
    }
    
    override func reflectPowerStatus(statuses: [Any]) {
    }
    
    override open func updateCharacteristicStatus(portal: Portal, notifier: (() -> Void)?) {
        if let service = hmService {
            service.characteristics.filter{$0.characteristicType == HMCharacteristicTypeCurrentTemperature}.forEach{
                characteristic in
                weak var weakSelf = self
                characteristic.readValue{
                    error in
                    if error == nil, let value = characteristic.value as? Double {
                        let oldValue = weakSelf?.temperature
                        weakSelf?.temperature = value
                        if oldValue != weakSelf?.temperature {
                            weakSelf?.invokeChangeState()
                        }
                    }
                }
            }
        }
        
        guard let service = portal.service else {
            notifier?()
            return
        }
        
        let urlprefix = "http://\(service.name).\(service.domain):\(service.port)"
        var components = URLComponents(string: "\(urlprefix)/cgi-bin/wakeserver-attribute.cgi")
        components?.queryItems = [
            URLQueryItem(name:"target", value:server),
            URLQueryItem(name:"attribute", value:attribute),
        ]
        let task = URLSession.shared.dataTask(with: components!.url!){
            [unowned self] data, response, error in
            guard let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 else {
                notifier?()
                return
            }
            do {
                if let root = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any],
                    let value = root["value"] as? String,
                    let temperature = Double(value) {
                    if self.temperature != temperature {
                        self.temperature = temperature
                        self.invokeChangeState()
                    }
                }
            }catch {
            }
            notifier?()
        }
        task.resume()
    }
    
    override open func resetState() {
        super.resetState()
        temperature = nil
    }
}
