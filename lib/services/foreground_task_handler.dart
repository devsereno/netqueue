import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NetQueueTaskHandler());
}

class NetQueueTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await ConnectivityService.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    final saved = prefs.getString('last_offline_time');
    DateTime? offlineTime = saved != null ? DateTime.tryParse(saved) : null;

    if (!hasConnection) {
      if (offlineTime == null) {
        final now = DateTime.now();
        await prefs.setString('last_offline_time', now.toIso8601String());
        ConnectivityService.lastOfflineTime = now;
      }
    } else {
      if (offlineTime != null) {
        final required = ConnectivityService.requiredOfflineDuration;
        final elapsed = DateTime.now().difference(offlineTime);
        if (elapsed >= required && ConnectivityService.autoControlEnabled) {
          FlutterForegroundTask.launchApp();
        }
      }
    }
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
