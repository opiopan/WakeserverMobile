//
//  Portal.swift
//  commonLib
//
//  Created by opiopan on 2017/10/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

//-----------------------------------------------------------------------------------------
// MARK: - Portal informain representation
//-----------------------------------------------------------------------------------------
open class Portal : LooseSerializable {
    open var name: String
    open let domain: String
    open let hostName: String
    open let id: String?
    open let hostDescription: String?
    open let platform: String?
    open let configHash: String?
    open let serversHash: String?
    open var config : PortalConfig?
    open var isEnableBeacon : Bool = true
    open var defaultPage : Int = 0
    
    #if os(iOS)
    open var service: NetService?
    #elseif os(watchOS)
    open var service : (name: String, domain: String, port: Int)?
    #endif

    open var displayName : String {
        get {
            return name
        }
    }
    
    open var isOutdoors : Bool{
        get {
            return self as? OutdoorsPortal != nil
        }
    }
    
    open var backgroundImage : UIImage? {
        get {
            if isOutdoors {
                return libBundleImage(name: "background_image_outdoors")
            }else{
                var image : UIImage? = nil
                if let background = config?.background, let svc = service,
                    let url = URL(string: "http://\(svc.name).\(svc.domain):\(svc.port)/\(background)"),
                    let data = try? Data(contentsOf: url){
                    image = UIImage(data: data)
                }
                return image
            }
        }
    }
    
    open var dashboardAccessory : DashboardAccessory? {
        get {
            if let index = config?.pages.index(where: {$0 as? DashboardAccessory != nil}) {
                return config?.pages[index] as? DashboardAccessory
            }else{
                return nil
            }
        }
    }
    
    open var pages : [PortalAccessory]? {
        return config?.pages
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Initializing / Serializing / Deserializing
    //-----------------------------------------------------------------------------------------
    public init() {
        name = ""
        domain = ""
        hostName = ""
        id = nil
        hostDescription = nil
        platform = nil
        configHash = nil
        serversHash = nil
    }

    #if os(iOS)
    public init(service : NetService) {
        self.service = service
        
        self.name = service.name
        self.domain = service.domain
        self.hostName = service.name
        
        var id : String? = nil
        var description : String? = nil
        var platform : String? = nil
        var configHash : String? = nil
        var serversHash : String? = nil
        let txtdata = service.txtRecordData()
        if txtdata != nil {
            let txt = NetService.dictionary(fromTXTRecord: txtdata!)
            if let value = txt["id"] {
                id = String(data: value, encoding: .utf8)
            }
            if let value = txt["desc"] {
                description = String(data: value, encoding: .utf8)
            }
            if let value = txt["platform"] {
                platform = String(data: value, encoding: .utf8)
            }
            if let value = txt["confighash"] {
                configHash = String(data: value, encoding: .utf8)
            }
            if let value = txt["servershash"] {
                serversHash = String(data: value, encoding: .utf8)
            }
        }
        
        self.id = id
        self.hostDescription = description
        self.platform = platform
        self.configHash = configHash
        self.serversHash = serversHash
    }
    #endif
    
    public required init(dict : [String : Any]) throws{
        name = dict["name"] as! String
        domain = dict["domain"] as! String
        hostName = dict["host_name"] as! String
        
        let strValue = {
            (key : String) -> String? in
            if let value = dict[key] as! String?{
                return value
            }else{
                return nil
            }
        }
        
        id = strValue("id")
        hostDescription = strValue("host_description")
        platform = strValue("platform")
        configHash = strValue("config_hash")
        serversHash = strValue("servers_hash")
        if let value = dict["is_enable_beacon"] as? Bool {isEnableBeacon = value}
        if let value = dict["default_page"] as? Int {defaultPage = value}
        if let dict = dict["config"] as? [String:Any] {
            try! config = PortalConfig(dict: dict)
        }
    }

    open var dictionary: [String : Any] {
        get{
            var dict : [String : Any] = [
                "name" : name,
                "domain" : domain,
                "host_name" : hostName,
                "is_enable_beacon" : isEnableBeacon,
                "default_page" : defaultPage,
            ]
            if let value = id {dict["id"] = value}
            if let value = hostDescription {dict["host_description"] = value}
            if let value = platform {dict["platform"] = value}
            if let value = configHash {dict["config_hash"] = value}
            if let value = serversHash {dict["servers_hash"] = value}
            if let value = config {dict["config"] = value.dictionary}

            return dict
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Configulation reflecting
    //-----------------------------------------------------------------------------------------
    public typealias UpdateConfigNotifier = (Portal?, PortalConfigError?)->Void
    
    private var updateConfigNotifier : UpdateConfigNotifier?
    
    open func updateConfig(notifier : UpdateConfigNotifier?) {
        let callback : UpdateConfigNotifier = {
            [unowned self] portal, error in
            DispatchQueue.main.async {
                self.updateConfigNotifier?(portal, error)
            }
        }

        guard updateConfigNotifier == nil && service != nil else{
            abort()
        }
        updateConfigNotifier = notifier
        
        self.config = nil

        let urlprefix = "http://\(service!.name).\(service!.domain):\(service!.port)"
        let components = URLComponents(string: "\(urlprefix)/cgi-bin/wakeserver-config.cgi")
        let task = URLSession.shared.dataTask(with: components!.url!){
            [unowned self] data, response, error in
            guard let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 else {
                callback(nil, .serverAccessFailed(LocalizedString("MSG_ERR_SERVERACCESS")))
                return
            }

            var deferedError : PortalConfigError? = nil
            do {
                try self.config = PortalConfig(data)
            }catch PortalConfigError.partialyInconsistentData(let msg) {
                deferedError = PortalConfigError.partialyInconsistentData(msg)
            }catch PortalConfigError.invalidFormat(let msg){
                callback(nil, .invalidFormat(msg))
                return
            }catch {
                callback(nil, .otherError(LocalizedString("FAILED_PARSE")))
                return
            }
            
            var components = URLComponents(string: "\(urlprefix)/cgi-bin/wakeserver-get.cgi")
            components?.queryItems = [URLQueryItem(name:"type", value:"full")]
            let task = URLSession.shared.dataTask(with: components!.url!){
                [unowned self] data, response, error in
                guard let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 else {
                    callback(nil, .serverAccessFailed(LocalizedString("MSG_ERR_SERVERACCESS")))
                    return
                }
                
                do {
                    try self.config?.reflectServersConfig(data)
                }catch PortalConfigError.partialyInconsistentData(let msg) {
                    deferedError = PortalConfigError.partialyInconsistentData(msg)
                }catch PortalConfigError.invalidFormat(let msg){
                    callback(nil, .invalidFormat(msg))
                    return
                }catch {
                    callback(nil, .otherError(LocalizedString("FAILED_PARSE")))
                    return
                }
                
                callback(self, deferedError)
            }
            task.resume()
        }
        task.resume()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Reflecting options
    //-----------------------------------------------------------------------------------------
    open func reflectOption(of portal: Portal) {
        name = portal.name
        isEnableBeacon = portal.isEnableBeacon
        if let index = (config?.pages.index{$0.name == portal.config?.pages[portal.defaultPage].name}) {
            defaultPage = index
        }
        config?.pages.forEach{ page in
            if let index = (portal.config?.pages.index{$0.name == page.name}) {
                page.reflectOption(of: (portal.config?.pages[index])!)
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Status updating
    //-----------------------------------------------------------------------------------------
    public typealias UpdateStatusNotifier = () -> Void

    private var isUpdatingStatus = false
    private var updateStatusNotifiers  = [UpdateStatusNotifier]()
    
    open func updateStatus(notifier: UpdateStatusNotifier?){
        guard !isUpdatingStatus else{
            if let notifier = notifier {
                updateStatusNotifiers.append(notifier)
            }
            return
        }

        isUpdatingStatus = true
        if let notifier = notifier {
            updateStatusNotifiers.append(notifier)
        }
        
        guard let service = service else {
            endUpdateStatus()
            return
        }
        
        let urlprefix = "http://\(service.name).\(service.domain):\(service.port)"
        var components = URLComponents(string: "\(urlprefix)/cgi-bin/wakeserver-get.cgi")
        components?.queryItems = [URLQueryItem(name:"type", value:"simple")]
        let task = URLSession.shared.dataTask(with: components!.url!){
            [unowned self] data, response, error in
            guard let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 else {
                self.endUpdateStatus()
                return
            }
            do {
                let root = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [Any]
                self.config?.pages.forEach{
                    $0.reflectPowerStatus(statuses: root)
                }
                self.endUpdateStatus()
            }catch {
                self.endUpdateStatus()
                return
            }
        }
        task.resume()
    }
    
    private func endUpdateStatus() {
        updateStatusNotifiers.forEach{$0()}
        updateStatusNotifiers = []
        isUpdatingStatus = false
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Characteristic status updating
    //-----------------------------------------------------------------------------------------
    private var nextCharacteristicStatusUpdatee = -1
    
    public func updateCharacteristicStatus(notifier: (()->Void)?) {
        guard nextCharacteristicStatusUpdatee < 0 else {
            notifier?()
            return
        }
        nextCharacteristicStatusUpdatee = 0
        updatePageCharacteristicStatus(notifier: notifier)
    }
    
    private func updatePageCharacteristicStatus(notifier: (()->Void)?) {
        guard let pages = pages, nextCharacteristicStatusUpdatee < pages.count else {
            nextCharacteristicStatusUpdatee = -1
            notifier?()
            return
        }
        let target = pages[nextCharacteristicStatusUpdatee]
        nextCharacteristicStatusUpdatee += 1
        target.updateCharacteristicStatus(portal: self) {
            [unowned self] in
            self.updatePageCharacteristicStatus(notifier: notifier)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Power controll command management
    //-----------------------------------------------------------------------------------------
    func sendPowerControllCommand(forAccessory accessory: PortalAccessory, power: Bool, callback: ((Bool)->Void)?) {
        guard let service = service,
            let server = accessory.server,
            (power == true && accessory.isWakeable) || (power == false && accessory.isSleepable) else {
            callback?(false)
            return
        }
            
        let urlprefix = "http://\(service.name).\(service.domain):\(service.port)"
        let urlsuffix = power ? "wakeserver-wake.cgi" : "wakeserver-sleep.cgi"
        var components = URLComponents(string: "\(urlprefix)/cgi-bin/\(urlsuffix)")
        components?.queryItems = [
            URLQueryItem(name:"target", value: server),
        ]
        let task = URLSession.shared.dataTask(with: components!.url!){
            data, response, error in
            
            guard data != nil, let response = response, (response as! HTTPURLResponse).statusCode == 200 else {
                callback?(false)
                return
            }
            callback?(true)
        }
        task.resume()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Attribute cgi management
    //-----------------------------------------------------------------------------------------
    enum PortalCommError{
        case overriden
        case serverResponseError
        case invalidResponse
    }
    
    typealias AttributeCommandResult = (result: Bool, value: String?, message: String)
    typealias AttributeCommand = (
        server: String,attribute: String, value: (()->String)?,
        callback: ((AttributeCommandResult?, PortalCommError?) -> Void)?)

    private var attributeCommandQue = [AttributeCommand]()
    private var attributeCommandTask: URLSessionDataTask?

    func sendAttributeCommand(_ command: AttributeCommand, withOverride override: Bool) {
        DispatchQueue.main.async {
            [unowned self] in
            if override {
                let index = self.attributeCommandQue.index(where: {
                    $0.server == command.server && $0.attribute == command.attribute &&
                    (($0.value == nil && command.value == nil) || ($0.value != nil && command.value != nil))
                })
                if let index = index {
                    self.attributeCommandQue[index].callback?(nil, .overriden)
                    self.attributeCommandQue[index] = command
                }else{
                    self.attributeCommandQue.append(command)
                }
            }else{
                self.attributeCommandQue.append(command)
            }
            self.scheduleAttributeCommand()
        }
    }

    private func scheduleAttributeCommand(){
        guard attributeCommandTask == nil, let service = service, let command = attributeCommandQue.first else {
            return
        }
        
        attributeCommandQue.removeFirst()

        let urlprefix = "http://\(service.name).\(service.domain):\(service.port)"
        var components = URLComponents(string: "\(urlprefix)/cgi-bin/wakeserver-attribute.cgi")
        var queryItems = [
            URLQueryItem(name:"target", value: command.server),
            URLQueryItem(name:"attribute", value: command.attribute)
        ]
        if let value = command.value {
            queryItems.append(URLQueryItem(name: "value", value: value()))
        }
        components?.queryItems = queryItems
        attributeCommandTask = URLSession.shared.dataTask(with: components!.url!){
            [unowned self] data, response, error in
            self.attributeCommandTask = nil
            
            if let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 {
                do {
                    let root = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any]
                    if let root = root{
                        if let result = root["result"] as? Bool {
                            let value = root["value"] as? String
                            let message = root["message"] as? String ?? ""
                            let commandResult = (result: result, value: value, message: message)
                            command.callback?(commandResult, nil)
                        }else{
                            command.callback?(nil, .invalidResponse)
                        }
                    }else{
                        command.callback?(nil, .invalidResponse)
                    }
                }catch {
                    command.callback?(nil, .invalidResponse)
                }
            }else{
                command.callback?(nil, .serverResponseError)
            }
            
            DispatchQueue.main.async {
                self.scheduleAttributeCommand()
            }
        }
        attributeCommandTask?.resume()
    }
}

//-----------------------------------------------------------------------------------------
// MARK: - Portal for outdoors
//-----------------------------------------------------------------------------------------
open class OutdoorsPortal : Portal{

    open var homeKitAccessories : [PortalAccessory] = []

    open class var defaultName : String {
        get {
            return LocalizedString("OUTDOORSPORTAL_NAME")
        }
    }

    override open var displayName: String {
        get {
            return  name == "" ? OutdoorsPortal.defaultName :name
        }
    }
    
    override open var dashboardAccessory: DashboardAccessory? {
        get{
            return DashboardAccessory(units: homeKitAccessories)
        }
    }
    
    override open var pages: [PortalAccessory]? {
        get {
            if let dashboard = dashboardAccessory {
                return [dashboard]
            }else{
                return nil
            }
        }
    }
    
    public override init(){
        super.init()
    }
    
    public required init(dict: [String : Any]) throws {
        try super.init(dict: dict)
        if let accessories = dict["home_kit_accessories"] as? [Any] {
            homeKitAccessories = try accessories.flatMap{
                input -> PortalAccessory? in
                guard let dict = input as? [String : Any],
                    let type = dict["type"] as? String,
                    let create = portalAccessories[type]?.create else{
                        return nil
                }
                return try create(dict)
            }
        }
    }
    
    override open var dictionary: [String : Any] {
        get {
            var dict = super.dictionary
            dict["home_kit_accessories"] = homeKitAccessories.map{$0.dictionary}
            return dict
        }
    }
}
