import 'dart:convert';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppListService {
  static const _key = 'cached_app_list';
  static const _historyKey = 'queue_history';

  static Future<List<Map<String, String>>> getCachedOrLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (_) {}
    }
    return await refresh();
  }

  static Future<List<Map<String, String>>> refresh() async {
    final apps = await FlutterDeviceApps.listApps(
      includeSystem: false,
      onlyLaunchable: true,
      includeIcons: false,
    );
    final simple = apps
        .where((a) => a.packageName != null && a.appName != null)
        .map((a) => {
              'package': a.packageName!,
              'name': a.appName!,
            })
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(simple));
    return simple;
  }

  static Future<void> addToHistory(String name, String package) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    list.insert(0, {
      'name': name,
      'package': package,
      'time': DateTime.now().toIso8601String(),
    });
    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setString(_historyKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }
}
