//
//  LooseSerializable.swift
//  commonLib
//
//  Created by opiopan on 2017/10/14.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

public protocol LooseSerializable {
    init(dict : [String : Any]) throws
    var dictionary : [String : Any] {get}
}
