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

  static final _autoTriggerController = StreamController<void>.broadcast();
  static Stream<void> get onAutoTrigger => _autoTriggerController.stream;

  static const String _offlineKey = 'last_offline_time';
  static const String _testActiveKey = 'test_mode_active';
  static const String _testMinutesKey = 'test_minutes';
  static const String _autoEnabledKey = 'auto_control_enabled';
  static const int defaultOfflineHours = 2;

  static bool autoControlEnabled = true;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await reloadFromPrefs();
    autoControlEnabled = _prefs.getBool(_autoEnabledKey) ?? true;
    _startListening();
  }

  static Future<void> reloadFromPrefs() async {
    final saved = _prefs.getString(_offlineKey);
    if (saved != null) {
      lastOfflineTime = DateTime.tryParse(saved);
    } else {
      lastOfflineTime = null;
    }
  }

  static void _startListening() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        if (lastOfflineTime == null) {
          lastOfflineTime = DateTime.now();
          await _prefs.setString(_offlineKey, lastOfflineTime!.toIso8601String());
        }
      } else {
        if (autoControlEnabled && await shouldActivateControl()) {
          _autoTriggerController.add(null);
        }
      }
    });
  }

  static bool get isTestModeActive => _prefs.getBool(_testActiveKey) ?? false;

  static int get testMinutes => _prefs.getInt(_testMinutesKey) ?? 10;

  static Future<void> startTestMode(int minutes) async {
    await _prefs.setBool(_testActiveKey, true);
    await _prefs.setInt(_testMinutesKey, minutes);
  }

  static Future<void> cancelTestMode() async {
    await _prefs.setBool(_testActiveKey, false);
    await _prefs.remove(_testMinutesKey);
  }

  static Future<void> setAutoControlEnabled(bool enabled) async {
    autoControlEnabled = enabled;
    await _prefs.setBool(_autoEnabledKey, enabled);
  }

  static Future<bool> shouldActivateControl() async {
    await reloadFromPrefs();
    if (lastOfflineTime == null) return false;

    if (isTestModeActive) {
      final threshold = Duration(minutes: testMinutes);
      return DateTime.now().difference(lastOfflineTime!) >= threshold;
    }

    final hours = _prefs.getInt('offline_hours') ?? defaultOfflineHours;
    final threshold = Duration(hours: hours);
    return DateTime.now().difference(lastOfflineTime!) >= threshold;
  }

  static Duration get requiredOfflineDuration {
    if (isTestModeActive) {
      return Duration(minutes: testMinutes);
    }
    final hours = _prefs.getInt('offline_hours') ?? defaultOfflineHours;
    return Duration(hours: hours);
  }

  static Duration get currentOfflineDuration {
    if (lastOfflineTime == null) return Duration.zero;
    return DateTime.now().difference(lastOfflineTime!);
  }

  static Future<void> markOnlineHandled() async {
    lastOfflineTime = null;
    await _prefs.remove(_offlineKey);
    if (isTestModeActive) {
      await cancelTestMode();
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _autoTriggerController.close();
  }
}
