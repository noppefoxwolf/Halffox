//
//  ViewController.swift
//  Highpass
//
//  Created by Tomoya Hirano on 2019/08/05.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
   
    
    let inputImage = CIImage(image: UIImage(named: "inputImage")!)!
    let radius: CGFloat = 5.0
    
    let blurOutput: CIImage
    blur: do {
      let filter = CIFilter(name: "CIGaussianBlur")!
      filter.setValue(inputImage, forKey: kCIInputImageKey)
      filter.setValue(radius, forKey: kCIInputRadiusKey)
      blurOutput = filter.outputImage!
    }
    
    let highpassOutput: CIImage
    highpass: do {
      let source = """
      kernel vec4 filterKernel(__sample image, __sample blurredImage) {
        return vec4(vec3(image.rgb - blurredImage.rgb + vec3(0.5,0.5,0.5)), image.a);
      }
      """
      let kernel = CIColorKernel(source: source)!
      highpassOutput = kernel.apply(extent: inputImage.extent, arguments: [inputImage, blurOutput])!
    }
    
    let linearLightBlendOutput: CIImage
    linearLightBlend: do {
      let foregroundOutput: CIImage
      foreground: do {
        //o.5倍
      }
      // https://developer.apple.com/documentation/coreimage/ciblendkernel
      let kernel = CIBlendKernel.linearLight
      linearLightBlendOutput = kernel.apply(extent: inputImage.extent, arguments: [highpassOutput, inputImage])!
    }
    
    let result = linearLightBlendOutput
    
  }


}

extension CIImage {
  func croppedToExtent() -> CIImage {
    return cropped(to: extent)
  }
}
