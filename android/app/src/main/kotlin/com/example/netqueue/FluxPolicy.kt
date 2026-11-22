package com.example.netqueue

import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

object FluxPolicy {
    private const val PREFS = "FlutterSharedPreferences"
    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    fun isManualStop(c: Context) = prefs(c).getBoolean("flutter.flux_manual_stop", false)
    fun battery(c: Context): Int {
        val manager = c.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }
    fun allowed(c: Context): Boolean {
        if (isManualStop(c)) return false
        val b = battery(c)
        val stopped = prefs(c).getBoolean("flutter.flux_battery_stop", false)
        if (b in 0..5) {
            prefs(c).edit().putBoolean("flutter.flux_battery_stop", true).apply()
            return false
        }
        if (stopped && b < 15) return false
        if (stopped && b >= 15) prefs(c).edit().putBoolean("flutter.flux_battery_stop", false).apply()
        return true
    }
    fun schedule(c: Context) {
        if (isManualStop(c)) { WorkManager.getInstance(c).cancelUniqueWork("flux_recovery"); return }
        val req = PeriodicWorkRequestBuilder<FluxRecoveryWorker>(30, TimeUnit.MINUTES).build()
        WorkManager.getInstance(c).enqueueUniquePeriodicWork("flux_recovery", ExistingPeriodicWorkPolicy.KEEP, req)
    }
    fun stopVpn(c: Context) {
        try { c.startService(Intent(c, NetQueueVpnService::class.java).setAction(NetQueueVpnService.ACTION_STOP)) }
        catch (_: Exception) { /* Service may already be stopped */ }
    }
}

class FluxRecoveryWorker(context: Context, params: WorkerParameters): Worker(context, params) {
    override fun doWork(): Result {
        val c = applicationContext
        if (!FluxPolicy.allowed(c)) { FluxPolicy.stopVpn(c); return Result.success() }
        // Recovery is best effort: Android 12+ may forbid starting foreground services here.
        // The Flutter foreground-task plugin manages its own boot/restart receiver.
        return Result.success()
    }
}

class FluxBootReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            if (FluxPolicy.allowed(context)) FluxPolicy.schedule(context)
        }
    }
}
