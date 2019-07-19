//
//  kernel.metal
//  Example
//
//  Created by Tomoya Hirano on 2019/07/13.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
#include <metal_common>
#include <simd/simd.h>

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
      //gbra
      half4 s2s = s2.sample(s2.coord()); //移動量テクスチャ
      half4 s1s = s1.sample(s1.coord());
      
      float x = s1.coord().x;
      float offsetX = s2s.r - 0.5;
      float y = s1.coord().y;
      half4 s = s1.sample(float2(x + offsetX, y));
      
      return s;//half4(0.5 - s2s.r, 0.0, 0.0, 1.0);
    }
    
    //https://lensstudio.snapchat.com/templates/face/distort/
    //https://ccrma.stanford.edu/~jacobliu/368Report/index.html
    
    // x どのXか
    // m 膨らむ箇所
    // s ながらかさ
    // ガウス関数
    float f(float x, float m, float s) {
      return exp( -(pow(x, 2) - pow(m, 2)) / (2 * pow(s, 2)));
    }
    
    float2 warp(destination dest) {
      float2 c = dest.coord();
      float y = f(c.x, 128, 20);
      return float2(c.x, c.y + (1.0 - y));
    }
  }
}
