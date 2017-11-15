//
//  OutdoorsSettingsViewController.swift
//  WakeserverMobile
//
//  Created by Hiroshi Murayama on 2017/11/09.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class OutdoorsSettingsViewController: UITableViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addAccessoryButton: UIButton!
    private let ACCESSSORY_SECTION = 1
    
    private var sections : [Section] = []
    private var addAccessorySectionFooter : SimpleFooterViewController?
    
    private var config = ConfigurationController.sharedController
    
    private var homeKitManager : HomeKitNodeManager?
    private var homeKitRoot : HomeKitNode?

    //-----------------------------------------------------------------------------------------
    // MARK: - class for section definition
    //-----------------------------------------------------------------------------------------
    private class Section{
        public typealias ViewControllerClosure = () -> UIView
        
        public let headerHeight : CGFloat
        public let footerHeight : CGFloat
        public let header : ViewControllerClosure?
        public let footer : ViewControllerClosure?
        public let editable : Bool
        
        private let PORTALS_SECTION = 1
        
        init(headerHeight : CGFloat, footerHeight : CGFloat, editable: Bool,
             header: ViewControllerClosure?, footer: ViewControllerClosure?) {
            self.headerHeight = headerHeight
            self.footerHeight = footerHeight
            self.editable = editable
            self.header = header
            self.footer = footer
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addAccessorySectionFooter = SimpleFooterViewController.viewController(self)
        addAccessorySectionFooter?.labelText = NSLocalizedString("OUTDOORS_ADD_ACCESSORY_FOOTER_TEXT", comment: "")
        
        sections = [
            Section(headerHeight: 0, footerHeight: 0, editable: false, header: nil, footer: nil),
            Section(headerHeight: 32, footerHeight: 10, editable: true, header: nil, footer: nil),
            Section(headerHeight: 10, footerHeight: 80, editable: false, header: nil){ [unowned self] in
                return self.addAccessorySectionFooter!.view
            },
        ]
        
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homeKitManager = nil
        homeKitRoot = nil
        updateView()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - View / Data update
    //-----------------------------------------------------------------------------------------
    private func updateView() {
        nameLabel?.text = config.outdoorsPortal.displayName
        addAccessoryButton.isEnabled = (config.outdoorsPortal.homeKitAccessories.count ) < 4
        tableView.reloadData()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - actions
    //-----------------------------------------------------------------------------------------
    @IBAction func onAddAccessory(_ sender: Any) {
        homeKitManager = HomeKitNodeManager{
            [unowned self] manager in
            self.homeKitRoot = manager.homes()
            if self.homeKitRoot?.children.count == 0 {
                let alert = UIAlertController(
                    title: NSLocalizedString("NO_HOMEKIT_TITLE", comment: ""),
                    message: NSLocalizedString("NO_HOMEKIT_MESSAGE", comment: ""),
                    preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }else if self.homeKitRoot?.children.count == 1 {
                self.homeKitRoot = self.homeKitRoot?.children.first
            }
            self.performSegue(withIdentifier: "addAccessorySegue", sender: nil)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return super.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].headerHeight
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].footerHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return sections[section].footer?()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == ACCESSSORY_SECTION {
            return config.outdoorsPortal.homeKitAccessories.count
        }
        return  super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == ACCESSSORY_SECTION {
            return super.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: indexPath.section - 1))
        }else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == ACCESSSORY_SECTION {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            let page = config.outdoorsPortal.homeKitAccessories[indexPath.row]
            cell.textLabel?.text = page.name
            cell.imageView?.image = page.preferenceIcon
            return cell
        }else{
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        if indexPath.section == ACCESSSORY_SECTION {
            return super.tableView(tableView, indentationLevelForRowAt: IndexPath(row: 0, section: indexPath.section - 1))
        }else{
            return super.tableView(tableView, indentationLevelForRowAt: indexPath)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table selection
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == ACCESSSORY_SECTION {
            HomeKitManager.sharedManager.waitForInitialize{
                [unowned self] _ in
                self.performSegue(withIdentifier: "accessorySettingsSegue", sender: indexPath)
            }
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view editing
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return sections[indexPath.section].editable ? .delete : .none
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].editable
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let portal = config.outdoorsPortal
            portal.homeKitAccessories.remove(at: indexPath.row)
            config.outdoorsPortal = portal
            tableView.deleteRows(at: [indexPath], with: .fade)
            UIView.transition(with: addAccessoryButton, duration: 0.5, options:.transitionCrossDissolve, animations: {
                self.addAccessoryButton.isEnabled = (self.config.outdoorsPortal.homeKitAccessories.count ) < 4
            }, completion: nil)
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? InputStringViewController {
            target.personality = InputStringViewControllerPersonality(
                title: NSLocalizedString("PORTAL_NAME_EDIT_TITLE", comment: ""),
                initial: config.outdoorsPortal.name,
                placehodlder: OutdoorsPortal.defaultName){
                    [unowned self] name in
                    let portal = self.config.outdoorsPortal
                    portal.name = name ?? ""
                    self.config.outdoorsPortal = portal
                    self.updateView()
            }
        }else if let navigator = segue.destination as? UINavigationController,
            let target = navigator.topViewController as? HomeKitUnitViewController {
            target.contextNode = homeKitRoot
            updateView()
        }else if let target = segue.destination as? OutdoorsAccessorySettingsViewController,
            let indexPath = sender as? IndexPath{
            target.personality = OutdoorsAccessorySettingsViewPersonality(
                accessory: config.outdoorsPortal.homeKitAccessories[indexPath.row],
                updateMethod: .immediately){
                    [unowned self] controller in
                    let portal = self.config.outdoorsPortal
                    portal.homeKitAccessories[indexPath.row] = (controller.personality?.accessory)!
                    self.config.outdoorsPortal = portal
            }
        }
    }

}
