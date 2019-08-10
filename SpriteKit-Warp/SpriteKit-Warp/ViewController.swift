//
//  ViewController.swift
//  SpriteKit-Warp
//
//  Created by Tomoya Hirano on 2019/08/09.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation
import SpriteKit

class ViewController: UIViewController {
  
  private let imageView: UIImageView = .init()
  private let filter: WarpGeometryFilter = .init()
  let camera = Camera()
  
  override func loadView() {
    super.loadView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(imageView)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: imageView.topAnchor),
      view.leftAnchor.constraint(equalTo: imageView.leftAnchor),
      view.rightAnchor.constraint(equalTo: imageView.rightAnchor),
      view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    let source: [vector_float2] = [
      vector_float2(0, 0),   vector_float2(0.5, 0),   vector_float2(1, 0),
      vector_float2(0, 0.5), vector_float2(0.5, 0.5), vector_float2(1, 0.5),
      vector_float2(0, 1),   vector_float2(0.5, 1),   vector_float2(1, 1)
    ]
    
    //歪曲先つまみ点
    let distination: [vector_float2] = [
      vector_float2(0, 0),   vector_float2(0.5, 0),   vector_float2(1, 0),
      vector_float2(0, 0.5), vector_float2(0.25, 0.5), vector_float2(1, 0.5),
      vector_float2(0, 1),   vector_float2(0.5, 1),   vector_float2(1, 1)
    ]
    let warpGeometry = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: source, destinationPositions: distination)
    filter.setValue(warpGeometry, forKey: kCIInputWarpGeometryKey)
    
    camera.setSampleBufferDelegate(self, queue: .global())
    camera.startRunning()
  }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    let inputImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
    filter.setValue(inputImage, forKey: kCIInputImageKey)
    let outputImage = filter.outputImage!
    DispatchQueue.main.async {
      self.imageView.image = UIImage(ciImage: outputImage)
    }
  }
  
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
  }
}

