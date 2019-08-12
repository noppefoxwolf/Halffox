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
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var imageView: UIImageView!
  private let session = ARSession()
  private let stickerFilter: StickerFilter = .init()
  
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
    let observation: ARFaceObservation = .init(frame: frame, orientation: .right)
    if let center = observation.landmarks?.allPoints {
      let inputImage = observation.capturedImage
      stickerFilter.setValue(inputImage, forKey: kCIInputImageKey)
      stickerFilter.setValue(center, forKey: kCIInputFaceLandmarkRegionCenterKey)
      let result = stickerFilter.outputImage!.cropped(to: inputImage.extent)
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: result)
      }
    } else {
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: observation.capturedImage)
      }
    }
  }
}

let kCIInputFaceLandmarkRegionCenterKey: String = "kCIInputFaceLandmarkRegionCenterKey"

class StickerFilter: CIFilter {
  private var inputImage: CIImage? = nil
  private var faceLandmarkRegion: ARFaceLandmarkRegion2D? = nil
  var index: Int = 0
  
  override func setValue(_ value: Any?, forKey key: String) {
    switch key {
    case kCIInputImageKey:
      inputImage = value as? CIImage
    case kCIInputFaceLandmarkRegionCenterKey:
      faceLandmarkRegion = value as? ARFaceLandmarkRegion2D
    default:
      break
    }
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    guard let faceLandmarkRegion = faceLandmarkRegion else { return nil }
    
    index += 1
    if index > 119 {
      index = 0
    }
    let translateMatrix = faceLandmarkRegion.pointsInImage(imageSize: inputImage.extent.size)[0].simd - inputImage.extent.size.center.simd
    
    let noseImage = CIImage(contentsOf: Bundle.main.url(forResource: String(format: "nose_%03d", index), withExtension: "png")!)!
    let earLeftImage = CIImage(contentsOf: Bundle.main.url(forResource: String(format: "earLeft_%03d", index), withExtension: "png")!)!
    let earRightImage = CIImage(contentsOf: Bundle.main.url(forResource: String(format: "earRight_%03d", index), withExtension: "png")!)!
    let beardLeftImage = CIImage(contentsOf: Bundle.main.url(forResource: String(format: "beardLeft_%03d", index), withExtension: "png")!)!
    let beardRightImage = CIImage(contentsOf: Bundle.main.url(forResource: String(format: "beardRight_%03d", index), withExtension: "png")!)!
    let mixed = noseImage.composited(over: earLeftImage).composited(over: earRightImage).composited(over: beardLeftImage).composited(over: beardRightImage).transformed(by: .init(translationX: CGFloat(translateMatrix.x), y: -CGFloat(translateMatrix.y)))
    return mixed.composited(over: inputImage)
  }
}
