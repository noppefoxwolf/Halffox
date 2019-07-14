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
import YUCIHighPassSkinSmoothing

class ViewController: UIViewController {
  private let displayView: SampleBufferDisplayView = .init()
  let session = AVCaptureSession()
  let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
  lazy var input: AVCaptureDeviceInput = {
    device.unlockForConfiguration()
    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
    try! device.lockForConfiguration()
    let input = try! AVCaptureDeviceInput(device: device)
    return input
  }()
  let output = AVCaptureVideoDataOutput()
  
  private var request: VNDetectFaceLandmarksRequest!
  private lazy var sequenceRequestHandler = VNSequenceRequestHandler()
  private var results: [VNFaceObservation] = []
  
  private let sharedQueue = DispatchQueue(label: "com.halffox.shared", qos: .userInteractive)
  private lazy var renderQueue = sharedQueue
  private lazy var visionQueue = sharedQueue
  
  let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
//  private lazy var renderQueue = DispatchQueue(label: "com.halffox.render", qos: .background)
//  private lazy var visionQueue = DispatchQueue(label: "com.halffox.vision", qos: .default)
  
  let enlargeEye: CGFloat = 1.5
  let filter = CIFilter(name: "YUCIHighPassSkinSmoothing")!
//  let filter = MetalFilter()
  
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
//    VNDetectFaceLandmarksRequest.revision(VNDetectFaceLandmarksRequestRevision1, supportsConstellation: VNRequestFaceLandmarksConstellation.constellation76Points)
    
    session.addInput(input)
    session.addOutput(output)
    session.sessionPreset = .iFrame960x540
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(self, queue: renderQueue)
    
    let connection = output.connection(with: .video)!
    connection.videoOrientation = .landscapeRight
    connection.isVideoMirrored = true
    
    session.startRunning()
    
    
    
    request = VNDetectFaceLandmarksRequest { [weak self] (request, error) in
      guard let results = request.results as? [VNFaceObservation] else { return }
      self?.results = results
    }
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//    print("drop")
    DispatchQueue.main.async { [weak self] in
      self?.displayView.displayLayer.enqueue(sampleBuffer)
    }
  }
  
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    let _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    guard let pixelBuffer = _pixelBuffer else { return }
    
    vision: do {
      let options: [VNImageOption : Any] = [
        VNImageOption.ciContext:context,
      ]
      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: options)
      try? handler.perform([request])
      try? sequenceRequestHandler.perform([request], on: pixelBuffer, orientation: .up)
    }
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let size = CGSize(width: width, height: height)
    
    let ciImage = CIImage(cvImageBuffer: pixelBuffer)
    var filters: [CIFilter] = []

    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(0.0, forKey: "inputAmount")
    
    if let landmarks = results.first?.landmarks {
      if let result = landmarks.leftPupil?.pointsInImage(imageSize: size).first,
        let leftEye = landmarks.leftEye, leftEye.pointCount > 1 {
        
        let leftEyePoints = leftEye.pointsInImage(imageSize: size)
        let minY = leftEyePoints.min(by: { $0.y < $1.y })?.y
        let maxY = leftEyePoints.max(by: { $0.y < $1.y })?.y
        let eyeSize = maxY! - minY!
        
        let vector = CIVector(x: result.x, y: result.y)
        let filter = CIFilter(name: "CIBumpDistortion")!
        filter.setValue(vector, forKey: kCIInputCenterKey)
        filter.setValue(eyeSize * enlargeEye, forKey: kCIInputRadiusKey)
        filter.setValue(0.5, forKey: kCIInputScaleKey)
        filters.append(filter)
      }
      
      if let result = landmarks.rightPupil?.pointsInImage(imageSize: size).first,
         let rightEye = landmarks.rightEye, rightEye.pointCount > 1 {
        
        let rightEyePoints = rightEye.pointsInImage(imageSize: size)
        let minY = rightEyePoints.min(by: { $0.y < $1.y })?.y
        let maxY = rightEyePoints.max(by: { $0.y < $1.y })?.y
        let eyeSize = maxY! - minY!
        
        let vector = CIVector(x: result.x, y: result.y)
        let filter = CIFilter(name: "CIBumpDistortion")!
        filter.setValue(vector, forKey: kCIInputCenterKey)
        filter.setValue(eyeSize * enlargeEye, forKey: kCIInputRadiusKey)
        filter.setValue(0.5, forKey: kCIInputScaleKey)
        filters.append(filter)
      }
      
      faceContour: do {
        if let faceContour = landmarks.faceContour {
          
          UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
          let ctx = UIGraphicsGetCurrentContext()!
          ctx.setStrokeColorSpace(CGColorSpaceCreateDeviceRGB())
          ctx.setFillColorSpace(CGColorSpaceCreateDeviceRGB())
          
          UIColor(red: 0.0, green: 0, blue: 0, alpha: 1).setFill()
          ctx.fill(.init(x: 0, y: 0, width: width, height: height))
          
          UIColor(red: 0.1, green: 0, blue: 0, alpha: 1).setStroke()
          ctx.setLineWidth(10.0)
          
          let points = faceContour.pointsInImage(imageSize: size)
          ctx.move(to: points[0])
          points.forEach({ ctx.addLine(to: $0) })
          ctx.strokePath()
          
          let cgImage = ctx.makeImage()!
          UIGraphicsEndImageContext()
          let ciImage = CIImage(cgImage: cgImage).oriented(.downMirrored)
          let filter = MetalFilter()
          filter.subImage = ciImage
          filters.append(filter)
        }
      }
    }
    
    let lastFilter: CIFilter = filters.reduce(into: filter as CIFilter, { (result, filter) in
      filter.setValue(result.outputImage!, forKey: kCIInputImageKey)
      result = filter
    })
    let outputImage = lastFilter.outputImage!
    
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
    
    DispatchQueue.main.async { [weak self] in
      var resultSampleBuffer: CMSampleBuffer? = nil
      CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                         imageBuffer: resultPixelBuffer!,
                                         dataReady: true,
                                         makeDataReadyCallback: nil,
                                         refcon: nil,
                                         formatDescription: videoInfo!,
                                         sampleTiming: &sampleTime,
                                         sampleBufferOut: &resultSampleBuffer)
      self?.displayView.displayLayer.enqueue(resultSampleBuffer!)
    }
  }
}

class SampleBufferDisplayView: UIView {
  override class var layerClass: AnyClass { return AVSampleBufferDisplayLayer.self }
  var displayLayer: AVSampleBufferDisplayLayer { return layer as! AVSampleBufferDisplayLayer }
}
