//
//  PortalSettingsViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/10/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class PortalSettingsViewPersonality {
    public enum UpdateMethod {
        case immediately
        case bulk
    }
    typealias ChangeNotifier = (_ controller : PortalSettingsViewController) -> Void
    
    public let portal: Portal
    public let updateMethod: UpdateMethod
    public let changeNotifier : ChangeNotifier?
    
    init(portal: Portal, updateMethod: UpdateMethod, changeNotifier: ChangeNotifier?) {
        self.portal = portal
        self.updateMethod = updateMethod
        self.changeNotifier = changeNotifier
    }
}

class PortalSettingsViewController: UITableViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var beaconSwitch: UISwitch!
    @IBOutlet weak var defaultAccessoryLabel: UILabel!
    
    var personality : PortalSettingsViewPersonality? {
        didSet{
            updateView()
        }
    }
    
    private var sections : [Section] = []
    private var beaconSectionFooter : SimpleFooterViewController?

    //-----------------------------------------------------------------------------------------
    // MARK: - class for section definition
    //-----------------------------------------------------------------------------------------
    private class Section{
        public typealias ViewControllerClosure = () -> UIView
        
        public let headerHeight : CGFloat
        public let footerHeight : CGFloat
        public let header : ViewControllerClosure?
        public let footer : ViewControllerClosure?
        
        private let PORTALS_SECTION = 1
        
        init(headerHeight : CGFloat, footerHeight : CGFloat,
             header: ViewControllerClosure?, footer: ViewControllerClosure?) {
            self.headerHeight = headerHeight
            self.footerHeight = footerHeight
            self.header = header
            self.footer = footer
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()

        beaconSectionFooter = SimpleFooterViewController.viewController(self)
        beaconSectionFooter?.labelText = NSLocalizedString("PORTAL_SEATTING_BEACON_FOOTER_TEXT", comment: "")

        sections = [
            Section(headerHeight: 0, footerHeight: 0, header: nil, footer: nil),
            Section(headerHeight: 0, footerHeight: 0, header: nil, footer: nil),
            Section(headerHeight: 0, footerHeight: 80, header: nil){ [unowned self] in
                return self.beaconSectionFooter!.view
            },
            Section(headerHeight: 0, footerHeight: 0, header: nil, footer: nil),
        ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func closeThisView(_ sender : UIBarButtonItem?){
        updateData(force: true)
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View / Data update
    //-----------------------------------------------------------------------------------------
    private func updateView() {
        nameLabel?.text = personality?.portal.name
        descriptionLabel?.text = personality?.portal.hostDescription
        hostNameLabel?.text = personality?.portal.hostName
        platformLabel?.text = PortalPlatform.name(forKey: personality?.portal.platform)
        defaultAccessoryLabel?.text = personality?.portal.config?.pages[(personality?.portal.defaultPage)!].name
        beaconSwitch?.isOn = (personality?.portal.isEnableBeacon)!
        if personality?.updateMethod == .immediately {
            navigationItem.rightBarButtonItem = nil
        }
     }
    
    private func updateData(force: Bool){
        if force || personality?.updateMethod == .immediately {
            personality?.changeNotifier?(self)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = super.numberOfSections(in: tableView)
        if let config = personality?.portal.config, config.pages.count > 0 {
            return count
        }else{
            return count - 1
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].footerHeight
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].footer?()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == super.numberOfSections(in: tableView) - 1 {
            if let config = personality?.portal.config {
                return config.pages.count
            }else{
                return 0
            }
        }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == super.numberOfSections(in: tableView) - 1 {
            return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section - 1))
        }else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == super.numberOfSections(in: tableView) - 1 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            if let pages = personality?.portal.config?.pages {
                let page = pages[indexPath.row]
                cell.textLabel?.text = page.name
                cell.imageView?.image = page.preferenceIcon
            }
            return cell
        }else{
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if indexPath.section == super.numberOfSections(in: tableView) - 1 {
            return super.tableView(tableView, indentationLevelForRowAt: IndexPath(row: 0, section: indexPath.section - 1))
        }else{
            return super.tableView(tableView, indentationLevelForRowAt: indexPath)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Process corresponding to cell state change
    //-----------------------------------------------------------------------------------------
    @IBAction func onBeaconSwichChanged(_ sender: Any) {
        personality?.portal.isEnableBeacon = (sender as! UISwitch).isOn
        self.updateData(force: false)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? InputStringViewController {
            target.personality = InputStringViewControllerPersonality(
                title: NSLocalizedString("PORTAL_NAME_EDIT_TITLE", comment: ""),
                initial: personality?.portal.name,
                placehodlder: personality?.portal.name){
                    [unowned self] (name) in
                    if name != nil  && name != "" {
                        self.personality?.portal.name = name!
                        self.updateView()
                        self.updateData(force: false)
                    }
                }
        }else if let target = segue.destination as? ItemSelectorViewController {
            if let targetCell = tableView.cellForRow(at: tableView.indexPathForSelectedRow!) {
                if let identifier = targetCell.reuseIdentifier, identifier == "defaultAccessoryCell" {
                    let portal = personality!.portal
                    let identity = ItemSelectorIdentity()
                    identity.title = targetCell.textLabel?.text
                    identity.selectionIndex = portal.defaultPage
                    identity.items = portal.config?.pages.map{$0.name}
                    identity.icons = portal.config?.pages.map{$0.preferenceIcon}
                    identity.changeNotifier = {
                        [unowned self] identity, index in
                        portal.defaultPage = index
                        self.updateView()
                        self.updateData(force: false)
                    }
                    target.identity = identity
                }
            }
        }
    }

}
