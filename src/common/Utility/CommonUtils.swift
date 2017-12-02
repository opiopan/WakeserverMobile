//
//  CommonUtils.swift
//  commonLib
//
//  Created by opiopan on 2017/10/28.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

open class Weak<T : AnyObject> {
    open weak var object : T?
    
    public init(_ object : T){
        self.object = object
    }
}
