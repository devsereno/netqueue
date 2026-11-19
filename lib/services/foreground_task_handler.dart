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

    if (!hasConnection) {
      // Sem internet: garante que o tempo offline está sendo contado
      if (ConnectivityService.lastOfflineTime == null) {
        final now = DateTime.now();
        ConnectivityService.lastOfflineTime = now;
        await prefs.setString('last_offline_time', now.toIso8601String());
      }
    } else {
      // Internet voltou: verifica se o tempo mínimo foi atingido
      final should = await ConnectivityService.shouldActivateControl();
      if (should && ConnectivityService.autoControlEnabled) {
        FlutterForegroundTask.launchApp();
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
