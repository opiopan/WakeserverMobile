//
//  AccessoryStatusUnitView.swift
//  WakeserverMobile
//
//  Created by opiopan on 2017/11/02.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import UIKit
import CoreImage
import commonLib

/*
private class ColoringFilter {
    private let kernel : CIKernel?
    
    init() {
        let kernelString = """
            kernel vec4 Coloring(sampler src, vec4 refColor) {
                vec4 srcColor = sample(src, samplerCoord(src));
                vec4 result = refColor;
                result.a = refColor.a * srcColor.a;
                return result;
            }
        """
        kernel = CIKernel(source: kernelString)
    }
    
    func apply(image: UIImage?, color: UIColor?) -> UIImage? {
        if let image = image?.cgImage, let color = color?.cgColor {
            let ciImage = CIImage(cgImage: image)
            let ciColor = CIColor(cgColor: color)
            let args = [ciImage, ciColor]
            if let rc = kernel?.apply(extent: ciImage.extent, roiCallback: {index, rect in rect}, arguments: args) {
                return UIImage(ciImage: rc)
            }
        }
        return nil
    }
}

private let coloringFilter = ColoringFilter()
*/

class AccessoryStatusUnitView: UIView, CAAnimationDelegate {
    enum ViewType {
        case none
        case powerState
        case thermometer
    }
    
    var viewType: ViewType = .none {
        didSet{
            setNeedsDisplay()
            resetStateImage()
        }
    }
    var themeColor: UIColor? {
        didSet{
            resetStateImage()
            temperatureTextLayer?.foregroundColor = themeColor?.cgColor
            foregroundCircle?.color = themeColor?.cgColor
            setNeedsDisplay()
        }
    }
    var image: UIImage? {
        didSet{
            resetStateImage()
            setNeedsDisplay()
        }
    }
    var powerStatus = PortalAccessory.PowerState.unknown {
        didSet{setNeedsDisplay()}
    }

    private var temperature : Double?
    var temperatureRef : Double? {
        get{
            return temperature
        }
    }

    private var unknownImage : UIImage?
    private var onImage : UIImage?
    private var offImage : UIImage?
    
    private var temperatureTextLayer : CATextLayer?
    private var temperatureTextTransitionLayer : CATextLayer?
    private var foregroundCircle: CircleIndicatorLayer?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        let initAndAddLayer: (CALayer)->Void = {child in
            child.backgroundColor = UIColor.clear.cgColor
            child.contentsScale = UIScreen.main.scale
            self.layer.addSublayer(child)
        }
            
        temperatureTextLayer = CATextLayer()
        if let child = temperatureTextLayer {
            child.alignmentMode = kCAAlignmentCenter
            initAndAddLayer(child)
        }
        
        foregroundCircle = CircleIndicatorLayer()
        if let child = foregroundCircle {
            initAndAddLayer(child)
        }
    }

    private func setupLayers(){
        if viewType == .thermometer {
            let parent = layer.frame

            layer.backgroundColor = stateColor(.unknown).cgColor
            layer.cornerRadius = parent.width / 2

            let fontSize = parent.height * 0.3
            temperatureTextLayer?.fontSize = fontSize
            let rect = CGRect(x: 0, y: parent.height / 2 - fontSize / 1.7, width: parent.width, height: parent.height)
            temperatureTextLayer?.frame = rect
            temperatureTextLayer?.opacity = 1

            let fullRect = CGRect(x: 0, y: 0, width: parent.width, height: parent.height)
            foregroundCircle?.frame = fullRect
            foregroundCircle?.opacity = 1
        }else{
            layer.backgroundColor = UIColor.clear.cgColor
            temperatureTextLayer?.opacity = 0
            foregroundCircle?.opacity = 0
        }
    }
    
    private var inAnimation = false
    
    func setTemperatureWithAnimation(temperature: Double?, duration: Double) {
        guard !inAnimation else {return}
        
        inAnimation = true
        
        if duration > 0{
            
            let animation : (String, Any, Any) -> CAAnimation = {
                key, from, to in
                let animation = CABasicAnimation(keyPath: key)
                animation.delegate = self
                animation.duration = duration
                animation.repeatCount = 1
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                animation.fromValue = from
                animation.toValue = to
                animation.isRemovedOnCompletion = false
                animation.fillMode = kCAFillModeForwards
                return animation
            }
            
            if let src = temperatureTextLayer {
                temperatureTextTransitionLayer = CATextLayer(layer: src)
                if let child = temperatureTextTransitionLayer {
                    layer.addSublayer(child)
                }
            }
            temperatureTextLayer?.string = temperatureToText(temperature)
            temperatureTextLayer?.opacity = 0

            foregroundCircle?.add(animation("rathio",
                                            temperatureToAngleRathio(self.temperature),
                                            temperatureToAngleRathio(temperature)), forKey: nil)
            temperatureTextLayer?.add(animation("opacity", CGFloat(0), CGFloat(1)), forKey: nil)
            temperatureTextTransitionLayer?.add(animation("opacity", CGFloat(1), CGFloat(0)), forKey: nil)
            layer.add(animation("backgroundColor",
                                stateColor(self.temperature == nil ? .unknown : .off).cgColor,
                                stateColor(temperature == nil ? .unknown : .off).cgColor), forKey: nil)
        }else{
            temperatureTextLayer?.string = temperatureToText(temperature)
            foregroundCircle?.rathio = temperatureToAngleRathio(temperature)
            layer.backgroundColor = stateColor(temperature == nil ? .unknown : .off).cgColor
            inAnimation = false
            setNeedsDisplay()
        }
        self.temperature = temperature
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        foregroundCircle?.rathio = temperatureToAngleRathio(temperature)
        temperatureTextLayer?.opacity = 1
        layer.backgroundColor = stateColor(temperature == nil ? .unknown : .off).cgColor
        foregroundCircle?.removeAllAnimations()
        temperatureTextLayer?.removeAllAnimations()
        temperatureTextTransitionLayer?.removeAllAnimations()
        layer.removeAllAnimations()
        inAnimation = false
    }
    
    override func draw(_ rect: CGRect) {
        setupLayers()
        switch viewType {
        case .powerState:
            drawPowerState(rect)
        case .thermometer:
            drawTemperature(rect)
        case .none:
            break
        }
    }
    
    private func drawPowerState(_ rect: CGRect) {
        stateImage(powerStatus)?.draw(in: rect)
    }
    
    private func drawTemperature(_ rect: CGRect) {
    }
    
    private func resetStateImage(){
        unknownImage = nil
        onImage = nil
        offImage = nil
    }
    
    private func stateColor(_ state: PortalAccessory.PowerState) -> UIColor {
        if let themeColor = themeColor {
            var red : CGFloat = 0
            var green : CGFloat = 0
            var blue : CGFloat = 0
            var alpha : CGFloat = 0
            themeColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            switch state {
            case .on:
                return UIColor(red: red, green: green, blue: blue, alpha: 0.8)
            case .off:
                return UIColor(red: red, green: green, blue: blue, alpha: 0.25)
            case .unknown:
                break
            }
        }

        let gray: CGFloat = 0.5
        return UIColor(red: gray, green: gray, blue: gray, alpha: 0.25)
    }
    
    private func stateImage(_ state: PortalAccessory.PowerState) -> UIImage? {
        switch state {
        case .on:
            if onImage == nil {
                onImage = Graphics.coloringFilter.apply(image: image, color: stateColor(.on))
            }
            return onImage
        case .off:
            if offImage == nil {
                offImage = Graphics.coloringFilter.apply(image: image, color: stateColor(.off))
            }
            return offImage
        case .unknown:
            if unknownImage == nil {
                unknownImage = Graphics.coloringFilter.apply(image: image, color: stateColor(.unknown))
            }
            return unknownImage
        }
    }
    
    private func temperatureToAngleRathio(_ temperature: Double?) -> CGFloat{
        if let temperature = temperature {
            let temp = CGFloat(temperature)
            let tempMin = CGFloat(-10)
            let tempMax = CGFloat(35)
            let rathio = (CGFloat(temp) - tempMin) / (tempMax - tempMin)
            return max(0, min(1, rathio))
        }else{
            return 0
        }
    }
    
    private func temperatureToText(_ temperature: Double?) -> String {
        if let temp = temperature {
            return "\(Int(temp.rounded(.toNearestOrEven)))°"
        }else{
            return ""
        }
    }
}
