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
    float2 warp(float2 fromLocation, float2 toLocation, destination dest) {
//      float dist = distance(location, dest.coord());
//      if (dist < 100.0) {
//        return dest.coord() * 2.0;
//      } else {
//        return dest.coord();
//      }
      return dest.coord();
    }
//    "kernel vec2 gooWarp(float radius, float force,  vec2 location, vec2 direction)" +
//    "{ " +
//    " float dist = distance(location, destCoord()); " +
//
//    "  if (dist < radius)" +
//    "  { " +
//
//    "     float normalisedDistance = 1.0 - (dist / radius); " +
//    "     float smoothedDistance = smoothstep(0.0, 1.0, normalisedDistance); " +
//
//    "    return destCoord() + (direction * force) * smoothedDistance; " +
//    "  } else { " +
//    "  return destCoord();" +
//    "  }" +
//    "}")!
  }
}
