import CoreImage

extension CIWarpKernel {
  static var warp: CIWarpKernel {
    let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
    let data = try! Data(contentsOf: url)
    return try! CIWarpKernel(functionName: "warp", fromMetalLibraryData: data)
  }
}

class MetalFilter: CIFilter {
  
//  private let kernel: CIColorKernel
  private let kernel: CIWarpKernel
  
  var inputImage: CIImage?
  var subImage: CIImage?
  var a0: CGFloat = 0
  var a1: CGFloat = 0
  var x0: CGFloat = 0
  var x1: CGFloat = 0
  
  override init() {
    kernel = .warp
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    return kernel.apply(extent: inputImage.extent, roiCallback: { _, r in r }, image: inputImage, arguments: [a0, a1, x0, x1])
  }
  
  override func setValue(_ value: Any?, forKey key: String) {
//    super.setValue(value, forKey: key)
    if key == kCIInputImageKey {
      inputImage = value as! CIImage
    }
  }
}
