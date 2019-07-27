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
  lazy var source: Source = CameraSource()
  var isEnabled: Bool = true
  
  override func loadView() {
    super.loadView()
    displayView.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(displayView, at: 0)
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
    if #available(iOS 13.0, *) {
      request.constellation = .constellation65Points
    } else {
      // Fallback on earlier versions
    }
  }
  
  @IBAction func switchAction(_ sender: UISwitch) {
    isEnabled = sender.isOn
    displayView.displayLayer.flushAndRemoveImage()
  }
  
}

extension ViewController: Output {
  func output(_ sampleBuffer: CMSampleBuffer) {
    if !isEnabled {
      DispatchQueue.main.async { [weak self] in
        self?.displayView.displayLayer.enqueue(sampleBuffer)
      }
      return
    }
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
          // 11 point iPhoneX
          // 17 point iPadPro / XR
          //http://flexmonkey.blogspot.com/2016/04/recreating-kais-power-tools-goo-in-swift.html

          let pointCount = faceContour.pointCount
          left: do {
            let filter = MetalFilter(isReverse: false)
            let points = faceContour.pointsInImage(imageSize: size)[5...10]
            let (a0, a1) = fit(points: points.map({ CIVector(x: $0.x, y: $0.y) }))
            let x0 = points.map({ $0.x }).min()!
            let x1 = points.map({ $0.x }).max()!
            let y0 = points.map({ $0.y }).min()!
            let y1 = points.map({ $0.y }).max()!
            filter.a0 = a0
            filter.a1 = a1
            filter.x0 = x0
            filter.x1 = x1
            filter.y0 = y0
            filter.y1 = y1
            filters.append(filter)
          }
          right: do {
            let filter = MetalFilter(isReverse: true)
            let points = faceContour.pointsInImage(imageSize: size)[0...5]
            let (a0, a1) = fit(points: points.map({ CIVector(x: $0.x, y: $0.y) }))
            let x0 = points.map({ $0.x }).min()!
            let x1 = points.map({ $0.x }).max()!
            let y0 = points.map({ $0.y }).min()!
            let y1 = points.map({ $0.y }).max()!
            filter.a0 = a0
            filter.a1 = a1
            filter.x0 = x0
            filter.x1 = x1
            filter.y0 = y0
            filter.y1 = y1
            filters.append(filter)
          }
        }
      }
    }
    
    let lastFilter: CIFilter = filters.reduce(into: filter as CIFilter, { (result, filter) in
      filter.setValue(result.outputImage!, forKey: kCIInputImageKey)
      result = filter
    })
    let outputImage = lastFilter.outputImage!
    
    var resultPixelBuffer: CVPixelBuffer? = nil
    let options: [String : Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
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

func hgoe() {
  let points: [CIVector] = [
    (204.3761064466671, 143.07658028616788),
    (203.24432600698492, 124.82329501915774),
    (201.1258521685195, 106.2884474237726),
    (196.79747462572595, 88.18849337624306),
    (187.87309004860253, 71.91756985917254),
    (174.54193821790432, 59.06172074146389),
    (158.57906429723153, 49.54490069592134),
    (141.18167704800362, 43.152921893414714),
    (122.62187812232514, 41.47481146651353),
    (108.65171055783776, 46.24232498345509),
    (98.15432445483839, 56.43128953932455),
    (89.19246037158337, 68.24847280123595),
    (82.51992678959687, 81.54666542117138),
    (78.34419345140213, 95.73596010171786),
    (75.71057003680244, 110.39235051174546),
    (74.92830513632043, 125.24046620859735),
    (75.45159605759864, 139.93187249814218)
  ].map({ CIVector.init(x: CGFloat($0.0), y: CGFloat($0.1)) })
}

func fit(points: [CIVector]) -> (a0: CGFloat, a1: CGFloat) {
    
    var A00: CGFloat = 0
    var A01: CGFloat = 0
    var A02: CGFloat = 0
    var A11: CGFloat = 0
    var A12: CGFloat = 0
    
    for point in points {
      A00 += 1.0
      A01 += point.x
      A02 += point.y;
      A11 += point.x * point.x
      A12 += point.x * point.y
    }
    return (a0: (A02*A11-A01*A12) / (A00*A11-A01*A01),
            a1: (A00*A12-A01*A02) / (A00*A11-A01*A01))
  }
