//
//  Source.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/16.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation

import ObjectiveC

extension AVCaptureDevice {
  @objc dynamic static func dummyDefault(for mediaType: AVMediaType) -> AVCaptureDevice? {
    switch mediaType {
    case .video:
      return DummyVideoDevice.make()
    default:
      return dummyDefault(for: mediaType)
    }
  }
  
  @objc dynamic static func dummyDefault(_ deviceType: AVCaptureDevice.DeviceType, for mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    switch mediaType {
    case .some(.video):
      return DummyVideoDevice.make()
    default:
      return dummyDefault(deviceType, for: mediaType, position: position)
    }
  }
  
  //TODO: support devices
  
  static let originalMethod = class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.default(for:)))!
  static let originalMethod2 = class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.default(_:for:position:)))!
  static let swizzledMethod = class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.dummyDefault(for:)))!
  static let swizzledMethod2 = class_getClassMethod(AVCaptureDevice.self, #selector(AVCaptureDevice.dummyDefault(_:for:position:)))!
  
  static func install() {
    method_exchangeImplementations(AVCaptureDevice.originalMethod, AVCaptureDevice.swizzledMethod)
    method_exchangeImplementations(AVCaptureDevice.originalMethod2, AVCaptureDevice.swizzledMethod2)
  }
}

extension AVCaptureDeviceInput {
  @objc static let originalMethod = class_getClassMethod(AVCaptureDeviceInput.self, #selector(AVCaptureDeviceInput.init(device:)))!
  @objc static let swizzledMethod = class_getClassMethod(AVCaptureDeviceInput.self, #selector(AVCaptureDeviceInput.dummyInit(device:)))!
  
  static func install() {
    
    method_exchangeImplementations(AVCaptureDeviceInput.originalMethod, AVCaptureDeviceInput.swizzledMethod)
  }
  
  @objc static func dummyInit(device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
    return InstanceFactory.make() as DummyAVCaptureDeviceInput
  }
}

class DummyAVCaptureDeviceInput: AVCaptureDeviceInput {
  override init(device: AVCaptureDevice) throws {
    try super.init(device: device)
  }
}




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
    let input = try! AVCaptureDeviceInput(device: device)
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
    
    let connection = output.connection(with: .video)!
    connection.videoOrientation = .landscapeRight
    connection.isVideoMirrored = true
    
    session.startRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.output(sampleBuffer)
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.output(sampleBuffer)
  }
}

class ImageSource: NSObject, Source {
  lazy var displayLink = CADisplayLink(target: self, selector: #selector(update))
  weak var delegate: Output? = nil
  
  override init() {
    super.init()
    displayLink.add(to: .main, forMode: .default)
  }
  
  @objc private func update(_ displayLink: CADisplayLink) {
    print("hoge")
    let image = UIImage(named: "lena.jpg")!
    delegate?.output(image.cmSampleBuffer)
  }
}

import ImageIO
import AVFoundation


extension UIImage {
  var cvPixelBuffer: CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer? = nil
    let options: [NSObject: Any] = [
      kCVPixelBufferCGImageCompatibilityKey: false,
      kCVPixelBufferCGBitmapContextCompatibilityKey: false,
    ]
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
    let rgbColorSpace = cgImage!.colorSpace!
    let bitmapInfo: UInt32 = cgImage!.bitmapInfo.rawValue
    
    // convert rgba to bgra
    let ctx = CIContext()
    let swapKernel = CIColorKernel( source:
      "kernel vec4 swapRedAndGreenAmount(__sample s) {" +
        "return s.bgra;" +
      "}"
    )!
    let ciImage = CIImage(cgImage: cgImage!)
    let ciOutput = swapKernel.apply(extent: ciImage.extent, arguments: [ciImage])
    let cgImage = ctx.createCGImage(ciOutput!, from: ciImage.extent)
    
    let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo)
    context?.draw(cgImage!, in: CGRect(origin: .zero, size: size))
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    return pixelBuffer
  }
  
  var cmSampleBuffer: CMSampleBuffer {
    let pixelBuffer = cvPixelBuffer
    var newSampleBuffer: CMSampleBuffer? = nil
    var timimgInfo: CMSampleTimingInfo = .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
    var videoInfo: CMVideoFormatDescription? = nil
    CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer!, formatDescriptionOut: &videoInfo)
    CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoInfo!, sampleTiming: &timimgInfo, sampleBufferOut: &newSampleBuffer)
    return newSampleBuffer!
  }
}
