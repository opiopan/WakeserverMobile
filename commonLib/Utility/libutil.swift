//
//  libutil.swift
//  commonLib
//
//  Created by opiopan on 2017/10/07.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation

fileprivate class ThisLib{}

let libBundle = Bundle(for: ThisLib.self)

func LocalizedString(_ key: String) -> String{
    return libBundle.localizedString(forKey: key, value: "", table: nil)
}

func libBundleImage(name: String) -> UIImage? {
    #if os(iOS)
        return UIImage(named: name, in: libBundle, compatibleWith: nil)
    #elseif os(watchOS)
        return UIImage(named: name)
    #endif
}
