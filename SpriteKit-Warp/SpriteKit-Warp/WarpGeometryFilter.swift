//
//  WarpGeometryFilter.swift
//  SpriteKit-Warp
//
//  Created by beta on 2019/08/10.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import SpriteKit
import AVFoundation

let kCIInputWarpGeometryKey: String = "CIInputWarpGeometryKey"

class WarpGeometryFilter: CIFilter {
  private var inputImage: CIImage? = nil
  private var warpGeometry: SKWarpGeometryGrid? = nil
  private let engine: WarpGeometryFilterEngine = .init()
  
  override func setValue(_ value: Any?, forKey key: String) {
    switch key {
    case kCIInputImageKey:
      inputImage = value as? CIImage
    case kCIInputWarpGeometryKey:
      warpGeometry = value as? SKWarpGeometryGrid
    default: break
    }
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    guard let warpGeometry = warpGeometry else { return nil }
    engine.configure(warpGeometry: warpGeometry)
    return engine.process(ciImage: inputImage)
  }
}

private class WarpGeometryFilterEngine {
  private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
  private let scene: SKScene = .init()
  private lazy var renderer: SKRenderer = .init(device: device)
  private var offscreenTexture: MTLTexture!
  private lazy var commandQueue: MTLCommandQueue = device.makeCommandQueue()!
  let planeNode: SKSpriteNode = .init()
  
  init() {
    scene.addChild(planeNode)
  }
  
  func configure(warpGeometry: SKWarpGeometryGrid) {
    planeNode.warpGeometry = warpGeometry
  }
  
  private func setupTextureIfNeeded(pixelBuffer: CVPixelBuffer) {
    guard offscreenTexture == nil else { return }
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let pixelFormat: MTLPixelFormat = .rgba8Unorm
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    var rawData0 = [UInt8](repeating: 0, count: bytesPerRow * height)
    
    let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
    
    textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
    
    let texture = device.makeTexture(descriptor: textureDescriptor)!
    
    let region = MTLRegionMake2D(0, 0, width, height)
    texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData0, bytesPerRow: bytesPerRow)
    
    offscreenTexture = texture
  }
  
  func process(ciImage: CIImage) -> CIImage? {
    guard var pixelBuffer = ciImage.makePixelBuffer() else { return nil }
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
    
    return CIImage(mtlTexture: self.offscreenTexture, options: [.colorSpace : colorspace])
  }
  
  
}

