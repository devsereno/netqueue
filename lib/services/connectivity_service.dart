import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static late SharedPreferences _prefs;
  static DateTime? lastOfflineTime;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static const String _offlineKey = 'last_offline_time';
  static const int defaultOfflineHours = 2;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getString(_offlineKey);
    if (saved != null) {
      lastOfflineTime = DateTime.tryParse(saved);
    }
    _startListening();
  }

  static void _startListening() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        lastOfflineTime = DateTime.now();
        _prefs.setString(_offlineKey, lastOfflineTime!.toIso8601String());
      }
    });
  }

  static Future<bool> shouldActivateControl() async {
    if (lastOfflineTime == null) return false;
    final hours = _prefs.getInt('offline_hours') ?? defaultOfflineHours;
    final threshold = Duration(hours: hours);
    return DateTime.now().difference(lastOfflineTime!) >= threshold;
  }

  static Future<void> markOnlineHandled() async {
    lastOfflineTime = null;
    await _prefs.remove(_offlineKey);
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
