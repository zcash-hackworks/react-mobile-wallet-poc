package com.helloeccworld

import android.app.Application
import cash.z.ecc.android.sdk.ext.TroubleshootingTwig
import cash.z.ecc.android.sdk.ext.Twig
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.soloader.SoLoader
import com.helloeccworld.sdk.ZcashSdkModule

class App : Application(), ReactApplication {

    private val mReactNativeHost: ReactNativeHost = object : ReactNativeHost(this) {
        override fun getUseDeveloperSupport() = BuildConfig.DEBUG
        override fun getJSMainModuleName() = "index"
        override fun getPackages() = PackageList(this).packages.apply {
            add(ZcashSdkModule.Package)
        }
    }

    override fun getReactNativeHost(): ReactNativeHost? {
        return mReactNativeHost
    }

    override fun onCreate() {
        super.onCreate()
        SoLoader.init(this, false)
        Twig.plant(TroubleshootingTwig())
    }
}