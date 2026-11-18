import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
    final should = await ConnectivityService.shouldActivateControl();
    if (should && ConnectivityService.autoControlEnabled) {
      // Tenta trazer o app para a frente
      FlutterForegroundTask.launchApp();
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
