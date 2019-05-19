//
//  ExtensionDelegate.swift
//  WakeserverMobile WatchKit Extension
//
//  Created by opiopan on 2017/08/10.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit
import commonLibWatch

enum WatchSize {
    case s38mm
    case s42mm
    case s40mm
    case s44mm
}

func watchSize() -> WatchSize {
    let width = WKInterfaceDevice.current().screenBounds.width
    return width > 162 ? .s44mm :
           width > 156 ? .s40mm :
           width > 136 ? .s42mm :
                         .s38mm
}

var bgTaskBeginDate = Date(timeIntervalSince1970: 0)
var bgTaskEndDate: Date? = Date(timeIntervalSince1970: 0)

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        communicator.start()
        let fireDate = Date(timeIntervalSinceNow: 3)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil){
            error in
            print("bgtask complete")
        }
        print("bgtask schedule date: " + fireDate.description)
    }

    func applicationDidBecomeActive() {
        placeRecognizer.reflesh(nil)
        //placeRecognizer.start()
    }

    func applicationWillResignActive() {
        //placeRecognizer.stop()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                bgTaskBeginDate = Date()
                bgTaskEndDate = nil
                print("bgtask fire date: " + bgTaskBeginDate.description)
                placeRecognizer.reflesh{
                    bgTaskEndDate = Date()
                    let fireDate = Date(timeIntervalSinceNow: 60 * 30)
                    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil){
                        error in
                        print("bgtask complete")
                    }
                    print("bgtask schedule date: " + fireDate.description)
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                }
                //backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
