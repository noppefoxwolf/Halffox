//
//  ViewController.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/06.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
  private let displayView: SampleBufferDisplayView = .init()
  let session = AVCaptureSession()
  let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
  lazy var input = try! AVCaptureDeviceInput(device: device)
  let output = AVCaptureVideoDataOutput()
  
  private var request: VNDetectFaceLandmarksRequest!
  private var results: [VNFaceObservation] = []
  
  override func loadView() {
    super.loadView()
    displayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(displayView)
    NSLayoutConstraint.activate([
      displayView.topAnchor.constraint(equalTo: view.topAnchor),
      displayView.leftAnchor.constraint(equalTo: view.leftAnchor),
      displayView.rightAnchor.constraint(equalTo: view.rightAnchor),
      displayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    session.addInput(input)
    session.addOutput(output)
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
    session.startRunning()
    
    
    request = VNDetectFaceLandmarksRequest { [weak self] (request, error) in
      guard let results = request.results as? [VNFaceObservation] else { return }
      self?.results = results
    }
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    if let pixelBuffer = pixelBuffer {
      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
      try? handler.perform([request])
    }
    let width = CVPixelBufferGetWidth(pixelBuffer!)
    let height = CVPixelBufferGetHeight(pixelBuffer!)
    let size = CGSize(width: width, height: height)
    
    let ciImage = CIImage(cvImageBuffer: pixelBuffer!)
    var filters: [CIFilter] = []
    
    if let landmarks = results.first?.landmarks {
      if let result = landmarks.leftPupil?.pointsInImage(imageSize: size).first, let leftEye = landmarks.leftEye, leftEye.pointCount >= 6 {
        let leftEyePoints = leftEye.pointsInImage(imageSize: size)
        let eyeSize = distance(SIMD2(point: leftEyePoints[2]), SIMD2(point: leftEyePoints[6]))
        
        let vector = CIVector(x: result.x, y: result.y)
        let filter = CIFilter(name: "CIBumpDistortion")!
        filter.setValue(vector, forKey: kCIInputCenterKey)
        filter.setValue(eyeSize, forKey: kCIInputRadiusKey)
        filter.setValue(0.5, forKey: kCIInputScaleKey)
        filters.append(filter)
      }
      if let result = landmarks.rightPupil?.pointsInImage(imageSize: size).first, let rightEye = landmarks.rightEye,
        rightEye.pointCount >= 6 {
        let rightEyePoints = rightEye.pointsInImage(imageSize: size)
        let eyeSize = distance(SIMD2(point: rightEyePoints[2]), SIMD2(point: rightEyePoints[6]))
        let vector = CIVector(x: result.x, y: result.y)
        let filter = CIFilter(name: "CIBumpDistortion")!
        filter.setValue(vector, forKey: kCIInputCenterKey)
        filter.setValue(eyeSize, forKey: kCIInputRadiusKey)
        filter.setValue(0.5, forKey: kCIInputScaleKey)
        filters.append(filter)
      }
    }
    
    
    let filter = CIFilter(name: "CIAffineTransform")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    let outputImage = filters.reduce(into: filter, { (result, filter) in
      filter.setValue(result.outputImage!, forKey: kCIInputImageKey)
      result = filter
    }).outputImage!
    
    let context = CIContext()
    var resultPixelBuffer: CVPixelBuffer? = nil
    let options = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ] as [String : Any]
    CVPixelBufferCreate(kCFAllocatorSystemDefault, width, height, kCVPixelFormatType_32BGRA, options as CFDictionary, &resultPixelBuffer)
    
    //context.render(ciImage, to: resultPixelBuffer!)
    context.render(outputImage, to: resultPixelBuffer!)
    
    var sampleTime: CMSampleTimingInfo = .init(duration: CMSampleBufferGetDuration(sampleBuffer),
                                               presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
                                               decodeTimeStamp: CMSampleBufferGetDecodeTimeStamp(sampleBuffer))
    var videoInfo: CMVideoFormatDescription? = nil
    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: resultPixelBuffer!,
                                                 formatDescriptionOut: &videoInfo)
    
    var resultSampleBuffer: CMSampleBuffer? = nil
    CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                       imageBuffer: resultPixelBuffer!,
                                       dataReady: true,
                                       makeDataReadyCallback: nil,
                                       refcon: nil,
                                       formatDescription: videoInfo!,
                                       sampleTiming: &sampleTime,
                                       sampleBufferOut: &resultSampleBuffer)
    
    displayView.displayLayer.enqueue(resultSampleBuffer!)
  }
}

class SampleBufferDisplayView: UIView {
  override class var layerClass: AnyClass { return AVSampleBufferDisplayLayer.self }
  var displayLayer: AVSampleBufferDisplayLayer { return layer as! AVSampleBufferDisplayLayer }
}

extension SIMD2 where Scalar == Double {
  init(point: CGPoint) {
    self = SIMD2.init(Double(point.x), Double(point.y))
  }
}
