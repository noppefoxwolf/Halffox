//
//  CIImage+Extensions.swift
//  SpriteKit-Warp
//
//  Created by beta on 2019/08/10.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit

extension CIImage {
  func makePixelBuffer() -> CVPixelBuffer? {
    let size: CGSize = extent.size
    var pixelBuffer: CVPixelBuffer?
    let options = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ] as [String : Any]
    
    let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                               Int(size.width),
                                               Int(size.height),
                                               kCVPixelFormatType_32BGRA,
                                               options as CFDictionary,
                                               &pixelBuffer)
    
    let context = CIContext()
    
    if (status == kCVReturnSuccess && pixelBuffer != nil) {
      context.render(self, to: pixelBuffer!)
    }
    
    return pixelBuffer
  }
}
