package io.github.levvs_one.sora

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import org.json.JSONObject

/** What the core asks the adapter to carry. */
data class TunRequest(val addresses: List<String>, val dns: List<String>, val mtu: Int) {
    companion object {
        fun from(json: JSONObject) = TunRequest(
            addresses = json.optJSONArray("addresses").strings(),
            dns = json.optJSONArray("dns").strings(),
            mtu = json.optInt("mtu").takeIf { it > 0 } ?: 1500,
        )

        private fun org.json.JSONArray?.strings() =
            if (this == null) emptyList() else List(length()) { getString(it) }
    }
}

/**
 * Holds the VPN adapter while a session runs. The core and engines keep working
 * as child processes of this app, whose own traffic stays outside the VPN, so
 * nothing has to protect sockets one by one.
 */
class SoraVpnService : VpnService() {
    private val main = Handler(Looper.getMainLooper())
    private var adapter: ParcelFileDescriptor? = null
    private var request: TunRequest? = null
    private var status: String = ""
    private val stop = Runnable { shutDown() }

    private val network = object : ConnectivityManager.NetworkCallback() {
        private var known: Network? = null

        override fun onAvailable(network: Network) {
            val moved = known != null && known != network
            known = network
            setUnderlyingNetworks(arrayOf(network))
            if (moved) VpnHost.publish("network")
        }
    }

    override fun onCreate() {
        super.onCreate()
        current = this
        getSystemService(ConnectivityManager::class.java).registerDefaultNetworkCallback(network)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            VpnHost.publish("revoked")
            return START_NOT_STICKY
        }
        intent?.getStringExtra(EXTRA_STATUS)?.let { status = it }
        startInForeground()
        return START_NOT_STICKY
    }

    private fun startInForeground() {
        val notification = notification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION, notification)
        }
    }

    /** Returns a copy of the adapter, reusing it while the request is the same. */
    @Synchronized
    fun open(wanted: TunRequest): ParcelFileDescriptor {
        main.removeCallbacks(stop)
        adapter?.takeIf { request == wanted }?.let { return it.dup() }
        val builder = Builder().setSession(getString(R.string.app_name)).setMtu(wanted.mtu)
        var ipv6 = false
        for (address in wanted.addresses) {
            val (host, prefix) = address.split('/')
            builder.addAddress(host, prefix.toInt())
            ipv6 = ipv6 || host.contains(':')
        }
        builder.addRoute("0.0.0.0", 0)
        if (ipv6) builder.addRoute("::", 0)
        wanted.dns.forEach { builder.addDnsServer(it) }
        // The core and engines run as this app; their traffic must not loop.
        builder.addDisallowedApplication(packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false)
        val opened = builder.establish() ?: error("the VPN permission is missing")
        adapter?.close()
        adapter = opened
        request = wanted
        return opened.dup()
    }

    /** Waits briefly, because a replacement session asks for the adapter again. */
    fun release() {
        main.removeCallbacks(stop)
        main.postDelayed(stop, RELEASE_DELAY_MS)
    }

    @Synchronized
    private fun shutDown() {
        adapter?.close()
        adapter = null
        request = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onRevoke() {
        VpnHost.publish("revoked")
        shutDown()
    }

    override fun onDestroy() {
        getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(network)
        adapter?.close()
        adapter = null
        if (current === this) current = null
        super.onDestroy()
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.vpn_channel), NotificationManager.IMPORTANCE_LOW),
        )
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE,
        )
        val disconnect = PendingIntent.getService(
            this, 1, Intent(this, SoraVpnService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(status.ifEmpty { getString(R.string.vpn_connected) })
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, getString(R.string.vpn_disconnect), disconnect).build())
            .build()
    }

    companion object {
        private const val TAG = "SoraVpn"
        private const val CHANNEL = "vpn"
        private const val NOTIFICATION = 1
        private const val RELEASE_DELAY_MS = 1500L
        private const val START_TIMEOUT_MS = 5000L
        private const val ACTION_STOP = "io.github.levvs_one.sora.STOP"
        private const val EXTRA_STATUS = "status"

        @Volatile
        var current: SoraVpnService? = null
            private set

        /** Starts the service, or updates what its notification says. */
        fun start(context: Context, status: String = "") {
            val intent = Intent(context, SoraVpnService::class.java)
            if (status.isNotEmpty()) intent.putExtra(EXTRA_STATUS, status)
            context.startForegroundService(intent)
        }

        /** The running service, started on demand for a reconnecting session. */
        fun await(context: Context): SoraVpnService? {
            current?.let { return it }
            try {
                start(context)
            } catch (error: IllegalStateException) {
                Log.w(TAG, "the system refused to start the VPN service", error)
                return null
            }
            val deadline = System.currentTimeMillis() + START_TIMEOUT_MS
            while (System.currentTimeMillis() < deadline) {
                current?.let { return it }
                Thread.sleep(50)
            }
            return null
        }
    }
}
