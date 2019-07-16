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
  
  private var request: VNDetectFaceLandmarksRequest!
  private lazy var sequenceRequestHandler = VNSequenceRequestHandler()
  private var results: [VNFaceObservation] = []
  
  private let sharedQueue = DispatchQueue(label: "com.halffox.shared", qos: .userInteractive)
  private lazy var renderQueue = sharedQueue
  private lazy var visionQueue = sharedQueue
  let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
  
  let context = CIContext()
//  private lazy var renderQueue = DispatchQueue(label: "com.halffox.render", qos: .background)
//  private lazy var visionQueue = DispatchQueue(label: "com.halffox.vision", qos: .default)
  
  let enlargeEye: CGFloat = 1.5
  let filter = CIFilter(name: "YUCIHighPassSkinSmoothing")!
//  let filter = MetalFilter()
//  var source: Source = ImageSource()
  var source: Source = CameraSource()
  
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
    source.delegate = self
    
    request = VNDetectFaceLandmarksRequest { [weak self] (request, error) in
      guard let results = request.results as? [VNFaceObservation] else { return }
      self?.results = results
    }
  }
}

extension ViewController: Output {
  func output(_ sampleBuffer: CMSampleBuffer) {
    displayView.displayLayer.enqueue(sampleBuffer)
    return
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
          // 17 point
          //http://flexmonkey.blogspot.com/2016/04/recreating-kais-power-tools-goo-in-swift.html
          //CIWarpKernelでいけそうかも
          UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
          let ctx = UIGraphicsGetCurrentContext()!
          
          
          UIColor(displayP3Red: 0.5, green: 0, blue: 0, alpha: 1.0).setFill()
          ctx.fill(.init(x: 0, y: 0, width: width, height: height))
          
//          ctx.setStrokeColor(red: 0.6, green: 0, blue: 0, alpha: 1)
//          ctx.setLineWidth(10.0)
//          let points = faceContour.pointsInImage(imageSize: size)
//          ctx.move(to: points[0])
//          points.forEach({ ctx.addLine(to: $0) })
//          ctx.strokePath()
          
          let cgImage = ctx.makeImage()!
          UIGraphicsEndImageContext()
          
//          let ciImage = CIImage(cgImage: cgImage).oriented(.downMirrored)
          let ciImage = CIImage(cgImage: cgImage, options: [CIImageOption.colorSpace : colorSpace]).oriented(.downMirrored)
          
          let filter = MetalFilter()
          filter.locations = faceContour.pointsInImage(imageSize: size)
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
//    context.render(outputImage, to: resultPixelBuffer!)
    context.render(outputImage, to: resultPixelBuffer!, bounds: outputImage.extent, colorSpace: colorSpace)
    
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
