//
//  Camera.swift
//  SpriteKit-Warp
//
//  Created by beta on 2019/08/10.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import AVFoundation

class Camera {
  lazy var device: AVCaptureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: .front).devices[0]
  lazy var input: AVCaptureDeviceInput = {
    return try! AVCaptureDeviceInput(device: device)
  }()
  lazy var output: AVCaptureVideoDataOutput = {
    return AVCaptureVideoDataOutput()
  }()
  let session: AVCaptureSession = .init()
  
  init() {
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
    session.addInput(input)
    session.addOutput(output)
  }
  
  func startRunning() {
    session.startRunning()
  }
  
  func stopRunning() {
    session.stopRunning()
  }
  
  func setSampleBufferDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate?, queue: DispatchQueue?) {
    output.setSampleBufferDelegate(delegate, queue: queue)
  }
}
