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
    let observation: ARFaceObservation = .init(frame: frame)
    if let landmarks = observation.landmarks {
      let size = observation.capturedImage.extent.size
      UIGraphicsBeginImageContext(size)
      UIImage(ciImage: observation.capturedImage).draw(at: .zero)
      for (index, point) in landmarks.allPoints!.pointsInImage(imageSize: size).enumerated() {
        NSAttributedString(string: "\(index)").draw(at: point)
      }
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
