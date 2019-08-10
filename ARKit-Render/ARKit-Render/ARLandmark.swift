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
  init(frame: ARFrame) {
    capturedImage = CIImage(cvPixelBuffer: frame.capturedImage)
    landmarks = ARFaceLandmarks2D(frame: frame)
  }
}

open class ARFaceLandmarks2D {
  let textureCoordinates: [simd_float2]
  
  init?(frame: ARFrame) {
    let faceAnchors = frame.anchors.compactMap { $0 as? ARFaceAnchor }
    if let faceAnchor = faceAnchors.first {
      let geometry = faceAnchor.geometry
      let vertices = geometry.vertices
      let size = frame.camera.imageResolution
      let camera = frame.camera
      
      let modelMatrix = faceAnchor.transform
      // https://stackoverflow.com/a/53255370/1131587
      textureCoordinates = vertices.map { vertex -> simd_float2 in
        let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
        let world_vertex4 = simd_mul(modelMatrix, vertex4)
        let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
        let pt = camera.projectPoint(world_vector3,
                                     orientation: .portrait,
                                     viewportSize: CGSize(
                                      width: CGFloat(size.height),
                                      height: CGFloat(size.width)))
        let v = 1.0 - Float(pt.x) / Float(size.height)
        let u = Float(pt.y) / Float(size.width)
        return vector_float2(u, v)
      }
    } else {
      return nil
    }
  }
  
  open var allPoints: ARFaceLandmarkRegion2D? {
    return ARFaceLandmarkRegion2D(normalizedPoints: textureCoordinates)
  }
  
  open var faceContour: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var leftEye: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var rightEye: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var leftEyebrow: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var rightEyebrow: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var nose: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var noseCrest: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var medianLine: ARFaceLandmarkRegion2D? {
    return nil
  }
  
  open var outerLips: ARFaceLandmarkRegion2D? {
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
    self.normalizedPoints = normalizedPoints.map({ CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) })
  }
  
  func pointsInImage(imageSize: CGSize) -> [CGPoint] {
    return normalizedPoints.map({ $0.applying(.init(scaleX: imageSize.width, y: imageSize.height)) })
  }
}
