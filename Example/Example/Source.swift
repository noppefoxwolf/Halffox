//
//  Source.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/16.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation

protocol Output: class {
  func output(_ sampleBuffer: CMSampleBuffer)
}

protocol Source {
  var delegate: Output? { get set }
}

class CameraSource: NSObject, Source, AVCaptureVideoDataOutputSampleBufferDelegate {
  let session = AVCaptureSession()
  let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
  lazy var input: AVCaptureDeviceInput = {
    device.unlockForConfiguration()
    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
    try! device.lockForConfiguration()
    let input = try! AVCaptureDeviceInput.init(device: device)
    return input
  }()
  let output = AVCaptureVideoDataOutput()
  private let renderQueue = DispatchQueue(label: "com.halffox.shared", qos: .userInteractive)
  weak var delegate: Output?
  
  override init() {
    super.init()
    session.addInput(input)
    session.addOutput(output)
    session.sessionPreset = .iFrame960x540
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(self, queue: renderQueue)
    
    if let connection = output.connection(with: .video) {
      connection.videoOrientation = .landscapeRight
      connection.isVideoMirrored = true
    }
    
    session.startRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.output(sampleBuffer)
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.output(sampleBuffer)
  }
}
