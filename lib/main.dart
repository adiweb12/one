import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import 'profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData && snapshot.data != null) {
            return ProfilePage(
              username: snapshot.data!['username'],
              token: snapshot.data!['token'],
            );
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }

  Future<Map<String, String>?> _checkLogin() async {
    String? username = await storage.read(key: 'username');
    String? token = await storage.read(key: 'token');
    if (username != null && token != null) {
      return {"username": username, "token": token};
    }
    return null;
  }
}