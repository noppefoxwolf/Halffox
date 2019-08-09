//
//  ViewController.swift
//  ARKit-Render
//
//  Created by Tomoya Hirano on 2019/08/08.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var imageView: UIImageView!
  private let session = ARSession()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    session.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARFaceTrackingConfiguration()
    session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    session.pause()
  }
}

extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    
    let inputImage = CIImage.init(cvPixelBuffer: frame.capturedImage).oriented(.right)
    let faceAnchors = frame.anchors.compactMap { $0 as? ARFaceAnchor }
    
    guard !faceAnchors.isEmpty, let camera = session.currentFrame?.camera else {
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: inputImage)
      }
      return
    }
    
    // Calculate face points to project to screen
    
    let projectionMatrix = camera.projectionMatrix(for: .portrait, viewportSize: inputImage.extent.size, zNear: 0.001, zFar: 1000)  // A transform matrix appropriate for rendering 3D content to match the image captured by the camera
    let viewMatrix = camera.viewMatrix(for: .portrait)        // Returns a transform matrix for converting from world space to camera space.
    
    let projectionViewMatrix = simd_mul(projectionMatrix, viewMatrix)
    
    for faceAnchor in faceAnchors  {
      let geometry = faceAnchor.geometry
      let vertices = geometry.vertices
      let size = frame.camera.imageResolution
      let camera = frame.camera
      
      let modelMatrix = faceAnchor.transform
      // https://stackoverflow.com/a/53255370/1131587
      let textureCoordinates = vertices.map { vertex -> simd_float2 in
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
      let θ: Float = .pi / 2.0 //90
      
      let orientationMatrix = simd_float2x2(float2(x: cos(θ), y: sin(θ)), float2(x: -sin(θ), y: cos(θ)))
      
      UIGraphicsBeginImageContext(inputImage.extent.size)
      let ctx = UIGraphicsGetCurrentContext()!
      UIImage(ciImage: inputImage).draw(at: .zero)
//      for point in textureCoordinates {
//        ctx.setFillColor(UIColor.red.cgColor)
//        ctx.fill(CGRect(origin: CGPoint(x: CGFloat(point.x) * inputImage.extent.width, y: CGFloat(point.y) * inputImage.extent.height), size: .init(width: 5, height: 5)))
//      }
      
//      ctx.setStrokeColor(UIColor.red.cgColor)
//      ctx.addLines(between: textureCoordinates.map({ CGPoint(x: CGFloat($0.x) * inputImage.extent.width, y: CGFloat($0.y) * inputImage.extent.height) }))
//      ctx.strokePath()
      
      for (index, point) in textureCoordinates.enumerated() {
        let point = simd_mul(orientationMatrix, point)
        //guard index == 6 else { continue }
        let p = CGPoint(x: CGFloat(point.x) * inputImage.extent.width + inputImage.extent.width, y: CGFloat(point.y) * inputImage.extent.height)
//        debugPrint(index, p)
        NSAttributedString(string: "\(index)").draw(at: p)
      }

      
      let result = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      DispatchQueue.main.async {
        self.imageView.image = result
      }
    }
  }
}
