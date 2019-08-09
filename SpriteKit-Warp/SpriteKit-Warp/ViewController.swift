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
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    
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
  let context = CIContext()
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//    imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored))
    

//    let width = CVPixelBufferGetWidth(pixelBuffer)
//    let height = CVPixelBufferGetHeight(pixelBuffer)
//    let viewport = CGRect(x: 0, y: 0, width: width, height: height)
//
//    let renderPassDescriptor = MTLRenderPassDescriptor()
//    renderPassDescriptor.colorAttachments[0].texture = offscreenTexture
//    renderPassDescriptor.colorAttachments[0].loadAction = .clear
//    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1.0); //green
//    renderPassDescriptor.colorAttachments[0].storeAction = .store
//
//    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
    let texture = SKTexture(cgImage: cgImage)
//    planeNode.texture = texture
    planeNode.run(.setTexture(texture))
//    renderer.scene = scene
//    renderer.render(withViewport: viewport, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
//    commandBuffer.commit()

//    imageView.image = UIImage(ciImage: CIImage(mtlTexture: offscreenTexture, options: [:])!)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
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
