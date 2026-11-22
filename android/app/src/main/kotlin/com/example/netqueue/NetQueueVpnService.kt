package com.example.netqueue

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import kotlin.concurrent.thread
import androidx.core.app.NotificationCompat

class NetQueueVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    @Volatile private var generation = 0

    companion object {
        const val ACTION_START = "com.example.netqueue.START_VPN"
        const val ACTION_STOP = "com.example.netqueue.STOP_VPN"
        const val EXTRA_ALLOWED_APPS = "allowed_apps"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "netqueue_vpn"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val allowed = intent.getStringArrayListExtra(EXTRA_ALLOWED_APPS) ?: emptyList()
                if (FluxPolicy.allowed(this)) startVpn(allowed) else { stopVpn(); stopSelf() }
            }
            ACTION_STOP -> {
                stopVpn()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startVpn(allowedPackages: List<String>) {
        // A cada app, reconfigurar a VPN: o selecionado sai do túnel.

        createNotificationChannel()

        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        val builder = Builder()
            .setSession("NetQueue")
            .addAddress("10.222.0.1", 30)
            .addAddress("fd42:2222::1", 126)
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)
            .addDnsServer("8.8.8.8")
            .setBlocking(true)

        for (pkg in allowedPackages) {
            try {
                builder.addDisallowedApplication(pkg)
            } catch (_: Exception) {}
        }
        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: Exception) {}

        val newTun = try {
            builder.establish()
        } catch (e: Exception) {
            android.util.Log.e("FluxNetVPN", "Falha ao criar VPN", e)
            stopVpn()
            stopSelf()
            return
        } ?: run {
            stopVpn()
            stopSelf()
            return
        }
        val previous = vpnInterface
        vpnInterface = newTun
        val current = ++generation
        previous?.close()
        // O túnel é um sumidouro: os apps NÃO selecionados ficam sem rede.
        // O selecionado usa a conexão Android diretamente, fora da VPN.
        thread(name = "FluxNetDrop-$current", isDaemon = true) {
            try {
                FileInputStream(newTun.fileDescriptor).use { input ->
                    val buffer = ByteArray(32767)
                    while (generation == current && input.read(buffer) >= 0) { /* descartar */ }
                }
            } catch (_: Exception) { /* troca ou encerramento */ }
        }
    }

    private fun stopVpn() {
        generation++
        vpnInterface?.close()
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "NetQueue VPN",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NetQueue controlando rede")
            .setContentText("Liberando apps na fila")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }

    override fun onRevoke() {
        stopVpn()
        stopSelf()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
