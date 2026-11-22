import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'screens/home_screen.dart';
import 'services/connectivity_service.dart';
import 'services/foreground_task_handler.dart';
import 'services/flux_policy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(FluxPolicy.event('flutter_error', {'message': details.exceptionAsString().substring(0, details.exceptionAsString().length.clamp(0, 250))}));
  };
  FlutterForegroundTask.initCommunicationPort();
  await ConnectivityService.init();
  await FluxPolicy.schedule();
  if (await FluxPolicy.canRun()) await initForegroundService();
  runApp(const NetQueueApp());
}

Future<void> initForegroundService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'netqueue_monitor',
      channelName: 'NetQueue Monitor',
      channelDescription: 'Monitoramento de conexão e fila de apps',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(30000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: false,
      allowWifiLock: false,
    ),
  );

  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.restartService();
  } else {
    await FlutterForegroundTask.startService(
      notificationTitle: 'NetQueue ativo',
      notificationText: 'Monitorando conexão em segundo plano',
      callback: startCallback,
    );
  }
}

class NetQueueApp extends StatelessWidget {
  const NetQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetQueue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
