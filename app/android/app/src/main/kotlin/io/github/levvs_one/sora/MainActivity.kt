package io.github.levvs_one.sora

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** The bridge between the Flutter app and the parts only Android can do. */
class MainActivity : FlutterActivity() {
    private var consent: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sora/android")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "socketPath" -> result.success(CoreProcess.socketPath(this))
                "filesDir" -> result.success(filesDir.path)
                "prepareVpn" -> prepareVpn(result)
                "startVpn" -> startVpn(result)
                "setStatus" -> setStatus(call.arguments as? String ?: "", result)
                "openVpnSettings" -> {
                    startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                    result.success(null)
                }
                "alwaysOn" -> result.success(alwaysOn())
                "batteryUnrestricted" -> result.success(batteryUnrestricted())
                "askBatteryUnrestricted" -> askBatteryUnrestricted(result)
                "privateDnsHost" -> result.success(privateDnsHost())
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            askNotifications()
            result.success(true)
            return
        }
        consent = result
        startActivityForResult(intent, REQUEST_VPN)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_VPN) return
        consent?.success(resultCode == RESULT_OK)
        consent = null
        if (resultCode == RESULT_OK) askNotifications()
    }

    private fun askNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
    }

    private fun startVpn(result: MethodChannel.Result) {
        try {
            SoraVpnService.start(this)
            result.success(true)
        } catch (error: IllegalStateException) {
            result.success(false)
        }
    }

    private fun setStatus(status: String, result: MethodChannel.Result) {
        if (SoraVpnService.current != null) SoraVpnService.start(this, status)
        result.success(null)
    }

    /** Whether the system keeps this VPN on, and blocks traffic without it. */
    private fun alwaysOn(): Map<String, Boolean> {
        val service = SoraVpnService.current
        if (service == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return mapOf("on" to false, "lockdown" to false)
        }
        return mapOf("on" to service.isAlwaysOn, "lockdown" to service.isLockdownEnabled)
    }

    private fun batteryUnrestricted() =
        getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(packageName)

    @SuppressLint("BatteryLife")
    private fun askBatteryUnrestricted(result: MethodChannel.Result) {
        startActivity(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")),
        )
        result.success(null)
    }

    /** The host of a strict Private DNS, which sends lookups past the VPN. */
    private fun privateDnsHost(): String? {
        if (Settings.Global.getString(contentResolver, "private_dns_mode") != "hostname") return null
        return Settings.Global.getString(contentResolver, "private_dns_specifier")
    }

    companion object {
        private const val REQUEST_VPN = 1
        private const val REQUEST_NOTIFICATIONS = 2
    }
}
