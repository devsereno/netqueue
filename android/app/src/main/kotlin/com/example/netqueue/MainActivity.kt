package com.example.netqueue

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.netqueue/vpn"
    private val VPN_REQUEST_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                "startVpn" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val intent = Intent(this, NetQueueVpnService::class.java).apply {
                        action = NetQueueVpnService.ACTION_START
                        putStringArrayListExtra(NetQueueVpnService.EXTRA_ALLOWED_APPS, ArrayList(packages))
                    }
                    startService(intent)
                    result.success(true)
                }
                "stopVpn" -> {
                    val intent = Intent(this, NetQueueVpnService::class.java).apply {
                        action = NetQueueVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
