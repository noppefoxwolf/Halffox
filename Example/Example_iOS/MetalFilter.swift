import CoreImage
import simd

extension CIWarpKernel {
  static var warp: CIWarpKernel {
    let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
    let data = try! Data(contentsOf: url)
    return try! CIWarpKernel(functionName: "warp", fromMetalLibraryData: data)
  }
  
  static var reverseWarp: CIWarpKernel {
      let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
      let data = try! Data(contentsOf: url)
      return try! CIWarpKernel(functionName: "reverse_warp", fromMetalLibraryData: data)
  }
  
  static var warp2: CIWarpKernel {
      let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
      let data = try! Data(contentsOf: url)
    do {
      return try CIWarpKernel(functionName: "warp2", fromMetalLibraryData: data)
    } catch {
      debugPrint(error)
      preconditionFailure()
    }
  }
}

class MetalFilter: CIFilter {
  
//  private let kernel: CIColorKernel
  private let kernel: CIWarpKernel
  
  var inputImage: CIImage?
  var subImage: CIImage?
  var a0: CGFloat = 0
  var a1: CGFloat = 0
  var c0: CIVector = .init()
  var j0: CIVector = .init()
  
  init(isReverse: Bool = false) {
    kernel = isReverse ? .reverseWarp : .warp
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    return kernel.apply(extent: inputImage.extent, roiCallback: { _, r in r }, image: inputImage, arguments: [a0, a1, c0, j0])
  }
  
  override func setValue(_ value: Any?, forKey key: String) {
//    super.setValue(value, forKey: key)
    if key == kCIInputImageKey {
      inputImage = value as! CIImage
    }
  }
}

class BFilter: CIFilter {
  private let kernel: CIWarpKernel
  private var inputImage: CIImage?
  var points: [CGPoint] = []
  
  override init() {
    kernel = .warp2
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var outputImage: CIImage? {
    guard let inputImage = inputImage else { return nil }
    
    let floatArr: [CGFloat] = points.reduce(into: [CGFloat](), {
      $0.append($1.x)
      $0.append($1.y)
    })
    let vector = CIVector(values: floatArr, count: floatArr.count)
    
    return kernel.apply(extent: inputImage.extent, roiCallback: { _, r in r }, image: inputImage, arguments: [vector])
  }
  
  override func setValue(_ value: Any?, forKey key: String) {
  //    super.setValue(value, forKey: key)
      if key == kCIInputImageKey {
        inputImage = value as! CIImage
      }
    }
}
