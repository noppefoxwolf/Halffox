//
//  SampleBufferDisplayView.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/16.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import AVFoundation
import UIKit

class SampleBufferDisplayView: UIView {
  override class var layerClass: AnyClass { return AVSampleBufferDisplayLayer.self }
  var displayLayer: AVSampleBufferDisplayLayer { return layer as! AVSampleBufferDisplayLayer }
}
