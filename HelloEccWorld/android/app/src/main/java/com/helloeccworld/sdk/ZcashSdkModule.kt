package com.helloeccworld.sdk

import android.widget.Toast
import cash.z.ecc.android.sdk.service.LightWalletGrpcService
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.*
import com.facebook.react.uimanager.ViewManager


class ZcashSdkModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    override fun getName() = "ZcashReactSdk"


    @ReactMethod
    fun show(message: String?) {
        Toast.makeText(reactApplicationContext, message, Toast.LENGTH_SHORT).show()
    }

    @ReactMethod
    fun getLatestHeight(promise: Promise) {
        try {
            LightWalletGrpcService(
                reactApplicationContext,
                "lightwalletd.electriccoin.co",
                9067
            ).getLatestBlockHeight().let {
                promise.resolve(it)
            }
        } catch (t: Throwable) {
            promise.reject(t)
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