import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';
import 'profile.dart';
import 'groups.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String?>> _checkLogin() async {
    const storage = FlutterSecureStorage();
    String? username = await storage.read(key: 'username');
    String? token = await storage.read(key: 'token');

    if (username != null && token != null) {
      return {"username": username, "token": token};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<Map<String, String?>>(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return GroupsPage(
              username: snapshot.data?['username'] ?? "",
              token: snapshot.data?['token'] ?? "",
            );
          }
          return LoginPage();
        },
      ),
    );
  }
}