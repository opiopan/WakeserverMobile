//
//  AddPortalViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/11.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import commonLib

class AddPortalViewController: UITableViewController, WSPBrowserDelegate {
    var addedNotifier : ((Portal)->Void)? = nil
    
    private var sectionHeader : ProgressHeaderViewController? = nil
    private var sectionFooter : SimpleFooterViewController? = nil
    private var browser : WSPBrowser = WSPBrowser()
    private var portals : [Portal] = []
    private let config = ConfigurationController.sharedController

    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionHeader = ProgressHeaderViewController.viewController(self)
        sectionFooter = SimpleFooterViewController.viewController(self)
        
        browser.delegate = self
        browser.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func closeThisView(_ sender : UIBarButtonItem?){
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - WSPBrowserProxy protocol
    //-----------------------------------------------------------------------------------------
    func wspBrowserDetectPortalAdd(browser: WSPBrowser, portal: Portal) {
        if config.registeredPortals.firstIndex(where:{$0.id == portal.id}) == nil {
            portal.updateConfig(){
                [unowned self] (portal:Portal?, error) in
                if let portal = portal {
                    self.portals.append(portal)
                    self.portals = self.portals.sorted{$0.hostName < $1.hostName}
                    let index = self.portals.firstIndex{$0 === portal}
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: index!, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }
            }
            
        }
    }
    
    func wspBrowserDetectPortalDel(browser: WSPBrowser, portal: Portal) {
        if let index = portals.firstIndex(where:{$0.id == portal.id}) {
            portals.remove(at: index)
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            tableView.endUpdates()

        }
        
    }
    
    func wspBrowserDidNotSearch(browser: WSPBrowser, errorDict: [String : NSNumber]) {
        
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return portals.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return 54
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        sectionHeader?.labelText = NSLocalizedString("ADDPORTAL_SECTION_TITLE", comment: "")
        sectionHeader?.startAnimating()
        return sectionHeader?.view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        sectionFooter?.labelText = NSLocalizedString("ADDPORTAL_FOOTER_TEXT", comment: "")
        return sectionFooter?.view
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let portal = portals[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "portalCell", for: indexPath)
        cell.textLabel?.text = portal.hostName
        cell.detailTextLabel?.text = portal.hostDescription
        cell.imageView?.image = PortalPlatform.icon(forKey: portal.platform)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let target = segue.destination as! PortalSettingsViewController
            target.personality = PortalSettingsViewPersonality(
                portal: portals[indexPath.row],
                updateMethod: .bulk){
                    [unowned self] (controller : PortalSettingsViewController) in
                    if let notifier = self.addedNotifier {
                        notifier((controller.personality?.portal)!)
                    }
            }
        }
    }

}
