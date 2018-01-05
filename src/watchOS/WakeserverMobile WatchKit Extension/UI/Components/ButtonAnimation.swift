//
//  ButtonAnimation.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/24.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation
import WatchKit

class ButtonAnimation {
    private weak var sizeChangee: WKInterfaceObject?
    private let normalSizeRatio: Double?
    private let pushedSizeRatio: Double?
    private weak var colorChangee: WKInterfaceObject?
    private let normalColor: UIColor?
    private let pushedColor: UIColor?
    
    init(withSizeChengee sizeChangee: WKInterfaceObject?, normalSizeRatio: Double?, pushedSizeRatio: Double?,
         colorChangee: WKInterfaceObject?, normalColor: UIColor?, pushedColor: UIColor?) {
        self.sizeChangee = sizeChangee
        self.normalSizeRatio = normalSizeRatio
        self.pushedSizeRatio = pushedSizeRatio
        self.colorChangee = colorChangee
        self.normalColor = normalColor
        self.pushedColor = pushedColor
        
        setState(true)
    }
    
    func setState(_ normal: Bool) {
        if let sizeChangee = sizeChangee {
            let ratio = CGFloat(normal ? normalSizeRatio! : pushedSizeRatio!)
            sizeChangee.setRelativeWidth(ratio, withAdjustment: 0)
            sizeChangee.setRelativeHeight(ratio, withAdjustment: 0)
        }
        if let colorChangee = colorChangee {
            let color = normal ? normalColor! : pushedColor!
            if let object = colorChangee as? WKInterfaceGroup {
                object.setBackgroundColor(color)
            }else if let object = colorChangee as? WKInterfaceImage {
                object.setTintColor(color)
            }
        }
    }
}
