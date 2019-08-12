//
//  CGPoint+Extensions.swift
//  Shrink-Demo
//
//  Created by beta on 2019/08/11.
//  Copyright © 2019 noppelab. All rights reserved.
//

import ARKit

extension CGPoint {
  var simd: simd_float2 {
    return simd_float2(x: Float(x), y: Float(y))
  }
  
  var vector: CIVector {
    return CIVector(x: x, y: y)
  }
  
  func reversedY(height: CGFloat) -> CGPoint {
    return CGPoint(x: x, y: height - y)
  }
  
  var integral: CGPoint {
    return CGPoint(x: Int(x), y: Int(y))
  }
}

extension simd_float2 {
  var point: CGPoint {
    return CGPoint(x: CGFloat(x), y: CGFloat(y))
  }
}

extension CGSize {
  var center: CGPoint {
    return CGPoint(x: width / 2, y: height / 2)
  }
}
