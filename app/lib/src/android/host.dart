import 'package:flutter/services.dart';

/// The Android side of the app: the VPN consent, the service that holds the
/// adapter, and system settings Flutter cannot reach.
abstract final class AndroidHost {
  static const _channel = MethodChannel('sora/android');

  static String socketPath = '';

  /// The app's private directory.
  static String filesDir = '';

  /// Reads what the app needs before it talks to the core.
  static Future<void> init() async {
    socketPath = await _channel.invokeMethod<String>('socketPath') ?? '';
    filesDir = await _channel.invokeMethod<String>('filesDir') ?? '';
  }

  /// Asks for the system's VPN permission when it is missing.
  static Future<bool> prepareVpn() async => await _channel.invokeMethod<bool>('prepareVpn') ?? false;

  /// Starts the service that will hold the adapter.
  static Future<bool> startVpn() async => await _channel.invokeMethod<bool>('startVpn') ?? false;

  /// What the notification of the running VPN says.
  static Future<void> setStatus(String status) => _channel.invokeMethod<void>('setStatus', status);

  static Future<void> openVpnSettings() => _channel.invokeMethod<void>('openVpnSettings');

  /// Whether the system keeps this VPN on and blocks traffic without it.
  static Future<({bool on, bool lockdown})> alwaysOn() async {
    final answer = await _channel.invokeMapMethod<String, bool>('alwaysOn');
    return (on: answer?['on'] ?? false, lockdown: answer?['lockdown'] ?? false);
  }

  static Future<bool> batteryUnrestricted() async =>
      await _channel.invokeMethod<bool>('batteryUnrestricted') ?? true;

  static Future<void> askBatteryUnrestricted() => _channel.invokeMethod<void>('askBatteryUnrestricted');

  /// The host of a strict Private DNS, which sends lookups past the VPN.
  static Future<String?> privateDnsHost() => _channel.invokeMethod<String>('privateDnsHost');
}
