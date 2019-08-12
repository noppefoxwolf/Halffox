//
//  ARLandmark.swift
//  ARKit-Render
//
//  Created by beta on 2019/08/11.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import ARKit

class ARFaceObservation {
  public let capturedImage: CIImage
  public let landmarks: ARFaceLandmarks2D?
  public var perspectivePoints: ARPerspectivePoints2D?
  
  init(frame: ARFrame, orientation: CGImagePropertyOrientation = CGImagePropertyOrientation.up) {
    capturedImage = CIImage(cvPixelBuffer: frame.capturedImage).oriented(orientation)
    landmarks = ARFaceLandmarks2D(frame: frame, orientation: orientation)
    perspectivePoints = ARPerspectivePoints2D(landmarks: landmarks)
  }
}

class ARPerspectivePoints2D {
  let topLeft: ARPerspectiveRegion2D
  let topRight: ARPerspectiveRegion2D
  let bottomRight: ARPerspectiveRegion2D
  let bottomLeft: ARPerspectiveRegion2D
  
  init?(landmarks: ARFaceLandmarks2D?) {
    if let allPoints = landmarks?.allPoints {
      // ここの計算は適当、横顔とかに弱い
      // 20
      // 1023 13 1029
      // 1047
      let rightTranslationMatrix = allPoints.normalizedPoints[1029].simd - allPoints.normalizedPoints[13].simd
      let leftTranslationMatrix = allPoints.normalizedPoints[1023].simd - allPoints.normalizedPoints[13].simd
      
      topLeft = ARPerspectiveRegion2D(point: (allPoints.normalizedPoints[20].simd + leftTranslationMatrix).point)
      topRight = ARPerspectiveRegion2D(point: (allPoints.normalizedPoints[20].simd + rightTranslationMatrix).point)
      bottomRight = ARPerspectiveRegion2D(point: (allPoints.normalizedPoints[1047].simd + rightTranslationMatrix).point)
      bottomLeft = ARPerspectiveRegion2D(point: (allPoints.normalizedPoints[1047].simd + leftTranslationMatrix).point)
    } else {
      return nil
    }
  }
}

public class ARPerspectiveRegion2D {
  let point: CGPoint
  
  init(point: CGPoint) {
    self.point = point
  }
  
  func pointInImage(imageSize: CGSize) -> CGPoint {
    return point.applying(.init(scaleX: imageSize.width, y: imageSize.height))
  }
}

open class ARFaceLandmarks2D {
  let textureCoordinates: [simd_float2]
  let orientation: CGImagePropertyOrientation
  
  init?(frame: ARFrame, orientation: CGImagePropertyOrientation) {
    if let faceAnchor = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first, faceAnchor.isTracked {
      let geometry = faceAnchor.geometry
      let vertices = geometry.vertices
      let size = frame.camera.imageResolution
      let camera = frame.camera
      let viewportSize = CGSize(width: size.height, height: size.width)
      let modelMatrix = faceAnchor.transform
      // https://stackoverflow.com/a/53255370/1131587
      textureCoordinates = vertices.lazy.map { (vertex) -> simd_float2 in
        let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
        let world_vertex4 = simd_mul(modelMatrix, vertex4)
        let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
        let pt = camera.projectPoint(world_vector3, orientation: .portrait, viewportSize: viewportSize)
        let v = 1.0 - Float(pt.x) / Float(size.height)
        let u = Float(pt.y) / Float(size.width)
        let normalizedPoints = simd_float2(u, v)
        
        switch orientation {
        case .up:
          return normalizedPoints
        case .right:
          let θ: Float = .pi / 2.0 //90
          let orientationMatrix = simd_float2x2(float2(x: cos(θ), y: sin(θ)), float2(x: -sin(θ), y: cos(θ)))
          return simd_mul(orientationMatrix, normalizedPoints) + simd_float2(x: 1, y: 0)
        default:
          preconditionFailure("not supported")
        }
        
      }
      self.orientation = orientation
    } else {
      return nil
    }
  }
  
  open var allPoints: ARFaceLandmarkRegion2D? {
    return ARFaceLandmarkRegion2D(normalizedPoints: textureCoordinates)
  }
  
  open var faceContour: ARFaceLandmarkRegion2D? {
    let indices: [Int] = [940, 939, 938, 937, 936, 935, 934, 933, 932, 989, 988, 987, 986, 985, 984, 1049, 983, 982, 944, 992, 991, 990, 1007, 1006, 1005, 1004, 1003, 1002, 1001, 1000, 999]
    return ARFaceLandmarkRegion2D(normalizedPoints: indices.compactMap({ textureCoordinates[$0] }))
    // 940 939 938 937 936 935 934 933 932 989 988 987 086 985 984
    // 1049
    // 983 982 944 992 991 990 1007 1006 1005 1004 1003 1002 1001 1008 1009
  }
  
  open var leftEye: ARFaceLandmarkRegion2D? {
    let indices: [Int] = (1181...1204).map({ $0 })
    return ARFaceLandmarkRegion2D(normalizedPoints: indices.compactMap({ textureCoordinates[$0] }))
  }
  
  open var rightEye: ARFaceLandmarkRegion2D? {
    let indices: [Int] = (1061...1084).map({ $0 })
    return ARFaceLandmarkRegion2D(normalizedPoints: indices.compactMap({ textureCoordinates[$0] }))
  }
  
  open var leftEyebrow: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var rightEyebrow: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var nose: ARFaceLandmarkRegion2D? {
    return ARFaceLandmarkRegion2D(normalizedPoints: [textureCoordinates[8]] )
  }
  
  open var noseCrest: ARFaceLandmarkRegion2D? {
    let indices: [Int] = [15, 14, 13, 12, 11, 10, 9, 8]
    return ARFaceLandmarkRegion2D(normalizedPoints: indices.compactMap({ textureCoordinates[$0] }))
    // 15 ~ 8
  }
  
  open var medianLine: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var outerLips: ARFaceLandmarkRegion2D? {
    //102 100 99 98 91 90 1 539 540 547 548 549 551
    return nil
  }
  
  open var innerLips: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var leftPupil: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var rightPupil: ARFaceLandmarkRegion2D? {
    return nil
  }
}

import Vision

public class ARFaceLandmarkRegion2D {
  let normalizedPoints: [CGPoint]
  
  init(normalizedPoints: [simd_float2]) {
    self.normalizedPoints = normalizedPoints.lazy.map({ CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) })
  }
  
  func pointsInImage(imageSize: CGSize) -> [CGPoint] {
    return normalizedPoints.lazy.map({ $0.applying(.init(scaleX: imageSize.width, y: imageSize.height)) })
  }
}
