//
//  ZcashSDKModule.swift
//  HelloEccWorld
//
//  Created by Francisco Gindre on 9/10/20.
//

import Foundation
import ZcashLightClientKit
import UIKit


class ZcashReactSdk: RCTEventEmitter {
  let service = LightWalletGRPCService(endpoint: LightWalletEndpoint(address: "lightwalletd.electriccoin.co", port: 9067))
  var synchronizer: SDKSynchronizer
  static let updateEvent = "UpdateEvent"

  override func supportedEvents() -> [String] {
    [ Self.updateEvent ]
  }
  override init() {
    let initializer = Initializer.init(cacheDbURL: try! URL.cacheDbURL(),
                                       dataDbURL: try! URL.dataDbURL() ,
                                       pendingDbURL: try! URL.pendingDbURL(),
                                       endpoint: LightWalletEndpoint(address: "lightwalletd.electriccoin.co", port: 9067),
                                       spendParamsURL: try! URL.spendParamsURL(),
                                       outputParamsURL: try! URL.spendParamsURL())
    self.synchronizer = try! SDKSynchronizer(initializer: initializer)
    
    
  }
  
  @objc func initialize(vk: String, birthday: Int, resolve resolveBlock: @escaping RCTPromiseResolveBlock, reject rejectBlock: @escaping RCTPromiseRejectBlock) {
    
    
    
    service.latestBlockHeight(result: { result in
      switch result {
      case .success(let height):
        self.sendEvent(withName: Self.updateEvent, body: [
          "balance" : "0",
          "networkBlockHeight" : String(height)
        ])
        resolveBlock(nil)
      case .failure(let error):
        rejectBlock("Error","error", error)
      }
    })
    
  }
  
  @objc func show(message: String) {
    let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(.init(title: "Dismiss", style: .default, handler: nil))
    
    guard let applicationWindow = UIApplication.shared.windows.first?.window,
      let rootViewController = applicationWindow.rootViewController else {
        print("cant locate main window!")
        return
    }
    rootViewController.present(alert, animated: true, completion: nil )
  }
  
  @objc func processorUpdated(_ notification: Notification) {
    
  }
}



extension URL {
  
  static func documentsDirectory() throws -> URL {
    try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  }
  
  static func cacheDbURL() throws -> URL {
    try documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_CACHES_DB_NAME, isDirectory: false)
  }
  
  static func dataDbURL() throws -> URL {
    try documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_DATA_DB_NAME, isDirectory: false)
  }
  
  static func pendingDbURL() throws -> URL {
    try documentsDirectory().appendingPathComponent(ZcashSDK.DEFAULT_DB_NAME_PREFIX+ZcashSDK.DEFAULT_PENDING_DB_NAME)
  }
  
  static func spendParamsURL() throws -> URL {
    Bundle.main.url(forResource: "sapling-spend", withExtension: ".params")!
  }
  
  static func outputParamsURL() throws -> URL {
    Bundle.main.url(forResource: "sapling-output", withExtension: ".params")!
  }
}
