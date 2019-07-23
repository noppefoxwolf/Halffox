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
    float gauss(float x, float m, float s) {
      return exp( -pow(x - m, 2) / (2 * pow(s, 2)));
    }
    
    //https://algorithm.joho.info/programming/c-language/least-square-method/
    // http://hooktail.sub.jp/mathInPhys/fwhmsigma/
    // FWHM - Full Width at Half Maximum
    // FWHM ≒ 2.35σ
    // 2FWHM = 4.7σ
    float2 fit(float x[], float y[], int n) {
      int i = 0;
      float A00 = 0, A01 = 0, A02 = 0, A11 = 0, A12 = 0;
      for (i = 0; i < n; i++) {
        A00 += 1.0;
        A01 += x[i];
        A02 += y[i];
        A11 += x[i] * x[i];
        A12 += x[i] * y[i];
      }
      return float2((A02*A11-A01*A12) / (A00*A11-A01*A01), (A00*A12-A01*A02) / (A00*A11-A01*A01));
    }
    
    //右
    float2 warp(float a0, float a1, float x0, float x1, float y0, float y1, destination dest) {
      float2 location = dest.coord();
      if (x0 < location.x && location.x < x1 && y0 < location.y && location.y < y1) {
        float mu = (location.y - a0) / a1;
        float s = 1;
        float g = gauss(location.x, mu, s);
        if (location.x < mu) {
          // 0.0 ~ 1.0
          return float2(location.x - g * s, location.y);
        } else {
          // 1.0 ~ 0.0
          return float2(location.x - (2.0 - g) * s, location.y);
        }
      } else {
        return location;
      }
    }
    
    //左
    float2 reverse_warp(float a0, float a1, float x0, float x1, float y0, float y1, destination dest) {
      float2 location = dest.coord();
      if (x0 < location.x && location.x < x1 && y0 < location.y && location.y < y1) {
        float mu = (location.y - a0) / a1;
        float s = 1;
        float g = gauss(location.x, mu, s);
        if (mu < location.x) {
          return float2(location.x - g * s, location.y);
        } else {
          return float2(location.x - (2.0 - g) * s, location.y);
        }
      } else {
        return location;
      }
    }
  }
}
