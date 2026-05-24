import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/photo_frame_settings.dart';

class FrameSettingsStorage {
  const FrameSettingsStorage();

  static const _settingsKey = 'photo_frame.saved_settings';

  Future<void> save(PhotoFrameSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(settings.toMap()));
  }

  Future<PhotoFrameSettings?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return PhotoFrameSettings.fromMap(Map<String, Object?>.from(decoded));
  }
}
