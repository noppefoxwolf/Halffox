//
//  ViewController.swift
//  SpriteKit-Warp
//
//  Created by Tomoya Hirano on 2019/08/09.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class ViewController: UIViewController {
  
  private let imageView: UIImageView = .init()
  
  private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
  private let scene: SKScene = .init()
  private lazy var renderer: SKRenderer = .init(device: device)
  private var offscreenTexture: MTLTexture!
  private lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
  let planeNode: SKSpriteNode = .init()
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
    let warp = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: source, destinationPositions: distination)
    planeNode.warpGeometry = warp
    scene.addChild(planeNode)
    
    
    
    camera.setSampleBufferDelegate(self, queue: .global())
    camera.startRunning()
  }
  
  private func setupTextureIfNeeded(pixelBuffer: CVPixelBuffer) {
    guard offscreenTexture == nil else { return }
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let rawPixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    let pixelFormat = MTLPixelFormat(pixelFormat: rawPixelFormat)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    var rawData0 = [UInt8](repeating: 0, count: bytesPerRow * height)

    let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
    
    textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
    
    let texture = device.makeTexture(descriptor: textureDescriptor)!
    
    let region = MTLRegionMake2D(0, 0, width, height)
    texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData0, bytesPerRow: bytesPerRow)
    
    offscreenTexture = texture
  }
}

extension MTLPixelFormat {
  init(pixelFormat: OSType) {
    switch pixelFormat {
    case kCVPixelFormatType_32ARGB:
      preconditionFailure("not supported \(pixelFormat)")
    case kCVPixelFormatType_32BGRA:
      self = MTLPixelFormat.rgba8Unorm
    default:
      preconditionFailure("not supported \(pixelFormat)")
    }
  }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    setupTextureIfNeeded(pixelBuffer: pixelBuffer)
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    scene.size = .init(width: width, height: height)
    planeNode.position = .init(x: width / 2, y: height / 2)
    planeNode.size = .init(width: width, height: height)
    
    let viewport = CGRect(x: 0, y: 0, width: width, height: height)

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
    let sourceBaseAddr = CVPixelBufferGetBaseAddress(pixelBuffer)!
    let colorspace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    let bitmapInfo: CGBitmapInfo
    switch pixelFormat {
    case kCVPixelFormatType_32ARGB:
      bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
    case kCVPixelFormatType_32BGRA:
//      bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
      bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

    default:
      preconditionFailure("not support \(pixelFormat)")
    }
    
    let provider = CGDataProvider(dataInfo: &pixelBuffer, data: sourceBaseAddr, size: bytesPerRow * height, releaseData: { (rawPixelBuffer, data, size) in
      let usedPixelBuffer = rawPixelBuffer!.bindMemory(to: CVPixelBuffer.self, capacity: size)
      CVPixelBufferUnlockBaseAddress(usedPixelBuffer.pointee, .init(rawValue: 0))
    })!
    if let image = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: colorspace,
      bitmapInfo: bitmapInfo,
      provider: provider,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent) {
      
      let texture = SKTexture(cgImage: image)
      planeNode.texture = texture
    }
    
    renderer.scene = scene
    renderer.render(withViewport: viewport, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    DispatchQueue.main.async {
      let ciImage = CIImage(mtlTexture: self.offscreenTexture, options: [CIImageOption.colorSpace:CGColorSpaceCreateDeviceRGB()])!
      let result = UIImage(ciImage: ciImage)
      self.imageView.image = result
    }
  }
  
  func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
  }
}
















// ==================================

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
