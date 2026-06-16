import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class PrefsService {
  static const _keyIp = 'server.ip';
  static const _keyPort = 'server.port';
  static const _keyApps = 'apps';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get savedIp => _prefs.getString(_keyIp) ?? '127.0.0.1';
  String get savedPort => _prefs.getString(_keyPort) ?? '5000';

  Future<void> saveIpPort(String ip, String port) async {
    await _prefs.setString(_keyIp, ip);
    await _prefs.setString(_keyPort, port);
  }

  Map<String, AppConfig> getAppConfigs() {
    final raw = _prefs.getString(_keyApps);
    if (raw == null) return AppConfig.defaults();
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((id, v) => MapEntry(id, AppConfig.fromJson(id, v as Map<String, dynamic>)));
    } catch (_) {
      return AppConfig.defaults();
    }
  }

  Future<void> saveAppConfigs(Map<String, AppConfig> configs) async {
    final encoded = json.encode(configs.map((k, v) => MapEntry(k, v.toJson())));
    await _prefs.setString(_keyApps, encoded);
  }
}
