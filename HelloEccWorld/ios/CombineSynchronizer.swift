//
//  CombineSynchronizer.swift
//  wallet
//
//  Created by Francisco Gindre on 1/27/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//
//
//import Foundation
//import Combine
//import ZcashLightClientKit
//class CombineSynchronizer {
//  
//  var initializer: Initializer {
//    synchronizer.initializer
//  }
//  private var synchronizer: SDKSynchronizer
//  
//  //    var walletDetailsBuffer: CurrentValueSubject<[DetailModel],Never>
//  var status: CurrentValueSubject<Status,Never>
//  var progress: CurrentValueSubject<Float,Never>
//  var syncBlockHeight: CurrentValueSubject<BlockHeight,Never>
//  var minedTransaction = PassthroughSubject<PendingTransactionEntity,Never>()
//  var balance: CurrentValueSubject<Double,Never>
//  var verifiedBalance: CurrentValueSubject<Double,Never>
//  var cancellables = [AnyCancellable]()
//  var errorPublisher = PassthroughSubject<Error, Never>()
//  var receivedTransactions: Future<[ConfirmedTransactionEntity],Never> {
//    Future<[ConfirmedTransactionEntity], Never>() {
//      promise in
//      DispatchQueue.global().async {
//        [weak self] in
//        guard let self = self else {
//          promise(.success([]))
//          return
//        }
//        promise(.success(self.synchronizer.receivedTransactions))
//      }
//    }
//  }
//  
//  var sentTransactions: Future<[ConfirmedTransactionEntity], Never> {
//    Future<[ConfirmedTransactionEntity], Never>() {
//      promise in
//      DispatchQueue.global().async {
//        [weak self] in
//        guard let self = self else {
//          promise(.success([]))
//          return
//        }
//        promise(.success(self.synchronizer.sentTransactions))
//      }
//    }
//  }
//  
//  var pendingTransactions: Future<[PendingTransactionEntity], Never> {
//    
//    Future<[PendingTransactionEntity], Never>(){
//      [weak self ] promise in
//      
//      guard let self = self else {
//        promise(.success([]))
//        return
//      }
//      
//      DispatchQueue.global().async {
//        promise(.success(self.synchronizer.pendingTransactions))
//      }
//    }
//  }
//  
//  init(initializer: Initializer) throws {
//
//    self.synchronizer = try SDKSynchronizer(initializer: initializer)
//    self.status = CurrentValueSubject(.disconnected)
//    self.progress = CurrentValueSubject(0)
//    self.balance = CurrentValueSubject(0)
//    self.verifiedBalance = CurrentValueSubject(0)
//    self.syncBlockHeight = CurrentValueSubject(ZcashSDK.SAPLING_ACTIVATION_HEIGHT)
//    
//    NotificationCenter.default.publisher(for: .synchronizerSynced).sink(receiveValue: { [weak self] _ in
//      guard let self = self else { return }
//      self.balance.send(initializer.getBalance().asHumanReadableZecBalance())
//      self.verifiedBalance.send(initializer.getVerifiedBalance().asHumanReadableZecBalance())
//    }).store(in: &cancellables)
//    
//    NotificationCenter.default.publisher(for: .synchronizerProgressUpdated).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] (progressNotification) in
//      guard let self = self else { return }
//      guard let newProgress = progressNotification.userInfo?[SDKSynchronizer.NotificationKeys.progress] as? Float else { return }
//      self.progress.send(newProgress)
//      
//      guard let blockHeight = progressNotification.userInfo?[SDKSynchronizer.NotificationKeys.blockHeight] as? BlockHeight else { return }
//      self.syncBlockHeight.send(blockHeight)
//    }).store(in: &cancellables)
//    
//    NotificationCenter.default.publisher(for: .synchronizerMinedTransaction).sink(receiveValue: { [weak self] minedNotification in
//      guard let self = self else { return }
//      guard let minedTx = minedNotification.userInfo?[SDKSynchronizer.NotificationKeys.minedTransaction] as? PendingTransactionEntity else { return }
//      self.minedTransaction.send(minedTx)
//    }).store(in: &cancellables)
//    
//    NotificationCenter.default.publisher(for: .synchronizerFailed).sink {[weak self] (notification) in
//      
//      guard let self = self else { return }
//      
//      guard let error = notification.userInfo?[SDKSynchronizer.NotificationKeys.error] as? Error else {
//        self.errorPublisher.send(WalletError.genericErrorWithMessage(message: "An error ocurred, but we can't figure out what it is. Please check device logs for more details")
//        )
//        return
//      }
//      self.errorPublisher.send(error)
//    }.store(in: &cancellables)
//    
//  }
//  
//  func start(retry: Bool = false){
//    
//    do {
//      if retry {
//        stop()
//      }
//      try synchronizer.start(retry: retry)
//    } catch {
//      //            logger.error("error starting \(error)")
//      self.errorPublisher.send(error)
//    }
//  }
//  
//  func stop() {
//    synchronizer.stop()
//  }
//  
//  func cancel(pendingTransaction: PendingTransactionEntity) -> Bool {
//    synchronizer.cancelSpend(transaction: pendingTransaction)
//  }
//  
//  deinit {
//    for c in cancellables {
//      c.cancel()
//    }
//  }
//  
//  func send(with spendingKey: String, zatoshi: Int64, to recipientAddress: String, memo: String?,from account: Int) -> Future<PendingTransactionEntity,Error>  {
//    Future<PendingTransactionEntity, Error>() {
//      promise in
//      self.synchronizer.sendToAddress(spendingKey: spendingKey, zatoshi: zatoshi, toAddress: recipientAddress, memo: memo, from: account) { (result) in
//        switch result {
//        case .failure(let error):
//          promise(.failure(error))
//        case .success(let pendingTx):
//          promise(.success(pendingTx))
//        }
//      }
//    }
//  }
//}
//
//



//
//  ZECCWalletEnvironment.swift
//  wallet
//
//  Created by Francisco Gindre on 1/23/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//
enum WalletState {
  case initalized
  case uninitialized
  case syncing
  case synced
}



func mapError(error: Error) -> WalletError {
  
  if let rustError = error as? RustWeldingError {
    switch rustError {
    case .genericError(let message):
      return WalletError.genericErrorWithMessage(message: message)
    case .dataDbInitFailed(let message):
      return WalletError.initializationFailed(message: message)
    case .dataDbNotEmpty:
      return WalletError.initializationFailed(message: "attempt to initialize a db that was not empty")
    case .saplingSpendParametersNotFound:
      return WalletError.createFailed(underlying: rustError)
    case .malformedStringInput:
      return WalletError.genericErrorWithError(error: rustError)
    default:
      return WalletError.genericErrorWithError(error: rustError)
    }
  } else if let synchronizerError = error as? SynchronizerError {
    switch synchronizerError {
    case .generalError(let message):
      return WalletError.genericErrorWithMessage(message: message)
    case .initFailed(let message):
      return WalletError.initializationFailed(message: "Synchronizer failed to initialize: \(message)")
    case .syncFailed:
      return WalletError.synchronizerFailed
    case .connectionFailed(let error):
      return WalletError.connectionFailedWithError(error: error)
    case .maxRetryAttemptsReached(attempts: let attempts):
      return WalletError.maxRetriesReached(attempts: attempts)
    case .connectionError:
      return WalletError.connectionFailed
    case .networkTimeout:
      return WalletError.networkTimeout
    case .uncategorized(let underlyingError):
      return WalletError.genericErrorWithError(error: underlyingError)
    case .criticalError:
      return WalletError.criticalError
    }
  } else if let serviceError = error as? LightWalletServiceError {
    switch serviceError {
    case .criticalError:
      return WalletError.criticalError
    case .userCancelled:
      return WalletError.connectionFailed
    case .unknown:
      return WalletError.connectionFailed
    case .failed:
      return WalletError.connectionFailedWithError(error: error)
    case .generalError:
      return WalletError.connectionFailed
    case .invalidBlock:
      return WalletError.genericErrorWithError(error: error)
    case .sentFailed(let error):
      return WalletError.sendFailed(error: error)
    case .genericError(error: let error):
      return WalletError.genericErrorWithError(error: error)
    case .timeOut:
      return WalletError.networkTimeout
    }
  }
  
  return WalletError.genericErrorWithError(error: error)
}


//
//  ErrorHandling.swift
//  ECC-Wallet
//
//  Created by Francisco Gindre on 8/7/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//

import Foundation

enum WalletError: Error {
  case createFailed(underlying: Error)
  case initializationFailed(message: String)
  case synchronizerFailed
  case genericErrorWithMessage(message: String)
  case genericErrorWithError(error: Error)
  case networkTimeout
  case connectionFailed
  case connectionFailedWithError(error: Error)
  case maxRetriesReached(attempts: Int)
  case sendFailed(error: Error)
  case criticalError
}


func mapToUserFacingError(_ walletError: WalletError) -> UserFacingErrors {
  switch walletError {
    
  case .createFailed:
    return .initalizationFailed
  case .initializationFailed:
    return .initalizationFailed
  case .synchronizerFailed:
    return .synchronizerError(canRetry: false)
  case .genericErrorWithMessage:
    return .internalError
  case .genericErrorWithError:
    return .internalError
  case .networkTimeout:
    return .connectionFailed
  case .connectionFailed:
    return .connectionFailed
  case .connectionFailedWithError:
    return .connectionFailed
  case .maxRetriesReached(_):
    return .synchronizerError(canRetry: true)
  case .sendFailed:
    return .transactionSubmissionError
  case .criticalError:
    return .criticalError
  }
}

enum UserFacingErrors: Error {
  case initalizationFailed
  case synchronizerError(canRetry: Bool)
  case connectionFailed
  case transactionSubmissionError
  case internalError
  case criticalError
}



//
//  BalanceUtils.swift
//  wallet
//
//  Created by Francisco Gindre on 1/2/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//

import Foundation
import ZcashLightClientKit

extension Int64 {
  func asHumanReadableZecBalance() -> Double {
    var decimal = Decimal(self) / Decimal(ZcashSDK.ZATOSHI_PER_ZEC)
    var rounded = Decimal()
    NSDecimalRound(&rounded, &decimal, 6, .bankers)
    return (rounded as NSDecimalNumber).doubleValue
  }
}

extension Double {
  
  
  static var defaultNetworkFee: Double = Int64(ZcashSDK.MINERS_FEE_ZATOSHI).asHumanReadableZecBalance()
  
  func toZatoshi() -> Int64 {
    var decimal = Decimal(self) * Decimal(ZcashSDK.ZATOSHI_PER_ZEC)
    var rounded = Decimal()
    NSDecimalRound(&rounded, &decimal, 6, .bankers)
    return (rounded as NSDecimalNumber).int64Value
  }
  // Absolute value + network fee
  func addingZcashNetworkFee(_ fee: Double = Self.defaultNetworkFee) -> Double {
    abs(self) + fee
  }
  
  func toZecAmount() -> String {
    NumberFormatter.zecAmountFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
  }
}

extension NumberFormatter {
  static var zecAmountFormatter: NumberFormatter {
    
    let fmt = NumberFormatter()
    
    fmt.alwaysShowsDecimalSeparator = false
    fmt.allowsFloats = true
    fmt.maximumFractionDigits = 8
    fmt.minimumFractionDigits = 0
    fmt.minimumIntegerDigits = 1
    return fmt
    
  }
  
  static var zeroBalanceFormatter: NumberFormatter {
    
    let fmt = NumberFormatter()
    
    fmt.alwaysShowsDecimalSeparator = false
    fmt.allowsFloats = true
    fmt.maximumFractionDigits = 0
    fmt.minimumFractionDigits = 0
    fmt.minimumIntegerDigits = 1
    return fmt
    
  }
}

