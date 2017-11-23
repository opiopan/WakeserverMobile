//
//  ButtonCell.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/09/18.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    //-----------------------------------------------------------------------------------------
    // MARK: - IBOutlet & IBAction
    //-----------------------------------------------------------------------------------------
    @IBOutlet weak var button: UIButton!
    
    @IBAction func onTouchUpButton(_ sender: Any) {
        buttonUpHandler?()
    }
    
    //-----------------------------------------------------------------------------------------
    // MARK: - プロパティ実装
    //-----------------------------------------------------------------------------------------
    var buttonTitle : String? {
        get {
            return button?.titleLabel!.text
        }
        
        set(title) {
            if (button != nil) {
                button!.setTitle(title, for: .normal)
            }
        }
    }
    
    var buttonUpHandler : (() -> Void)?

    //-----------------------------------------------------------------------------------------
    // MARK: - ビュー状態遷移
    //-----------------------------------------------------------------------------------------
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
