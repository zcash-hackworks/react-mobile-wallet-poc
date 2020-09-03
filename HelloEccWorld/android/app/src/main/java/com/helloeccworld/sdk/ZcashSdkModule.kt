package com.helloeccworld.sdk

import android.widget.Toast
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.uimanager.ViewManager


class ZcashSdkModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    override fun getName() = "ZcashReactSdk"

    @ReactMethod
    fun show(message: String?) {
        Toast.makeText(reactApplicationContext, message, Toast.LENGTH_SHORT).show()
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