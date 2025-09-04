import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    setState(() => _loading = true);
    var url = Uri.parse("https://test-4udw.onrender.com/signup");
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim()
        }));

    setState(() => _loading = false);
    if (response.statusCode == 200) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _usernameController, decoration: InputDecoration(labelText: "Username")),
          SizedBox(height: 10),
          TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password")),
          SizedBox(height: 20),
          _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _signup, child: Text("Signup")),
        ]),
      ),
    );
  }
}