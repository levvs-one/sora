package io.github.levvs_one.sora

import android.app.Application

/** Starts the core with the app, so subscriptions work before any session. */
class SoraApp : Application() {
    override fun onCreate() {
        super.onCreate()
        VpnHost.start(this)
        CoreProcess.start(this)
    }
}
