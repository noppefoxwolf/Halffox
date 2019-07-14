import CoreImage

class MetalFilter: CIFilter {
  
  private let kernel: CIColorKernel
  
  var inputImage: CIImage?
  var subImage: CIImage?
  
  override init() {
    guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib") else { preconditionFailure() }
    guard let data = try? Data(contentsOf: url) else { preconditionFailure() }
    kernel = try! CIColorKernel(functionName: "grayscale", fromMetalLibraryData: data)
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    guard let subImage = subImage else { return nil }
    //return kernel.apply(extent: inputImage.extent, arguments: [inputImage, subImage])
    return kernel.apply(extent: inputImage.extent, roiCallback: { _, r in r }, arguments: [inputImage, subImage])
  }
  
  override func setValue(_ value: Any?, forKey key: String) {
//    super.setValue(value, forKey: key)
    if key == kCIInputImageKey {
      inputImage = value as! CIImage
    }
  }
}
