package com.example.netqueue

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat

class NetQueueVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

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
                startVpn(allowed)
            }
            ACTION_STOP -> {
                stopVpn()
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startVpn(allowedPackages: List<String>) {
        if (vpnInterface != null) return

        createNotificationChannel()

        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_VPN
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        val builder = Builder()
            .setSession("NetQueue")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .setBlocking(false)

        for (pkg in allowedPackages) {
            try {
                builder.addAllowedApplication(pkg)
            } catch (_: Exception) {}
        }
        try {
            builder.addAllowedApplication(packageName)
        } catch (_: Exception) {}

        vpnInterface = builder.establish()
    }

    private fun stopVpn() {
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

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
