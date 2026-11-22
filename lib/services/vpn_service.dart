import 'package:flutter/services.dart';

class VpnController {
  static const _channel = MethodChannel('com.example.netqueue/vpn');

  static Future<bool> prepare() async {
    final result = await _channel.invokeMethod<bool>('prepareVpn');
    return result ?? false;
  }

  static Future<void> start(List<String> allowedPackages) async {
    await _channel.invokeMethod('startVpn', {'packages': allowedPackages});
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopVpn');
  }
}
