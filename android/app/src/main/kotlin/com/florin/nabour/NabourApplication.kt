package com.florin.nabour

import android.app.Application
import android.content.Context
import android.util.Log
import com.facebook.FacebookSdk

/**
 * Facebook SDK trebuie inițializat înainte ca [FlutterFacebookAuthPlugin] să
 * apeleze [LoginManager.getInstance] la înregistrare. [attachBaseContext] rulează
 * înainte de [onCreate]; unele build-uri înregistrează pluginurile foarte devreme.
 * Cu App ID placeholder, login-ul real în Graph eșuează, dar aplicația pornește.
 */
class NabourApplication : Application() {
    override fun attachBaseContext(base: Context) {
        initFacebookSdkFromResources(base)
        super.attachBaseContext(base)
    }

    override fun onCreate() {
        initFacebookSdkFromResources(this)
        super.onCreate()
    }

    private fun initFacebookSdkFromResources(context: Context) {
        if (facebookInitDone) return
        synchronized(initLock) {
            if (facebookInitDone) return
            try {
                val appId = context.resources.getString(R.string.facebook_app_id).trim()
                val clientToken =
                    context.resources.getString(R.string.facebook_client_token).trim()
                if (!isRealFacebookAppId(appId)) {
                    Log.i(
                        TAG,
                        "Facebook SDK: App ID placeholder — inițializare pentru flutter_facebook_auth.",
                    )
                }
                FacebookSdk.setApplicationId(appId.ifEmpty { PLACEHOLDER_APP_ID })
                if (clientToken.isNotEmpty()) {
                    FacebookSdk.setClientToken(clientToken)
                }
                FacebookSdk.fullyInitialize()
                facebookInitDone = true
                Log.i(TAG, "Facebook SDK ready isInitialized=${FacebookSdk.isInitialized()}")
            } catch (e: Throwable) {
                Log.e(TAG, "Facebook SDK init failed", e)
            }
        }
    }

    private fun isRealFacebookAppId(appId: String): Boolean {
        if (appId.isEmpty()) return false
        if (appId == "0000000000000000") return false
        if (appId.all { it == '0' }) return false
        return true
    }

    companion object {
        private const val TAG = "NabourApplication"
        private const val PLACEHOLDER_APP_ID = "0000000000000000"
        private val initLock = Any()
        @Volatile
        private var facebookInitDone = false
    }
}
