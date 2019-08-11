//
//  ViewController.swift
//  Shrink-Demo
//
//  Created by beta on 2019/08/11.
//  Copyright © 2019 noppelab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet weak var imageView: UIImageView!
  private let session = ARSession()
  private let shrinkFilter: FaceShrinkFilter = .init()
  
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
    if let perspectivePoints = observation.perspectivePoints {
      shrinkFilter.setValue(observation.capturedImage, forKey: kCIInputImageKey)
      shrinkFilter.setValue(perspectivePoints, forKey: kCIInputPerspectivePointsKey)
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: self.shrinkFilter.outputImage!)
      }
    } else {
      DispatchQueue.main.async {
        self.imageView.image = UIImage(ciImage: observation.capturedImage)
      }
    }
  }
}
