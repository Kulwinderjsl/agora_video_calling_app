import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class LocalStorageService {
  static const String _usersKey = 'cached_users';
  static const String _lastFetchTimeKey = 'last_fetch_time';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  static Future<void> cacheUsers(List<User> users) async {
    await _ensureInitialized();

    final userJsonList = users.map((user) => user.toJson()).toList();
    await _prefs!.setString(_usersKey, jsonEncode(userJsonList));
    await _prefs!.setString(
      _lastFetchTimeKey,
      DateTime.now().toIso8601String(),
    );
  }

  static Future<List<User>> getCachedUsers() async {
    await _ensureInitialized();

    final usersJson = _prefs!.getString(_usersKey);
    if (usersJson == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(usersJson);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<DateTime?> getLastFetchTime() async {
    await _ensureInitialized();

    final timeString = _prefs!.getString(_lastFetchTimeKey);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  static Future<bool> isCacheValid({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final lastFetch = await getLastFetchTime();
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < maxAge;
  }

  static Future<void> clearCache() async {
    await _ensureInitialized();

    await _prefs!.remove(_usersKey);
    await _prefs!.remove(_lastFetchTimeKey);
  }
}
