//
//  AppDelegate.swift
//  Example
//
//  Created by Tomoya Hirano on 2019/07/06.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation

//#if targetEnvironment(simulator)
import Holo
typealias AVCaptureDevice = AnyCaptureDevice
typealias AVCaptureDeviceInput = AnyCaptureDeviceInput
typealias AVCaptureSession = AnyCaptureSessionContainer
typealias AVCaptureVideoDataOutput = AnyCaptureVideoDataOutput
typealias AVCaptureConnection = AnyCaptureConnection
typealias AVCaptureVideoDataOutputSampleBufferDelegate = AnyCaptureVideoDataOutputSampleBufferDelegate
typealias AVCaptureOutput = AnyCaptureOutput
typealias AVCaptureInput =  AnyCaptureInput
//#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  lazy var window: UIWindow? = .init(frame: UIScreen.main.bounds)
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//    #if targetEnvironment(simulator)
    HoloSettings.shared.mode = .image(UIImage(named: "lena.jpg")!)
//    #endif
    window?.rootViewController = ViewController()
    window?.makeKeyAndVisible()
    return true
  }
}

