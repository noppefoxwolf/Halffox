//
//  DummyVideoDevice.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/17.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import AVFoundation

class InstanceFactory {
  static func make<T: NSObject>() -> T {
    let deviceType = NSClassFromString(NSStringFromClass(T.self)) as! NSObject.Type
    return deviceType.init() as! T
  }
}

class DummyFormat: AVCaptureDevice.Format {
}

final class DummyVideoDevice: AVCaptureDevice {
  static func make() -> DummyVideoDevice {
    return InstanceFactory.make()
  }
  
  override var uniqueID: String { return "" }
  override var modelID: String { return "" }
  override var localizedName: String { return "" }
  override func hasMediaType(_ mediaType: AVMediaType) -> Bool {
    return mediaType == .video
  }
  override func lockForConfiguration() throws {}
  override func unlockForConfiguration() {}
  override func supportsSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool { return true }
  override var isConnected: Bool { return true }
  override var formats: [AVCaptureDevice.Format] { return [] }
  override var activeFormat: AVCaptureDevice.Format {
    get { return InstanceFactory.make() as DummyFormat }
    set {}
  }
  override var activeVideoMinFrameDuration: CMTime {
    get { return .zero }
    set {}
  }
  override var activeVideoMaxFrameDuration: CMTime {
    get { return .zero }
    set {}
  }
}
