//
//  ComplicationController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/08/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import ClockKit
import commonLibWatch

private let ICON_NAME_PREFIX_APP = "ComplicationApp"

//-----------------------------------------------------------------------------------------
// MARK: - Complication datastore
//-----------------------------------------------------------------------------------------
typealias ComplicationData = (
    iconNamePrefix: String,
    portalId: String?,
    portalName: String,
    accessory1Name: String?,
    accessory1Value: String?,
    accessory2Name: String?,
    accessory2Value: String?
)

class ComplicationDatastore {
    var data: ComplicationData = (
        iconNamePrefix: ICON_NAME_PREFIX_APP,
        portalId: nil,
        portalName: placeRecognizer.placeName,
        accessory1Name: nil,
        accessory1Value: nil,
        accessory2Name: nil,
        accessory2Value: nil
    )
    
    private var currentData : ComplicationData {
        get {
            let portal = placeRecognizer.currentPortal
            let dashboard = portal?.dashboardAccessory
            var accessory1Name: String? = nil
            var accessory1Value: String? = nil
            if dashboard?.units.count ?? 0 >= 1 {
                let unit = dashboard?.units[0]
                accessory1Name = unit?.name
                accessory1Value = unit?.complicationStatusString
            }
            var accessory2Name: String? = nil
            var accessory2Value: String? = nil
            if dashboard?.units.count ?? 0 >= 2 {
                let unit = dashboard?.units[1]
                accessory2Name = unit?.name
                accessory2Value = unit?.complicationStatusString
            }
            
            return (
                iconNamePrefix: ICON_NAME_PREFIX_APP,
                portalId: portal?.id,
                portalName: placeRecognizer.placeName,
                accessory1Name: accessory1Name,
                accessory1Value: accessory1Value,
                accessory2Name: accessory2Name,
                accessory2Value: accessory2Value
            )
        }
    }
    
    func update() {
        DispatchQueue.main.async{
            [unowned self] in
            print("UPDATE: complication")
            
            let current = self.currentData
            self.update(withComplicationData: current)
        }
    }
    
    func update(withAccessoriesInMessage message: [String:Any]) {
        DispatchQueue.main.async{
            [unowned self] in
            let current : ComplicationData = (
                iconNamePrefix: ICON_NAME_PREFIX_APP,
                portalId: placeRecognizer.currentPortal?.id,
                portalName: placeRecognizer.placeName,
                accessory1Name: message[IPCKeyAccessory1Name] as? String,
                accessory1Value: message[IPCKeyAccessory1Value] as? String,
                accessory2Name: message[IPCKeyAccessory2Name] as? String,
                accessory2Value: message[IPCKeyAccessory2Value] as? String
            )
            self.update(withComplicationData: current)
        }
    }
    
    private func update(withComplicationData data: ComplicationData) {
        if self.data.iconNamePrefix != data.iconNamePrefix ||
            self.data.portalId != data.portalId ||
            self.data.portalName != data.portalName ||
            self.data.accessory1Name != data.accessory1Name ||
            self.data.accessory1Value != data.accessory1Value ||
            self.data.accessory2Name != data.accessory2Name ||
            self.data.accessory2Value != data.accessory2Value {
            self.data = data
            let server = CLKComplicationServer.sharedInstance()
            server.activeComplications?.forEach{server.reloadTimeline(for: $0)}
        }
    }
}

let complicationDatastore = ComplicationDatastore()

//-----------------------------------------------------------------------------------------
// MARK: - conmplication controller
//-----------------------------------------------------------------------------------------
class ComplicationController: NSObject, CLKComplicationDataSource {
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Timeline Configuration
    //-----------------------------------------------------------------------------------------
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
        //handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
 
    //-----------------------------------------------------------------------------------------
    // MARK: - Timeline Population
    //-----------------------------------------------------------------------------------------

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        if let template = getTemplate(for: complication, withData: complicationDatastore.data) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        }else{
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Placeholder Templates
    //-----------------------------------------------------------------------------------------
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let data : ComplicationData = (
            iconNamePrefix: ICON_NAME_PREFIX_APP,
            portalId: nil,
            portalName: NSLocalizedString("COMPLICATION_TEMPLATE_PLACE_NAME", comment: ""),
            accessory1Name: NSLocalizedString("COMPLICATION_TEMPLATE_ACCESORY1_NAME", comment: ""),
            accessory1Value: NSLocalizedString("COMPLICATION_TEMPLATE_ACCESORY1_VALUE", comment: ""),
            accessory2Name: NSLocalizedString("COMPLICATION_TEMPLATE_ACCESORY2_NAME", comment: ""),
            accessory2Value: NSLocalizedString("COMPLICATION_TEMPLATE_ACCESORY2_VALUE", comment: "")
        )
        let template = getTemplate(for: complication, withData: data)
        handler(template)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - utilities
    //-----------------------------------------------------------------------------------------
    private func getTemplate(for complication: CLKComplication, withData data: ComplicationData) -> CLKComplicationTemplate?{
        var template : CLKComplicationTemplate?
        let gtint = appColor.theme

        switch complication.family {
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallRingImage()
            circularTemplate.tintColor = gtint
            circularTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: data.iconNamePrefix + "Circular")!)
            template = circularTemplate
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
            modularTemplate.tintColor = gtint
            modularTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: data.iconNamePrefix + "ModularSmall")!)
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            modularTemplate.tintColor = gtint
            //modularTemplate.headerImageProvider =
            //    CLKImageProvider(onePieceImage: UIImage(named: data.iconNamePrefix + "ModularLarge")!)
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: data.portalName)
            modularTemplate.row1Column1TextProvider =
                CLKSimpleTextProvider(text: (data.accessory1Name ?? "------") + ":")
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: data.accessory1Value ?? "")
            modularTemplate.row2Column1TextProvider =
                CLKSimpleTextProvider(text: (data.accessory2Name ?? "------") + ":")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: data.accessory2Value ?? "")
            template = modularTemplate
        case .utilitarianLarge:
            let utilityTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilityTemplate.tintColor = gtint
            utilityTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: data.iconNamePrefix + "Utility")!)
            utilityTemplate.textProvider = CLKSimpleTextProvider(text: data.portalName)
            template = utilityTemplate
        case .utilitarianSmallFlat, .utilitarianSmall:
            let utilityTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilityTemplate.tintColor = gtint
            utilityTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: data.iconNamePrefix + "Utility")!)
            utilityTemplate.textProvider = CLKSimpleTextProvider(text: data.portalName)
            template = utilityTemplate
        case .graphicCircular:
            if #available(watchOSApplicationExtension 5.0, *) {
                let graphCircularTemplate = CLKComplicationTemplateGraphicCircularImage()
                graphCircularTemplate.imageProvider =
                    CLKFullColorImageProvider(fullColorImage: UIImage(named: data.iconNamePrefix + "GraphicCircular")!)
                template = graphCircularTemplate
            } else {
                template = nil
            }
        default:
            template = nil
        }

        return template
    }
}
