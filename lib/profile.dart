import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  final String token;

  const ProfilePage({super.key, required this.username, required this.token});

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Username: $username", style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text("Token: $token", style: TextStyle(fontSize: 14)),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () => _logout(context), child: Text("Logout")),
        ]),
      ),
    );
  }
}