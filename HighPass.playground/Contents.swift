import UIKit

let inputImage = CIImage(image: #imageLiteral(resourceName: "inputImage.png"))!

let blurOutput: CIImage
blur: do {
  let filter = CIFilter(name: "CIGaussianBlur")!
  filter.setValue(inputImage, forKey: kCIInputImageKey)
  blurOutput = filter.outputImage!
}

let result = blurOutput
