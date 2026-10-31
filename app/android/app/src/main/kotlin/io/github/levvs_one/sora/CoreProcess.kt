package io.github.levvs_one.sora

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log
import java.io.File
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/**
 * Runs sora-core as a child process, as the desktop service does. Android only
 * lets an app execute files from its native library directory, so the core and
 * the engines ship there as lib*.so.
 */
object CoreProcess {
    private const val TAG = "SoraCore"
    private const val MAX_DELAY_MS = 30_000L
    private val STALE = listOf("libsora_core.so", "libxray.so", "libmihomo.so")

    @Volatile
    private var started = false

    fun socketPath(context: Context) = File(dataDir(context), "core.sock").path

    private fun dataDir(context: Context) = File(context.filesDir, "core")

    private fun enginesDir(context: Context) = File(context.filesDir, "engines")

    /** Starts the core once and keeps it running while the app lives. */
    @Synchronized
    fun start(context: Context) {
        if (started) return
        started = true
        val app = context.applicationContext
        // The core dies with the thread that started it, so this one stays.
        thread(name = "sora-core", isDaemon = true) { supervise(app) }
    }

    private fun supervise(context: Context) {
        var delay = 500L
        while (true) {
            val began = System.currentTimeMillis()
            try {
                prepareEngines(context)
                run(context)
            } catch (error: Exception) {
                Log.e(TAG, "the core did not start", error)
            }
            if (System.currentTimeMillis() - began > MAX_DELAY_MS) delay = 500L
            Thread.sleep(delay)
            delay = (delay * 2).coerceAtMost(MAX_DELAY_MS)
        }
    }

    /** A previous run that died can leave its engines holding the adapter. */
    private fun killStale() {
        val own = Process.myPid()
        File("/proc").listFiles()?.mapNotNull { it.name.toIntOrNull() }?.forEach { pid ->
            if (pid == own) return@forEach
            val command = runCatching { File("/proc/$pid/cmdline").readText() }.getOrNull() ?: return@forEach
            if (STALE.any { it in command }) Process.killProcess(pid)
        }
    }

    private fun run(context: Context) {
        killStale()
        val native = context.applicationInfo.nativeLibraryDir
        val data = dataDir(context).apply { mkdirs() }
        val process = ProcessBuilder(
            "$native/libsora_core.so",
            "-socket", socketPath(context),
            "-data-dir", data.path,
            "-engines-dir", enginesDir(context).path,
            "-allow-file-keys",
            "-vpn-host", VpnHost.name(),
        ).apply {
            directory(data)
            redirectErrorStream(true)
            environment().apply {
                put("HOME", context.filesDir.path)
                put("TMPDIR", context.cacheDir.path)
                put("SORA_DEVICE_ID", deviceId(context))
                put("SORA_OS_VERSION", Build.VERSION.RELEASE ?: "")
            }
        }.start()
        process.inputStream.bufferedReader().forEachLine { Log.i(TAG, it) }
        process.waitFor(1, TimeUnit.SECONDS)
        Log.w(TAG, "the core stopped")
    }

    @SuppressLint("HardwareIds")
    private fun deviceId(context: Context) =
        Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: ""

    /** Links the engines where the core looks and unpacks their geo data. */
    private fun prepareEngines(context: Context) {
        val dir = enginesDir(context).apply { mkdirs() }
        val native = context.applicationInfo.nativeLibraryDir
        for ((name, library) in listOf("xray" to "libxray.so", "mihomo" to "libmihomo.so")) {
            val link = File(dir, name).toPath()
            java.nio.file.Files.deleteIfExists(link)
            java.nio.file.Files.createSymbolicLink(link, File(native, library).toPath())
        }
        val stamp = File(dir, ".geo-version")
        val version = context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime.toString()
        if (stamp.takeIf { it.exists() }?.readText() == version) return
        for (name in listOf("geoip.dat", "geosite.dat")) {
            context.assets.open("geo/$name").use { input ->
                File(dir, name).outputStream().use { input.copyTo(it) }
            }
        }
        stamp.writeText(version)
    }

    val myUid get() = Process.myUid()
}
