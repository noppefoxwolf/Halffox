//
//  kernel.metal
//  Example
//
//  Created by Tomoya Hirano on 2019/07/13.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" {
  namespace coreimage {
//    half4 grayscale(sample_h s) {
//      half y = 0.2126 * s.r + 0.7152 * s.g + 0.0722 * s.b;
//      return half4(y, y, y, s.a);
//    }
    
    half4 grayscale(sampler_h s1, sampler_h s2) {
//    half y = 0.2126 * s.r + 0.7152 * s.g + 0.0722 * s.b;
//    half4(y, y, y, s.a);
      
//    return s * s2;
      half4 s2s = s2.sample(s1.coord()); //移動量テクスチャ
//      half4 s1s = s1.sample(s1.coord());
      float x = s1.coord().x + s2s.r;
      float y = s1.coord().y;
      half4 s = s1.sample(float2(x, y));
      return s;
    }
  }
}
