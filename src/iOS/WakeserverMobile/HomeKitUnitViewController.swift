//
//  HomeKitUnitViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/11.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import HomeKit
import commonLib

class HomeKitUnitViewController: UITableViewController {

    var contextNode : HomeKitNode? {
        didSet{
            title = contextNode?.nodeName
            if (contextNode?.children.count ?? 0) > 0 && contextNode?.children.first?.nodeType == .zone {
                sections = contextNode?.children ?? []
            }
        }
    }
    
    private var sections = [HomeKitNode]()
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func closeThisView(_ sender : UIBarButtonItem?){
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }

    //-----------------------------------------------------------------------------------------
    // MARK: - Table view data source
    //-----------------------------------------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count > 0 ? sections.count : 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections.count > 0 ? sections[section].nodeName : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count > 0 ? sections[section].children.count : contextNode?.children.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = sections.count > 0 ?
            sections[indexPath.section].children[indexPath.row] : contextNode?.children[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "homekitItemCell", for: indexPath)
        cell.textLabel?.text = node?.nodeName
        cell.imageView?.image = node?.preferenceIcon
        if node?.nodeType == .accessory {
            cell.detailTextLabel?.text = "\(node!.service!.localizedDescription): \(node!.accessory!.name)"
            cell.accessoryType = .none
        }else{
            cell.detailTextLabel?.text =
                String(format: NSLocalizedString("ROOM_DESCRIPTION_FORMAT", comment: ""), node?.children.count ?? 0)
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let node = sections.count > 0 ?
            sections[indexPath.section].children[indexPath.row] : contextNode?.children[indexPath.row] {
            if node.nodeType == .accessory {
                let newAccessory = node.portalAccessory()
                performSegue(withIdentifier: "accessorySettingsSegue", sender: newAccessory)
            }else{
                if let newView = storyboard?.instantiateViewController(
                    withIdentifier: "homekitNodeViewController") as? HomeKitUnitViewController {
                    newView.contextNode = node
                    if var controllers = navigationController?.viewControllers {
                        controllers.append(newView)
                        navigationController?.setViewControllers(controllers, animated: true)
                    }
                }
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    //-----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //-----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? OutdoorsAccessorySettingsViewController,
            let accessory = sender as? PortalAccessory{
            let personality = OutdoorsAccessorySettingsViewPersonality(
                accessory: accessory,
                updateMethod: .bulk){
                    controller in
                    let portal = ConfigurationController.sharedController.outdoorsPortal
                    if let accessory = controller.personality?.accessory {
                        portal.homeKitAccessories.append(accessory)
                    }
                    ConfigurationController.sharedController.outdoorsPortal = portal
            }
            target.personality = personality
        }
    }

}
