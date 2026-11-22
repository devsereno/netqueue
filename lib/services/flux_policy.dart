import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'vpn_service.dart';

class FluxPolicy {
  static const channel = MethodChannel('com.example.netqueue/vpn');
  static Future<bool> canRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('flux_manual_stop') ?? false) return false;
    try { return await channel.invokeMethod<bool>('canRun') ?? false; }
    catch (_) { return false; }
  }
  static Future<bool> isCharging() async {
    try { return await channel.invokeMethod<bool>('isCharging') ?? false; }
    catch (_) { return false; }
  }
  static Future<int> battery() async {
    try { return await channel.invokeMethod<int>('batteryLevel') ?? -1; }
    catch (_) { return -1; }
  }
  static Future<void> schedule() async {
    try { await channel.invokeMethod('scheduleRecovery'); } catch (_) {}
  }
  static Future<void> stopAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flux_manual_stop', true);
    await VpnController.stop();
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
    await schedule();
  }
  static Future<void> resume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flux_manual_stop', false);
    await schedule();
  }
  static Future<void> event(String type, [Map<String, dynamic> extra = const {}]) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> events;
    try { events = jsonDecode(prefs.getString('flux_events') ?? '[]') as List<dynamic>; }
    catch (_) { events = []; }
    events.insert(0, {'type': type, 'at': DateTime.now().toIso8601String(), ...extra});
    if (events.length > 120) events = events.take(120).toList();
    await prefs.setString('flux_events', jsonEncode(events));
  }
}
