import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/settings_model.dart';

class SettingsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _settingsKey = 'app_settings';

  Future<AppSettings> getSettings() async {
    try {
      final String? data = await _storage.read(key: _settingsKey);
      if (data == null) return AppSettings.defaults;
      return AppSettings.fromJson(jsonDecode(data));
    } catch (e) {
      return AppSettings.defaults;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _storage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
  }
}
