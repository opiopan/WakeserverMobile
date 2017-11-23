//
//  CircleIndicatorLayer.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/06.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit

class CircleIndicatorLayer: CALayer {
    var lineWidth : CGFloat = 0.1 {
        didSet{setNeedsDisplay()}
    }
    var color : CGColor? = UIColor.black.cgColor{
        didSet{setNeedsDisplay()}
    }
    @objc dynamic var rathio : CGFloat = 1.0{
        didSet{setNeedsDisplay()}
    }
    
    override init(){
        super.init()
    }
    
    override init(layer: Any) {
        if let layer = layer as? CircleIndicatorLayer {
            lineWidth = layer.lineWidth
            color = layer.color
            rathio = layer.rathio
        }
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        let begin = CGFloat(-Double.pi / 2)
        let angle = CGFloat(Double.pi * 2)
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let boundingSize = min(frame.width, frame.height)
        let width = boundingSize * lineWidth
        let radius = (boundingSize - width) / 2

        if let color = color {
            ctx.setStrokeColor(color)
        }
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.addArc(center: center, radius: radius, startAngle:begin, endAngle: begin + angle * rathio, clockwise: false)
        ctx.strokePath()
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        switch key {
        case "rathio":
            return true
        default:
            return false
        }
    }
}
