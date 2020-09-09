package com.helloeccworld.sdk

import android.widget.Toast
import cash.z.ecc.android.sdk.SdkSynchronizer
import cash.z.ecc.android.sdk.Synchronizer
import cash.z.ecc.android.sdk.VkInitializer
import cash.z.ecc.android.sdk.block.CompactBlockProcessor
import cash.z.ecc.android.sdk.ext.collectWith
import cash.z.ecc.android.sdk.ext.convertZatoshiToZecString
import cash.z.ecc.android.sdk.service.LightWalletGrpcService
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.ViewManager


class ZcashSdkModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    lateinit var synchronizer: SdkSynchronizer
    var isInitialized = false
    var isStarted = false

    override fun getName() = "ZcashReactSdk"


    @ReactMethod
    fun show(message: String?) {
        Toast.makeText(reactApplicationContext, "$message ID: ${synchronizer}", Toast.LENGTH_SHORT).show()
    }

    @ReactMethod
    fun initialize(vk: String, birthdayHeight: Int, promise: Promise) {
        if (!isInitialized) {
            synchronizer = Synchronizer(VkInitializer(reactApplicationContext) {
                host = "lightwalletd.electriccoin.co"
                port = 9067
                alias = "ReactPoC"
                viewingKeys(vk)
                importedWalletBirthday(birthdayHeight)
            }) as SdkSynchronizer
            promise.resolve(synchronizer.hashCode().toString())
            isInitialized = true
        } else {
            promise.reject("noInit", "Not initialized.")
        }
    }

    @ReactMethod
    fun start() {
        if (isInitialized && !isStarted) {
            synchronizer.start()
            synchronizer.coroutineScope.let { scope ->
                synchronizer.processorInfo.collectWith(scope, ::onUpdate)
                synchronizer.status.collectWith(scope, ::onStatus)
                synchronizer.balances.collectWith(scope, ::onBalance)
            }
            isStarted = true
        }
    }

    private fun onBalance(walletBalance: CompactBlockProcessor.WalletBalance) {
        sendEvent("BalanceEvent") { args ->
            args.putString("available", walletBalance.availableZatoshi.convertZatoshiToZecString())
            args.putString("total", walletBalance.totalZatoshi.convertZatoshiToZecString())
        }
    }

    private fun onStatus(status: Synchronizer.Status) {
        sendEvent("StatusEvent") { args ->
            args.putString("name", status.name)
        }
    }

    private fun onUpdate(processorInfo: CompactBlockProcessor.ProcessorInfo) {
        sendEvent("UpdateEvent") { args ->
            processorInfo.let { info ->
                args.putBoolean("isDownloading", info.isDownloading)
                args.putBoolean("isScanning", info.isScanning)
                args.putInt("lastDownloadedHeight", info.lastDownloadedHeight)
                args.putInt("lastScannedHeight", info.lastScannedHeight)
                args.putInt("scanProgress", info.scanProgress)
                args.putInt("networkBlockHeight", info.networkBlockHeight)
                args.putString(
                    "balance",
                    synchronizer.latestBalance.totalZatoshi.convertZatoshiToZecString()
                )
            }
        }
    }

    private fun sendEvent(eventName: String, putArgs: (WritableMap) -> Unit) {
        Arguments.createMap().let { args ->
            putArgs(args)
            reactApplicationContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(eventName, args)
        }
    }

    companion object Package : ReactPackage {
        override fun createViewManagers(c: ReactApplicationContext): List<ViewManager<*, *>> =
            emptyList()

        override fun createNativeModules(reactContext: ReactApplicationContext) =
            listOf<NativeModule>(
                ZcashSdkModule(reactContext)
            )
    }
}