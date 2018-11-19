//
//  OutdoorsAccessorySettingsViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/12.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import HomeKit
import commonLib

class OutdoorsAccessorySettingsViewPersonality {
    public enum UpdateMethod {
        case immediately
        case bulk
    }
    typealias ChangeNotifier = (_ controller : OutdoorsAccessorySettingsViewController) -> Void
    
    public let accessory: PortalAccessory
    public let updateMethod: UpdateMethod
    public let changeNotifier : ChangeNotifier?
    
    init(accessory: PortalAccessory, updateMethod: UpdateMethod, changeNotifier: ChangeNotifier?) {
        self.accessory = accessory
        self.updateMethod = updateMethod
        self.changeNotifier = changeNotifier
    }
}

class OutdoorsAccessorySettingsViewController: UITableViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var accessoryNameLabel: UILabel!
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    
    private let iconIndex = IndexPath(row: 1, section: 0)
    
    var foo : String?
    var personality : OutdoorsAccessorySettingsViewPersonality? {
        didSet{
            updateView()
        }
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View Open / Close
    //-----------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeThisView(_ sender : UIBarButtonItem?){
        updateData(force: true)
        self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - View / Data update
    //-----------------------------------------------------------------------------------------
    private func updateView() {
        nameLabel?.text = personality?.accessory.name
        typeLabel?.text = personality?.accessory.hmService?.localizedDescription
        roomNameLabel?.text = personality?.accessory.hmService?.accessory?.room?.name
        homeNameLabel?.text = personality?.accessory.hmHome?.name
        
        accessoryNameLabel?.text = personality?.accessory.hmService?.accessory?.name
        manufacturerLabel?.text = personality?.accessory.hmService?.accessory?.manufacturer
        modelLabel?.text = personality?.accessory.hmService?.accessory?.model
        
        let image = Graphics.coloringFilter.apply(
            image: personality?.accessory.dashboardIcon, color: UIColor.lightGray)
        iconImageView?.image = Graphics.shrinkingFilter.apply(image: image, rathio: 0.8)

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
        return super.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == iconIndex.section && personality?.accessory as? ThermometerAccessory != nil {
            return iconIndex.row
        }else{
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
        if let target = segue.destination as? InputStringViewController{
            target.personality = InputStringViewControllerPersonality(
                title: NSLocalizedString("ACCESSORY_NAME_EDIT_TITLE", comment: ""),
                initial: personality?.accessory.name,
                placehodlder: personality?.accessory.name){
                    [unowned self] (name) in
                    if let name = name, name != "" {
                        self.personality?.accessory.name = name
                        self.updateView()
                        self.updateData(force: false)
                    }
            }
        }else if let target = segue.destination as? ItemSelectorViewController {
            let identity = ItemSelectorIdentity()
            identity.title = NSLocalizedString("SELECT_ICON_TITLE", comment: "")
            identity.items = sortedPortalAccessoryTypes.compactMap{portalAccessories[$0]?.description}
            identity.selectionIndex =
                portalAccessories[personality?.accessory.iconName ?? personality!.accessory.type]!.seqid
            identity.icons = sortedPortalAccessoryTypes.compactMap{
                Graphics.shrinkingFilter.apply(image:
                    Graphics.coloringFilter.apply(image: portalAccessories[$0]?.dashboardIcon,
                                                  color: UIColor.lightGray),
                rathio: 0.8)
            }
            identity.changeNotifier = {
                [unowned self] identity, index in
                self.personality?.accessory.iconName = sortedPortalAccessoryTypes[index]
                self.updateView()
                self.updateData(force: false)
            }
            
            target.identity = identity
        }
    }

}
