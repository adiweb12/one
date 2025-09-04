import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup.dart';
import 'groups.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    var url = Uri.parse("https://test-4udw.onrender.com/login");
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim()
        }));

    setState(() => _loading = false);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      const storage = FlutterSecureStorage();
      await storage.write(key: "username", value: data["username"]);
      await storage.write(key: "token", value: data["token"]);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GroupsPage(username: data["username"], token: data["token"]),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _usernameController, decoration: InputDecoration(labelText: "Username")),
          SizedBox(height: 10),
          TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password")),
          SizedBox(height: 20),
          _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: Text("Login")),
          TextButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage()));
          }, child: Text("Create an account"))
        ]),
      ),
    );
  }
}