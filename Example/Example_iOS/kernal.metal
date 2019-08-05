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
    float2 warp(float a0, float a1, float2 c0, float2 j0, destination dest) {
      float2 location = dest.coord(); //現在の場所
      float diameter = distance(c0, j0); //鼻から顎までの距離
      float mu = (location.y - a0) / a1; //x軸上にある特徴点の場所
      float s = diameter / 10; //顔の大きさと傾きを係数にかけたい
      float g = gauss(location.x, mu, s);
      float r = 1 - pow(dist / diameter, 3);
      if (location.x < mu) {
        // 0.0 ~ 1.0
        return float2(location.x + (g * s * r), location.y);
      } else {
        // 1.0 ~ 0.0
        return float2(location.x + ((2.0 - g) * s * r), location.y);
      }
    }
    
    //左
    float2 reverse_warp(float a0, float a1, float2 c0, float2 j0, destination dest) {
      float2 location = dest.coord(); //現在の場所
      float dist = distance(c0, location); // 中心特徴点からの距離
      float diameter = distance(c0, j0);
      float mu = (location.y - a0) / a1; //x軸上にある特徴点の場所
      float s = diameter / 10; //顔の大きさと傾きを係数にかけたい
      float g = gauss(location.x, mu, s);
      if (dist < diameter) {
        float r = 1 - pow(dist / diameter, 3);
        if (location.x > mu) {
          // 0.0 ~ 1.0
          return float2(location.x - (g * s * r), location.y);
        } else {
          // 1.0 ~ 0.0
          return float2(location.x - ((2.0 - g) * s * r), location.y);
        }
      } else {
        return location;
      }
    }
    
    //http://pc-physics.com/lagrange.html
    float lambda(int i, int n, float x, float dataX[]) {
      int j;
      float lam = 1.0;
      for (j = 0 ; j < n ; j++) {
        if(i != j)
        {
          lam *= (x - dataX[j])/(dataX[i] - dataX[j]);
        }
      }
      return lam;
    }

    
    float2 warp2(float2 points[11], destination dest) {
      float2 location = dest.coord(); //現在の場所
      float f = 0;
      int i = 0;
      int n = 11;
      float dataX[11] = {};
      for (i = 0 ; i < n; i++) {
        dataX[i] = points[i].x;
      }
      for (i = 0 ; i < n; i++) {
        f += points[i].y * lambda(i, n, location.x, dataX);
      }
      
      if (f - location.y < 10.0) {
        return float2(0, 0);
      } else {
        return location;
      }
      return float2(location.x, location.y + f);
    }
    
  }
}
