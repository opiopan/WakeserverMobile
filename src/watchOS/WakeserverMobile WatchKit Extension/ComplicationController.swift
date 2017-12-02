//
//  ComplicationController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/08/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import ClockKit
import commonLibWatch

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
        if let template = getTemplate(for: complication, withName: {placeRecognizer.placeName}) {
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
        let template = getTemplate(for: complication, withName: {
            NSLocalizedString("COMPLICATION_TEMPLATE_PLACE_NAME", comment: "")})
        handler(template)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - utilities
    //-----------------------------------------------------------------------------------------
    private func getTemplate(for complication: CLKComplication, withName name: ()->String) -> CLKComplicationTemplate?{
        var template : CLKComplicationTemplate?
        let gtint = UIColor(red: 90.0/255.0, green: 200.0/255.0, blue: 250.0/255.0, alpha: 1.0)

        switch complication.family {
        case .circularSmall:
            let circularTemplate = CLKComplicationTemplateCircularSmallRingImage()
            circularTemplate.tintColor = gtint
            circularTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: "ComplicationAppCircular")!)
            template = circularTemplate
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
            modularTemplate.tintColor = gtint
            modularTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: "ComplicationAppModularSmall")!)
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            modularTemplate.tintColor = gtint
            modularTemplate.headerImageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: "ComplicationAppModularLarge")!)
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: name())
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "Accessory 1:")
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "On")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "Accessory 2:")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "Off")
            template = modularTemplate
        case .utilitarianLarge:
            let utilityTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            utilityTemplate.tintColor = gtint
            utilityTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: "ComplicationAppUtility")!)
            utilityTemplate.textProvider = CLKSimpleTextProvider(text: name())
            template = utilityTemplate
        case .utilitarianSmallFlat, .utilitarianSmall:
            let utilityTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            utilityTemplate.tintColor = gtint
            utilityTemplate.imageProvider =
                CLKImageProvider(onePieceImage: UIImage(named: "ComplicationAppUtility")!)
            utilityTemplate.textProvider = CLKSimpleTextProvider(text: name())
            template = utilityTemplate
        default:
            template = nil
        }

        return template
    }
}
