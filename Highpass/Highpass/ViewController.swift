//
//  ViewController.swift
//  Highpass
//
//  Created by Tomoya Hirano on 2019/08/05.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.contentMode = .scaleAspectFit
    
//    example: do {
//      let a = CIImage(image: UIImage(named: "A")!)!
//      let b = CIImage(image: UIImage(named: "B")!)!
//      let kernel = CIBlendKernel.linearLight
//      let result = kernel.apply(foreground: a, background: b)!
//      let context = CIContext()
//      let resultUIImage = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
//      imageView.image = resultUIImage
//    }
//    return
    
    let inputImage = CIImage(image: UIImage(named: "inputImage")!)!
    let radius: Double = 5.0
    
    let blurOutput: CIImage
    blur: do {
//      let filter = CIFilter(name: "CIGaussianBlur")!
//      filter.setValue(inputImage, forKey: kCIInputImageKey)
//      filter.setValue(radius, forKey: kCIInputRadiusKey)
      //blurOutput = filter.outputImage!
      blurOutput = inputImage.clampedToExtent().applyingGaussianBlur(sigma: radius).cropped(to: inputImage.extent)
      
//      render(result: blurOutput)
    }
//    return
    
    let highpassOutput: CIImage
    highpass: do {
      let source = """
      kernel vec4 filterKernel(__sample image, __sample blurredImage) {
        return vec4(vec3(image.rgb - blurredImage.rgb + 0.5), image.a);
      }
      """
      let kernel = CIColorKernel(source: source)!
      highpassOutput = kernel.apply(extent: inputImage.extent, arguments: [inputImage, blurOutput])!
    }
    
    let linearLightBlendOutput: CIImage
    linearLightBlend: do {
      // https://developer.apple.com/documentation/coreimage/ciblendkernel
      //https://github.com/MetalPetal/MetalPetal/blob/237287fcf4a555c11af6147ca61060f7285e5bea/Frameworks/MetalPetal/Shaders/MTIShaderLib.h
      let kernel = CIBlendKernel.linearLight
      linearLightBlendOutput = kernel.apply(foreground: highpassOutput, background: inputImage)!
      
      //https://helpx.adobe.com/jp/photoshop/using/blending-modes.html
      // リニアライト
//      合成色に応じて明るさを減少または増加させ、カラーの焼き込みまたは覆い焼きを行います。合成色（光源）が 50 ％グレーより明るい場合は、明るさを増して画像を明るくします。合成色が 50 ％グレーより暗い場合は、明るさを落として画像を暗くします。
//      let source = """
//      kernel vec4 filterKernel(__sample foreground, __sample background) {
//        return (foreground + background) / 2.0;
//      }
//      """
//      let kernel = CIBlendKernel(source: source)!
//      linearLightBlendOutput = kernel.apply(foreground: highpassOutput, background: inputImage)!
    }
    
    let result = linearLightBlendOutput
    render(result: result)
  }
  
  func render(result: CIImage) {
    let context = CIContext()
    let resultUIImage = UIImage(cgImage: context.createCGImage(result, from: result.extent)!)
    imageView.image = resultUIImage
  }
  
  
}

