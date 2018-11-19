//
//  DashboardViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class DashboardViewController: UITableViewController, PlaceRecognizerDelegate, ConfigurationControllerDelegate {
    //-----------------------------------------------------------------------------------------
    // MARK: - class for section definition
    //-----------------------------------------------------------------------------------------
    private class Section{
        public typealias RowNumClosure = () -> Int
        public typealias CellClosure = (_ indexPath: IndexPath) -> UITableViewCell
        public typealias EditableClosure = (_ indexPath: IndexPath) ->Bool
        
        public let name : String?
        public let headerHeight : CGFloat
        public let footerHeight : CGFloat
        public let cellHeight : CGFloat
        public let rowNum : RowNumClosure
        public let cell : CellClosure
        public let editable : EditableClosure
        
        private let PORTALS_SECTION = 1
        
        init(name: String?, headerHeight : CGFloat, footerHeight : CGFloat, cellHeight: CGFloat,
             rowNum: @escaping RowNumClosure, cell: @escaping CellClosure, editable: @escaping EditableClosure) {
            self.name = name
            self.headerHeight = headerHeight
            self.footerHeight = footerHeight
            self.cellHeight = cellHeight
            self.rowNum = rowNum
            self.cell = cell
            self.editable = editable
        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Properties
    //-----------------------------------------------------------------------------------------
    private var sections : [Section] = []
    private let config = ConfigurationController.sharedController
    private var statusCell : DashboardStatusCell?
    private var suspendedUpdateConfiguration = false
    private var isAppeared = false
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Section definitions
        sections = [
            Section(
                name: nil,
                headerHeight: 0.01,
                footerHeight: 48,
                cellHeight: 200,
                rowNum: {1},
                cell: {
                    [unowned self] (indexPath) in
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "statusCell",
                                                                  for: indexPath)
                    self.statusCell = cell as? DashboardStatusCell
                    self.statusCell?.portal = placeRecognizer.currentPortal
                    return cell
                },
                editable: {(_) in false}
            ),
            Section(
                name: NSLocalizedString("PORTAL_SECTION_POTALS", comment: ""),
                headerHeight: 18,
                footerHeight: 1,
                cellHeight: 64,
                rowNum: {
                    [unowned self] () in
                    self.config.registeredPortals.count + 1
                },
                cell: {
                    [unowned self] (indexPath) in
                    if indexPath.row == 0 {
                        let cell = self.tableView.dequeueReusableCell(withIdentifier: "outdoorCell",
                                                                      for: indexPath)
                        return cell
                    }else{
                        let cell = self.tableView.dequeueReusableCell(withIdentifier: "portalCell",
                                                                      for: indexPath)
                        let portal = self.config.registeredPortals[indexPath.row - 1]
                        cell.textLabel?.text = portal.name
                        cell.detailTextLabel?.text = portal.hostDescription
                        cell.imageView?.image = PortalPlatform.icon(forKey: portal.platform)
                        return cell
                    }
                },
                editable: {
                    (indexPath) in
                    indexPath.row != 0
                }
            ),
            Section(
                name: nil,
                headerHeight: 18,
                footerHeight: 18,
                cellHeight: 44,
                rowNum: {1},
                cell: {
                    [unowned self] (indexPath) in
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: "buttonCell",
                                                                  for: indexPath) as! ButtonCell
                    cell.buttonTitle = NSLocalizedString("PORTAL_BUTTON_ADD", comment: "")
                    cell.buttonUpHandler = {
                        [unowned self] () in
                        self.performSegue(withIdentifier: "addPortalSegue", sender: nil)
                    }
                    return cell
                },
                editable: {(_) in false}
            )
        ]

        placeRecognizer.register(delegate: self)
        statusCell?.portal = placeRecognizer.currentPortal
        ConfigurationController.sharedController.register(delegate: self)
    }
    
    deinit {
        placeRecognizer.unregister(delegate: self)
        ConfigurationController.sharedController.unregister(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isAppeared = true
        if suspendedUpdateConfiguration {
            suspendedUpdateConfiguration = false
            placeRecognizer.updatePortalConfig()
        }
        placeRecognizer.rescan()
        statusCell?.startObservation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isAppeared = false
        super.viewWillDisappear(animated)
        statusCell?.endObservation()
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rowNum()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].cell(indexPath)
    }

    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return sections[section].headerHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sections[section].footerHeight
    }

    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sections[indexPath.section].cellHeight
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view editing
    //-----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].editable(indexPath)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(
                title: NSLocalizedString("PORTAL_DELETE_TITLE", comment: ""),
                message: NSLocalizedString("PORTAL_DELETE_MESSAGE", comment: ""),
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default){
                [unowned self] action in
                var portals = self.config.registeredPortals
                portals.remove(at: indexPath.row - 1)
                self.config.registeredPortals = portals
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            alert.addAction(okAction)
            let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)

        }
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Portal changing
    //-----------------------------------------------------------------------------------------
    func placeRecognizerDetectChangePortal(recognizer: PlaceRecognizer, portal: Portal) {
        statusCell?.portal = portal
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Configuration changing
    //-----------------------------------------------------------------------------------------
    func configurationDidChanged(kind: ConfigurationUpdateKind) {
        if isAppeared {
            placeRecognizer.updatePortalConfig()
        }else{
            suspendedUpdateConfiguration = true
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigator = segue.destination as? UINavigationController {
            if let target = navigator.topViewController as? AddPortalViewController {
                target.addedNotifier = {
                    [unowned self] (portal: Portal) in
                    var portals = self.config.registeredPortals
                    portals.append(portal)
                    self.config.registeredPortals = portals
                    self.tableView.reloadData()
                }
            }
        }else if let target = segue.destination as? PortalSettingsViewController {
            let portal = config.registeredPortals[tableView.indexPathForSelectedRow!.row - 1]
            target.personality = PortalSettingsViewPersonality(
                portal: portal,
                updateMethod: .immediately,
                changeNotifier: {
                    [unowned self] (controller) in
                    self.config.registeredPortals = self.config.registeredPortals
                    self.tableView.reloadData()
                }
            )
        }
    }

}
