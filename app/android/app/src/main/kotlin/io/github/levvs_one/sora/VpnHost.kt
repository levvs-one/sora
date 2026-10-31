package io.github.levvs_one.sora

import android.content.Context
import android.net.LocalServerSocket
import android.net.LocalSocket
import android.util.Log
import org.json.JSONObject
import java.io.IOException
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.concurrent.thread

/**
 * The socket the core calls to get the VPN adapter, which only the app can
 * create. Abstract sockets are visible to other apps, so each peer's user is
 * checked before anything is read.
 */
object VpnHost {
    private const val TAG = "SoraVpnHost"

    private val socketName = "sora-host-" + UUID.randomUUID()
    private val watchers = CopyOnWriteArrayList<LocalSocket>()

    @Volatile
    private var started = false

    fun name() = socketName

    @Synchronized
    fun start(context: Context) {
        if (started) return
        started = true
        val app = context.applicationContext
        val server = LocalServerSocket(socketName)
        thread(name = "sora-host", isDaemon = true) {
            while (true) {
                val peer = try {
                    server.accept()
                } catch (error: IOException) {
                    Log.e(TAG, "the host socket failed", error)
                    return@thread
                }
                thread(name = "sora-host-peer", isDaemon = true) { serve(app, peer) }
            }
        }
    }

    /** Tells the core something happened outside it. */
    fun publish(event: String) {
        val line = (JSONObject().put("event", event).toString() + "\n").toByteArray()
        for (watcher in watchers) {
            try {
                watcher.outputStream.write(line)
                watcher.outputStream.flush()
            } catch (_: IOException) {
                watchers.remove(watcher)
            }
        }
    }

    private fun serve(context: Context, peer: LocalSocket) {
        var keep = false
        try {
            if (peer.peerCredentials.uid != CoreProcess.myUid) {
                Log.w(TAG, "refused a peer of another user")
                return
            }
            val line = peer.inputStream.bufferedReader().readLine() ?: return
            val request = JSONObject(line)
            when (request.getString("op")) {
                "open" -> open(context, peer, request)
                "release" -> SoraVpnService.current?.release()
                "watch" -> {
                    watchers.add(peer)
                    keep = true
                }
            }
        } catch (error: Exception) {
            Log.e(TAG, "a core request failed", error)
            answerError(peer, error.message ?: "the request failed")
        } finally {
            if (!keep) runCatching { peer.close() }
        }
    }

    private fun open(context: Context, peer: LocalSocket, request: JSONObject) {
        val service = SoraVpnService.await(context) ?: error("the VPN service did not start")
        val adapter = service.open(TunRequest.from(request))
        adapter.use {
            peer.setFileDescriptorsForSend(arrayOf(it.fileDescriptor))
            peer.outputStream.write("{}\n".toByteArray())
            peer.outputStream.flush()
            // The descriptor must reach the peer before this copy closes.
            peer.inputStream.read()
        }
    }

    private fun answerError(peer: LocalSocket, message: String) {
        runCatching {
            peer.outputStream.write((JSONObject().put("error", message).toString() + "\n").toByteArray())
            peer.outputStream.flush()
        }
    }
}
