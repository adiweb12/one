import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watsee_flutter/services/auth_service.dart';
import 'package:watsee_flutter/models/video_model.dart';

class Api {
  // use http://127.0.0.1:5000 for emulator: if using Android emulator use 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:5000';

  static Map<String, String> _headers({bool auth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && AuthService.token != null) {
      headers['Authorization'] = 'Bearer ${AuthService.token}';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String path, Map body, {bool auth = false}) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers(auth: auth), body: jsonEncode(body));
    return jsonDecode(res.body);
  }

  static Future<List<VideoModel>> fetchVideos() async {
    final res = await http.get(Uri.parse('$baseUrl/videos'), headers: _headers());
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => VideoModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch videos (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return post('/login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    return post('/signup', {'username': username, 'email': email, 'password': password});
  }
}