//
//  PortalPlatform.swift
//  commonLib
//
//  Created by opiopan on 2017/10/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class PortalPlatformEntity {
    let name : String
    let icon : UIImage?
    
    public init(name: String, icon: UIImage?){
        self.name = name
        self.icon = icon
    }
}

open class PortalPlatform {
    private static let list : [String: PortalPlatformEntity] = [
        "raspi": PortalPlatformEntity(name: "Raspberry Pi",
                                      icon: libBundleImage(name: "platform_icon_raspi"))
    ]
    
    private static let unknownPlatform : PortalPlatformEntity =
        PortalPlatformEntity(name: LocalizedString("PORTAL_PLATFORM_UNKNOWN"),
                             icon: libBundleImage(name: "platform_icon_unknown"))
    
    open static func name(forKey key: String?) -> String {
        if let platform = list[key == nil ? "" : key!] {
            return platform.name
        }else{
            return unknownPlatform.name
        }
    }
    
    open static func icon(forKey key: String?) -> UIImage? {
        if let platform = list[key == nil ? "" : key!] {
            return platform.icon
        }else{
            return unknownPlatform.icon
        }
    }
}
