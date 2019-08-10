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
  @IBOutlet weak var minSlider: UISlider!
  @IBOutlet weak var maxSlider: UISlider!
  
  private let session = ARSession()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    session.delegate = self
    
    minSlider.minimumValue = 0
    minSlider.maximumValue = 1220
    minSlider.setValue(0, animated: false)
    
    maxSlider.minimumValue = 0
    maxSlider.maximumValue = 1220
    maxSlider.setValue(1220, animated: false)
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
    guard minSlider.value < maxSlider.value else { return }
    
    let observation: ARFaceObservation = .init(frame: frame, orientation: .right)
    if let landmarks = observation.landmarks {
      let size = observation.capturedImage.extent.size
      UIGraphicsBeginImageContext(size)
      let context = UIGraphicsGetCurrentContext()!
      UIImage(ciImage: observation.capturedImage).draw(at: .zero)
      for (index, point) in landmarks.allPoints!.pointsInImage(imageSize: size).enumerated() {
        //guard index % 3 == 0 else { continue }
        guard Int(minSlider.value)...Int(maxSlider.value) ~= index else { continue }
        NSAttributedString(string: "\(index)").draw(at: point)
      }
      
      context.setStrokeColor(UIColor.red.cgColor)
      context.addLines(between: landmarks.faceContour!.pointsInImage(imageSize: size))
      context.strokePath()
      
      context.setStrokeColor(UIColor.green.cgColor)
      context.addLines(between: landmarks.noseCrest!.pointsInImage(imageSize: size))
      context.strokePath()
      
      context.setStrokeColor(UIColor.blue.cgColor)
      context.addLines(between: landmarks.leftEye!.pointsInImage(imageSize: size))
      context.strokePath()
      
      context.setStrokeColor(UIColor.blue.cgColor)
      context.addLines(between: landmarks.rightEye!.pointsInImage(imageSize: size))
      context.strokePath()
      
      let result = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      DispatchQueue.main.async {
        self.imageView.image = result
      }
    } else {
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: observation.capturedImage)
      }
    }
  }
}
