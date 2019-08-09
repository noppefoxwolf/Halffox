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
  private let scene: SKScene = .init(size: .init(width: 1920, height: 1080))
  private lazy var renderer: SKRenderer = .init(device: device)
  private var offscreenTexture: MTLTexture!
  private lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
  let planeNode: SKSpriteNode = .init()
  let camera = Camera()
  let skView: SKView = .init()
  
  
  override func loadView() {
    super.loadView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(imageView)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: imageView.topAnchor),
      view.leftAnchor.constraint(equalTo: imageView.leftAnchor),
      view.rightAnchor.constraint(equalTo: imageView.rightAnchor),
      view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 400),
    ])
    
    skView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(skView)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: skView.topAnchor, constant: -400),
      view.leftAnchor.constraint(equalTo: skView.leftAnchor),
      view.rightAnchor.constraint(equalTo: skView.rightAnchor),
      view.bottomAnchor.constraint(equalTo: skView.bottomAnchor),
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTexture()
    
    let source: [vector_float2] = [
      vector_float2(0, 0),   vector_float2(0.5, 0),   vector_float2(1, 0),
      vector_float2(0, 0.5), vector_float2(0.5, 0.5), vector_float2(1, 0.5),
      vector_float2(0, 1),   vector_float2(0.5, 1),   vector_float2(1, 1)
    ]
    
    //歪曲先つまみ点
    let distination: [vector_float2] = [
      vector_float2(0.25, 0),   vector_float2(0.75, 0),   vector_float2(1.25, 0),
      vector_float2(-0.25, 0.5), vector_float2(0.25, 0.5), vector_float2(0.75, 0.5),
      vector_float2(0.25, 1),   vector_float2(0.75, 1),   vector_float2(1.25, 1)
    ]
    let warp = SKWarpGeometryGrid(columns: 2, rows: 2, sourcePositions: source, destinationPositions: distination)
    planeNode.warpGeometry = warp
    
    imageView.backgroundColor = .cyan
    scene.backgroundColor = .red
    planeNode.position = .init(x: 1920 / 2 - 30, y: 1080 / 2 - 30)
    planeNode.size = .init(width: 1920, height: 1080)
    planeNode.color = .blue
    scene.addChild(planeNode)
    skView.presentScene(scene)
    
    camera.setSampleBufferDelegate(self, queue: .main)
    camera.startRunning()
  }
  
  private func setupTexture() {
    let textureSizeX: Int = 1920
    let textureSizeY: Int = 1080
    let bitsPerComponent = Int(8)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    var rawData0 = [UInt8](repeating: 0, count: Int(textureSizeX) * Int(textureSizeY) * 4)
    
    let bytesPerRow = 4 * Int(textureSizeX)
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
    
    let context = CGContext(data: &rawData0, width: Int(textureSizeX), height: Int(textureSizeY), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo)!
    context.setFillColor(UIColor.green.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: CGFloat(textureSizeX), height: CGFloat(textureSizeY)))
    
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(textureSizeX), height: Int(textureSizeY), mipmapped: false)
    
    textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
    
    let textureA = device.makeTexture(descriptor: textureDescriptor)!
    
    let region = MTLRegionMake2D(0, 0, Int(textureSizeX), Int(textureSizeY))
    textureA.replace(region: region, mipmapLevel: 0, withBytes: &rawData0, bytesPerRow: Int(bytesPerRow))
    
    offscreenTexture = textureA
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let viewport = CGRect(x: 0, y: 0, width: width, height: height)

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1.0); //green
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
      
      bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
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
//      planeNode.texture = texture
      planeNode.run(.setTexture(texture))
    }
    
    renderer.scene = scene
    renderer.render(withViewport: viewport, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
    commandBuffer.commit()

    imageView.image = UIImage(ciImage: CIImage(mtlTexture: offscreenTexture, options: [:])!)
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
