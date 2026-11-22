import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'flux_policy.dart';
import 'vpn_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NetQueueTaskHandler());
}

class NetQueueTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (!await FluxPolicy.canRun()) {
      await VpnController.stop();
      await FlutterForegroundTask.stopService();
      return;
    }
    await ConnectivityService.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (!await FluxPolicy.canRun()) {
      await VpnController.stop();
      await FlutterForegroundTask.stopService();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    final saved = prefs.getString('last_offline_time');
    DateTime? offlineTime = saved != null ? DateTime.tryParse(saved) : null;

    String notifText = 'Monitorando conexão...';

    if (!hasConnection) {
      if (offlineTime == null) {
        final now = DateTime.now();
        await prefs.setString('last_offline_time', now.toIso8601String());
        ConnectivityService.lastOfflineTime = now;
        offlineTime = now;
      }
      final elapsed = DateTime.now().difference(offlineTime!);
      final min = elapsed.inMinutes;
      final sec = elapsed.inSeconds.remainder(60);
      notifText = 'Offline: ${min}min ${sec}s';
    } else {
      if (offlineTime != null) {
        final required = ConnectivityService.requiredOfflineDuration;
        final elapsed = DateTime.now().difference(offlineTime);
        if (elapsed >= required && ConnectivityService.autoControlEnabled) {
          // Background activity launches are restricted by Android.
          // Keep the notification visible; the user can open the app explicitly.
          notifText = 'Condição atingida. Abra o app para iniciar a fila.';
        } else {
          await prefs.remove('last_offline_time');
          notifText = 'Online. Aguardando tempo offline.';
        }
      } else {
        notifText = 'Online. Monitorando...';
      }
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'NetQueue ativo',
      notificationText: notifText,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    ConnectivityService.dispose();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
