package com.example.netqueue

import android.content.Intent
import android.app.Activity
import android.os.Build
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.netqueue/vpn"
    private val VPN_REQUEST_CODE = 100
    private var pendingPermission: MethodChannel.Result? = null

    @Deprecated("Android activity result compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            pendingPermission?.success(resultCode == Activity.RESULT_OK)
            pendingPermission = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        pendingPermission = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        result.success(true)
                    }
                }
                "isCharging" -> {
                    val battery = registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val state = battery?.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1) ?: -1
                    result.success(state == android.os.BatteryManager.BATTERY_STATUS_CHARGING || state == android.os.BatteryManager.BATTERY_STATUS_FULL)
                }
                "batteryLevel" -> result.success(FluxPolicy.battery(this))
                "canRun" -> result.success(FluxPolicy.allowed(this))
                "scheduleRecovery" -> { FluxPolicy.schedule(this); result.success(true) }
                "startVpn" -> {
                    if (!FluxPolicy.allowed(this)) { result.error("POLICY_STOP", "FluxNet paused by user or low battery", null); return@setMethodCallHandler }
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val intent = Intent(this, NetQueueVpnService::class.java).apply {
                        action = NetQueueVpnService.ACTION_START
                        putStringArrayListExtra(NetQueueVpnService.EXTRA_ALLOWED_APPS, ArrayList(packages))
                    }
                    if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
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
