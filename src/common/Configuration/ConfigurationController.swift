//
//  ConfigurationController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/24.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

public let AppGroupID = "group.com.opiopan.WakeserverMobile"

//-----------------------------------------------------------------------------------------
// MARK: - Delegate protocol
//--------------------------------------------------------------------------------------
public enum ConfigurationUpdateKind {
    case registeredPortals
    case outdoorsPortal
}

public protocol ConfigurationControllerDelegate : AnyObject {
    func configurationDidChanged(kind: ConfigurationUpdateKind)
}

//-----------------------------------------------------------------------------------------
// MARK: - Key name for each user defaults value
//--------------------------------------------------------------------------------------
public struct UserDefaults {
    static public let RegisteredPortals = "RegisteredPortalsDict"
    static public let OutdoorsPortal = "OutdoorsPortalDict"
}

//-----------------------------------------------------------------------------------------
// MARK: - Controller to access app configuration
//-----------------------------------------------------------------------------------------
open class ConfigurationController : NSObject {
    static public let sharedController = ConfigurationController()
    
    private let defaults : [String:Any]
    private let controller = Foundation.UserDefaults(suiteName: AppGroupID)!
    private var delegates = [ConfigurationControllerDelegate]()

    //-----------------------------------------------------------------------------------------
    // MARK: - delegates operation
    //--------------------------------------------------------------------------------------
    open func register(delegate: ConfigurationControllerDelegate) {
        if (delegates.index{$0 === delegate}) == nil {
            delegates.append(delegate)
        }
    }
    
    open func unregister(delegate: ConfigurationControllerDelegate) {
        if let index = (delegates.index{$0 === delegate}) {
            delegates.remove(at: index)
        }
    }
    
    private func callDelegate(withUpdateKind kind: ConfigurationUpdateKind) {
        delegates.forEach{$0.configurationDidChanged(kind: kind)}
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - initalization
    //-----------------------------------------------------------------------------------------
    override init(){
        //-----------------------------------------------------------------------------------------
        // default value definition
        //-----------------------------------------------------------------------------------------
        defaults = [
            UserDefaults.RegisteredPortals : [] as! [[String : Any]],
            UserDefaults.OutdoorsPortal : OutdoorsPortal().dictionary,
        ]

        controller.register(defaults: defaults)
        
        //-----------------------------------------------------------------------------------------
        // load data
        //-----------------------------------------------------------------------------------------
        registeredPortals =
            (controller.value(forKey: UserDefaults.RegisteredPortals) as! [[String : Any]])
                .map{try! Portal(dict: $0)}
        outdoorsPortal =
            try! OutdoorsPortal(dict:(controller.value(forKey: UserDefaults.OutdoorsPortal) as! [String : Any]))
        
        super.init()
    }
    
    open var syncCount = 0
    
    open func updagteAll(with dictionary: [String : Any]) {
        let reflect : (String) -> Void = {key in
            self.controller.setValue(dictionary[key], forKey: key)
        }
        reflect(UserDefaults.RegisteredPortals)
        reflect(UserDefaults.OutdoorsPortal)
        syncCount += 1
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - sync to watch
    //-----------------------------------------------------------------------------------------
    private func syncToWatch(){
        #if os(iOS)
            IPC.session.syncConfiguration()
        #endif
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - properties (save data)
    //-----------------------------------------------------------------------------------------
    open var dictionaryRepresentation : [String : Any] {
        get {
            /*
            return [
                UserDefaults.RegisteredPortals : controller.value(forKey: UserDefaults.RegisteredPortals)!,
                UserDefaults.OutdoorsPortal : controller.value(forKey: UserDefaults.OutdoorsPortal)!,
            ]
             */
            return controller.dictionaryRepresentation()
        }
    }
    
    open var registeredPortals : [Portal] {
        didSet{
            controller.setValue(registeredPortals.map{$0.dictionary}, forKey: UserDefaults.RegisteredPortals)
            callDelegate(withUpdateKind: .registeredPortals)
            syncToWatch()
        }
    }
    
    open var outdoorsPortal : OutdoorsPortal {
        didSet{
            controller.setValue(outdoorsPortal.dictionary, forKey: UserDefaults.OutdoorsPortal)
            callDelegate(withUpdateKind: .outdoorsPortal)
            syncToWatch()
        }
    }
}
