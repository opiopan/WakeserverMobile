//
//  InterfaceCircle.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/12/23.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import WatchKit

open class InterfaceCircle {
    var lineWidth = CGFloat(3.5)

    private let size : CGSize
    private weak var imageObject: WKInterfaceImage?
    private var angle : CGFloat = 0

    init(withInterfaceImage object: WKInterfaceImage, size: CGFloat) {
        imageObject = object
        self.size = CGSize(width: size * 2, height: size * 2)
    }
    
    open func setCircleAngle(_ angle: Double) {
        self.angle = CGFloat(angle)
        
        let begin = CGFloat(-Double.pi / 2)
        let angle = CGFloat(Double.pi * 2)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = (size.width - lineWidth * 2) / 2

        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()

        if let context = context {
            context.setStrokeColor(gray: 1, alpha: 1)
            context.setLineWidth(lineWidth * 2)
            context.setLineCap(.round)

            context.addArc(center: center, radius: radius,
                           startAngle:begin, endAngle: begin + angle * self.angle, clockwise: false)
            context.strokePath()

            let cgImage = context.makeImage();
            if let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage).withRenderingMode(.alwaysTemplate)
                imageObject?.setImage(image)
            }
        }
        
        UIGraphicsEndImageContext()
    }
}
