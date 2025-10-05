import 'dart:convert';
import 'package:http/http.dart' as http;

// ⚠️ CHANGE TO YOUR DEPLOYED FLASK SERVER URL
const String SERVER_URL = "https://onechatjdifivifrrfigiufitxtd6xy.onrender.com";

class ApiService {
  // ----------- AUTH -----------
  static Future<Map<String, dynamic>> signup(
      String username, String password, String name) async {
    final res = await http.post(Uri.parse("$SERVER_URL/signup"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password, "name": name}));
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(Uri.parse("$SERVER_URL/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password}));
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> logout(String token) async {
    final res = await http.post(Uri.parse("$SERVER_URL/logout"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token}));
    return json.decode(res.body);
  }

  // ----------- PROFILE -----------
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.post(Uri.parse("$SERVER_URL/profile"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token}));
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile(String token, String newName) async {
    final res = await http.post(Uri.parse("$SERVER_URL/update_profile"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "newName": newName}));
    return json.decode(res.body);
  }

  // ----------- GROUPS -----------
  static Future<Map<String, dynamic>> createGroup(
      String token, String groupName, String groupNumber) async {
    final res = await http.post(Uri.parse("$SERVER_URL/create_group"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(
            {"token": token, "groupName": groupName, "groupNumber": groupNumber}));
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> joinGroup(String token, String groupNumber) async {
    final res = await http.post(Uri.parse("$SERVER_URL/join_group"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "groupNumber": groupNumber}));
    return json.decode(res.body);
  }

  // ----------- MESSAGES -----------
  static Future<Map<String, dynamic>> sendMessage(
      String token, String groupNumber, String message) async {
    final res = await http.post(Uri.parse("$SERVER_URL/send_message"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "groupNumber": groupNumber, "message": message}));
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> getMessages(String token, String groupNumber) async {
    final res = await http.post(Uri.parse("$SERVER_URL/get_messages/$groupNumber"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token}));
    return json.decode(res.body);
  }
}
