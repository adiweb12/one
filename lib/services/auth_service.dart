import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static SharedPreferences? _prefs;
  static const String _tokenKey = 'watsee_token';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get token => _prefs?.getString(_tokenKey);
  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> setToken(String tok) async {
    await _prefs?.setString(_tokenKey, tok);
  }

  static Future<void> clear() async {
    await _prefs?.remove(_tokenKey);
  }
}