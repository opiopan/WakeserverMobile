//
//  InputStringViewController.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/10/09.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class InputStringViewControllerPersonality {
    typealias FinishNotifier = (String?)->Void
    
    let titleString : String
    let initialString : String?
    let placeholderString : String?
    let finishNotifier : FinishNotifier?
    
    init(title: String, initial: String?, placehodlder: String?, finishNotifier: FinishNotifier?){
        self.titleString = title
        self.initialString = initial
        self.placeholderString = placehodlder
        self.finishNotifier = finishNotifier
    }
}

class InputStringViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!
    
    var personality : InputStringViewControllerPersonality? {
        didSet{
            updateField()
        }
    }
    
    private func updateField() {
        navigationItem.title = personality?.titleString
        textField?.text = personality?.initialString
        textField?.placeholder = personality?.placeholderString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateField()
        textField.delegate = self
        textField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        navigationController?.popViewController(animated: true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != personality?.initialString {
            personality?.finishNotifier?(textField.text)
        }
    }

}
