//
//  InterfaceController.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/08/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import Foundation
import commonLibWatch


class DebugSheetController: WKInterfaceController, PlaceRecognizerDelegate {
    @IBOutlet var bgTaskLabel: WKInterfaceLabel!
    @IBOutlet var placeLabel: WKInterfaceLabel!
    @IBOutlet var stateLabel: WKInterfaceLabel!
    @IBOutlet var characteristicsLabel: WKInterfaceLabel!
    @IBOutlet var transactionLabel: WKInterfaceLabel!
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    private var isShowing = false
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
   }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        isShowing = true
        placeRecognizer.register(delegate: self)
        updateView()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        isShowing = false
        super.didDeactivate()
    }
    
    func placeRecognizerDetectChangePortal(recognizer: PlaceRecognizer, place: PlaceType) {
        updateView()
    }
    
    @IBAction func onMenuItem() {
    }
    
    @IBAction func onReloadButton() {
        updateView()
    }
    
    private func updateView() {
        guard isShowing else {
            return
        }
        
        self.setTitle(placeRecognizer.placeName)
        bgTaskLabel.setText(String(format:"bg: %.1fm, %@", bgTaskBeginDate.timeIntervalSinceNow / -60,
                                   (bgTaskEndDate == nil) ?
                                    "---":
                                    String(format: "%.1fm", bgTaskEndDate!.timeIntervalSinceNow / -60)))
        let updateDate = placeRecognizer.updateTime
        placeLabel.setText(String(format:"Place: %.1fm", updateDate.place.timeIntervalSinceNow / -60))
        stateLabel.setText(String(format:"State: %.1fm", updateDate.state.timeIntervalSinceNow / -60))
        characteristicsLabel.setText(String(format:"Char: %.1fm", updateDate.characeristics.timeIntervalSinceNow / -60))
        transactionLabel.setText(String(format:"Tran: %.1fm, %@", updateDate.begin.timeIntervalSinceNow / -60,
                                        (updateDate.end == nil) ?
                                        "---":
                                            String(format: "%.1fm", updateDate.end!.timeIntervalSinceNow / -60)))
        errorLabel.setText(String(format:"Error: %@", (updateDate.error?.description()) ?? ""))
    }
}
