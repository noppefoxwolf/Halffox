//
//  kernel.metal
//  Example
//
//  Created by Tomoya Hirano on 2019/07/13.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>
extern "C" {
  namespace coreimage {
    half4 grayscale(sample_h s) {
      half y = 0.2126 * s.r + 0.7152 * s.g + 0.0722 * s.b;
      return half4(y, y, y, s.a);
    }
  }
}
