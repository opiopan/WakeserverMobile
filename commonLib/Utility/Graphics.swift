//
//  Graphics.swift
//  commonLib
//
//  Created by opiopan on 2017/11/13.
//  Copyright © 2017年 opiopan. All rights reserved.
//

import Foundation


open class ColoringFilter {
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
    
    open func apply(image: UIImage?, color: UIColor?) -> UIImage? {
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

open class ShrinkingFilter {
    open func apply(image: UIImage?, rathio : Double) -> UIImage? {
        guard let image = image, image.cgImage != nil || image.ciImage != nil else{
            return nil
        }
        
        let width = image.ciImage?.extent.width ?? CGFloat(image.cgImage!.width)
        let height = image.ciImage?.extent.height ?? CGFloat(image.cgImage!.height)
        let size = CGSize(width: width, height: height)
        let drawRect = CGRect(x: width * (1.0 - CGFloat(rathio)) / 2, y: height * (1.0 - CGFloat(rathio)) / 2,
                              width: width * CGFloat(rathio), height: height * CGFloat(rathio))

        UIGraphicsBeginImageContext(size)
        image.draw(in: drawRect)
        let outImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return outImage
    }
    
    open func apply(image: UIImage?, size: CGSize) -> UIImage? {
        guard let image = image else {
            return nil
        }

        let drawRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        
        UIGraphicsBeginImageContext(size)
        image.draw(in: drawRect)
        let outImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return outImage
    }
}

public var Graphics : (
    coloringFilter : ColoringFilter,
    shrinkingFilter : ShrinkingFilter) =
    (
        ColoringFilter(),
        ShrinkingFilter()
)
