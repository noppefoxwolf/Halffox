//
//  FaceShrinkFilter.swift
//  Shrink-Demo
//
//  Created by beta on 2019/08/11.
//  Copyright © 2019 noppelab. All rights reserved.
//

import UIKit
import ARKit
import SpriteKit

let kCIInputPerspectivePointsKey: String = "kCIInputPerspectivePointsKey"

class FaceShrinkFilter: CIFilter {
  private var inputImage: CIImage? = nil
  private var perspectivePoints: ARPerspectivePoints2D? = nil
  
  override func setValue(_ value: Any?, forKey key: String) {
    switch key {
    case kCIInputImageKey:
      inputImage = value as? CIImage
    case kCIInputPerspectivePointsKey:
      perspectivePoints = value as? ARPerspectivePoints2D
    default: break
    }
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    guard let perspectivePoints = perspectivePoints else { return nil }
    let size = inputImage.extent.size
    
    let sourceImage = inputImage.clampedToExtent()
    let correctionFilter = CIFilter(name: "CIPerspectiveCorrection")!
    correctionFilter.setValue(sourceImage, forKey: kCIInputImageKey) //ハミでてもちゃんとサイズ維持する
    
    let topLeft = perspectivePoints.topLeft.pointInImage(imageSize: size).reversedY(height: size.height).vector
    let topRight = perspectivePoints.topRight.pointInImage(imageSize: size).reversedY(height: size.height).vector
    let bottomRight = perspectivePoints.bottomRight.pointInImage(imageSize: size).reversedY(height: size.height).vector
    let bottomLeft = perspectivePoints.bottomLeft.pointInImage(imageSize: size).reversedY(height: size.height).vector
    correctionFilter.setValue(topLeft, forKey: "inputTopLeft")
    correctionFilter.setValue(topRight, forKey: "inputTopRight")
    correctionFilter.setValue(bottomRight, forKey: "inputBottomRight")
    correctionFilter.setValue(bottomLeft, forKey: "inputBottomLeft")
    
    let source: [vector_float2] = [
      vector_float2(0, 0),   vector_float2(0.5, 0),   vector_float2(1, 0),
      vector_float2(0, 0.5), vector_float2(0.5, 0.5), vector_float2(1, 0.5),
      vector_float2(0, 1),   vector_float2(0.5, 1),   vector_float2(1, 1)
    ]
    let distination: [vector_float2] = [
      vector_float2(0, 0),   vector_float2(0.5, 0),   vector_float2(1, 0),
      vector_float2(0, 0.5), vector_float2(0.25, 0.5), vector_float2(1, 0.5),
      vector_float2(0, 1),   vector_float2(0.5, 1),   vector_float2(1, 1)
    ]
    let warpGeometry = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: source, destinationPositions: distination)
    let warpGeometryFilter = WarpGeometryFilter()
    warpGeometryFilter.setValue(correctionFilter.outputImage!, forKey: kCIInputImageKey)
    warpGeometryFilter.setValue(warpGeometry, forKey: kCIInputWarpGeometryKey)
    
    // 合成
    let transformFilter = CIFilter(name: "CIPerspectiveTransform")!
    let transformInputImage = warpGeometryFilter.outputImage!
    transformFilter.setValue(transformInputImage, forKey: kCIInputImageKey)
    transformFilter.setValue(bottomLeft, forKey: "inputTopLeft")
    transformFilter.setValue(bottomRight, forKey: "inputTopRight")
    transformFilter.setValue(topRight, forKey: "inputBottomRight")
    transformFilter.setValue(topLeft, forKey: "inputBottomLeft")
    
    return transformFilter.outputImage!.composited(over: inputImage).cropped(to: inputImage.extent)
  }
}
