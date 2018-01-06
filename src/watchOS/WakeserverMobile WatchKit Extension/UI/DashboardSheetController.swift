//
//  DashboardSheetController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/12/24.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch

class DashboardSheetController: WSPageController {
    @IBOutlet var unit1Group: WKInterfaceGroup!
    @IBOutlet var unit1Background: WKInterfaceGroup!
    @IBOutlet var unit1Gesture: WKTapGestureRecognizer!
    @IBOutlet var unit1Image: WKInterfaceImage!
    @IBOutlet var unit1Caption: WKInterfaceLabel!
    @IBOutlet var unit1Label: WKInterfaceLabel!

    @IBOutlet var unit2Group: WKInterfaceGroup!
    @IBOutlet var unit2Background: WKInterfaceGroup!
    @IBOutlet var unit2Gesture: WKTapGestureRecognizer!
    @IBOutlet var unit2Image: WKInterfaceImage!
    @IBOutlet var unit2Caption: WKInterfaceLabel!
    @IBOutlet var unit2Label: WKInterfaceLabel!
    
    @IBOutlet var unit3Group: WKInterfaceGroup!
    @IBOutlet var unit3Background: WKInterfaceGroup!
    @IBOutlet var unit3Gesture: WKTapGestureRecognizer!
    @IBOutlet var unit3Image: WKInterfaceImage!
    @IBOutlet var unit3Caption: WKInterfaceLabel!
    @IBOutlet var unit3Label: WKInterfaceLabel!
    
    @IBOutlet var unit4Group: WKInterfaceGroup!
    @IBOutlet var unit4Background: WKInterfaceGroup!
    @IBOutlet var unit4Gesture: WKTapGestureRecognizer!
    @IBOutlet var unit4Image: WKInterfaceImage!
    @IBOutlet var unit4Caption: WKInterfaceLabel!
    @IBOutlet var unit4Label: WKInterfaceLabel!
    
    private var pageData: DashboardAccessory?
    
    private var units = [Unit]()

    private typealias GEOMETRY = (
        imageHeight: CGFloat,
        circleThickness: CGFloat
    )
    
    private var geometry: GEOMETRY!
    
    private let geometryFor42mm: GEOMETRY = (
        imageHeight: CGFloat(60),
        circleThickness: CGFloat(5)
    )
    
    private let geometryFor38mm: GEOMETRY = (
        imageHeight: CGFloat(60),
        circleThickness: CGFloat(4.5)
    )

    //-----------------------------------------------------------------------------------------
    // MARK: - initialization
    //-----------------------------------------------------------------------------------------
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        geometry = watchSizeIs42mm ? geometryFor42mm : geometryFor38mm
        pageData = self.context?.page as? DashboardAccessory

        units = [
            Unit(controller: self, group: unit1Group, background: unit1Background,
                 image: unit1Image, caption: unit1Caption, label: unit1Label),
            Unit(controller: self, group: unit2Group, background: unit2Background,
                 image: unit2Image, caption: unit2Caption, label: unit2Label),
            Unit(controller: self, group: unit3Group, background: unit3Background,
                 image: unit3Image, caption: unit3Caption, label: unit3Label),
            Unit(controller: self, group: unit4Group, background: unit4Background,
                 image: unit4Image, caption: unit4Caption, label: unit4Label),
        ]
        
        for (index, unit) in (pageData?.units ?? []).enumerated() {
            self.units[index].setAccessory(unit, withImageSize: self.geometry.imageHeight,
                                           circleThickness: geometry.circleThickness)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - status transition
    //-----------------------------------------------------------------------------------------
    override func willActivate() {
        super.willActivate()
        units.forEach{$0.reflectState()}
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - tap action
    //-----------------------------------------------------------------------------------------
    @IBAction func tapOnUnit1(_ sender: Any) {
        units[0].correspondToTap(withPortal: context?.portal)
    }
    
    @IBAction func tapOnUnit2(_ sender: Any) {
        units[1].correspondToTap(withPortal: context?.portal)
    }
    
    @IBAction func tapOnUnit3(_ sender: Any) {
        units[2].correspondToTap(withPortal: context?.portal)
    }
    
    @IBAction func tapOnUnit4(_ sender: Any) {
        units[3].correspondToTap(withPortal: context?.portal)
    }
}

//-----------------------------------------------------------------------------------------
// MARK: - Accessory unit representation
//-----------------------------------------------------------------------------------------
private class Unit{
    weak var controller: WKInterfaceController?
    let group: WKInterfaceGroup
    let background: WKInterfaceGroup
    let image: WKInterfaceImage
    let caption: WKInterfaceLabel
    let label: WKInterfaceLabel
    private var accessory: PortalAccessory?
    private var circle: InterfaceCircle?
    private var button: ButtonAnimation?
    
    init(controller: WKInterfaceController?, group: WKInterfaceGroup, background: WKInterfaceGroup,
         image: WKInterfaceImage, caption: WKInterfaceLabel, label: WKInterfaceLabel){
        self.controller = controller
        self.group = group
        self.background = background
        self.image = image
        self.caption = caption
        self.label = label
        self.group.setHidden(true)
    }
    
    func setAccessory(_ accessory: PortalAccessory, withImageSize imageSize: CGFloat, circleThickness: CGFloat) {
        self.accessory = accessory
        if self.accessory as? ThermometerAccessory != nil {
            self.circle = InterfaceCircle(withInterfaceImage: self.image, size: imageSize)
            self.circle?.lineWidth = circleThickness
            self.caption.setHidden(false)
        }else{
            self.circle = nil
            self.caption.setHidden(true)
            let image = Graphics.shrinkingFilter.apply(image: self.accessory?.dashboardIcon, rathio: 0.6)
            self.image.setImage(image?.withRenderingMode(.alwaysTemplate))
        }
        if self.accessory?.isWakeable ?? false {
            self.button = ButtonAnimation(withSizeChengee: self.image, normalSizeRatio: 1.0, pushedSizeRatio: 0.8,
                                          colorChangee: nil, normalColor: nil, pushedColor: nil)
        }else{
            self.button = nil
        }
        label.setText(self.accessory?.name)
        reflectState()
        self.group.setHidden(self.accessory == nil)
    }
    
    func reflectState() {
        guard let accessory = accessory else {
            return
        }
        
        if let thermometer = accessory as? ThermometerAccessory {
            if let temperature = thermometer.temperature {
                caption.setText(String(format: "%.0f°", temperature))
                caption.setTextColor(appColor.theme)
                let minT = -10.0
                let maxT = 35.0
                let gain = maxT - minT
                let angle = min(max((temperature - minT) / gain, 0.03), 1.0)
                circle?.setCircleAngle(angle)
                image.setTintColor(appColor.theme)
                background.setBackgroundColor(appColor.themeDark)
            }else{
                caption.setText("--°")
                caption.setTextColor(appColor.defaultLightDark)
                circle?.setCircleAngle(0)
                background.setBackgroundColor(appColor.defaultDark)
            }
        }else{
            switch accessory.powerState {
            case .off:
                image.setTintColor(appColor.themeLightDark)
                background.setBackgroundColor(appColor.themeDark)
            case .on:
                image.setTintColor(appColor.theme)
                background.setBackgroundColor(appColor.themeDark)
            case .unknown:
                image.setTintColor(appColor.defaultDark)
                background.setBackgroundColor(appColor.defaultLightDark)
            }
        }
    }
    
    func correspondToTap(withPortal portal: Portal?) {
        if let button = button, accessory?.powerState != .unknown {
            if let accessory = accessory as? PortalAccessoryCorrespondsServer, let portal = portal {
                accessory.togglePowerStatus(viaPortal: portal)
            }
            
            button.setState(false)
            controller?.animate(withDuration: 0.3){
                [unowned self] in
                self.reflectState()
                button.setState(true)
            }
        }
    }
}
