import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String keyEvents = 'cache_events';
  static const String keyParticipations = 'cache_participations';
  static const String keyContingents = 'cache_contingents';
  static const String keyDepartments = 'cache_departments';

  static Future<void> cacheData(String key, String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonData);
  }

  static Future<String?> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
