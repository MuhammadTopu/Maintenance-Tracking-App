import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  SharedPrefService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception("SharedPrefService not initialized");
    }
    return _prefs!;
  }

  // =========================
  // 🔹 STRING
  // =========================

  static Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
  }

  static String? getString(String key) {
    return _instance.getString(key);
  }

  // =========================
  // 🔹 BOOL
  // =========================

  static Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  // =========================
  // 🔹 INT
  // =========================

  static Future<void> setInt(String key, int value) async {
    await _instance.setInt(key, value);
  }

  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  // =========================
  // 🔹 REMOVE / CLEAR
  // =========================

  static Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  static Future<void> clear() async {
    await _instance.clear();
  }
}