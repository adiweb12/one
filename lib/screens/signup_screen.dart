import 'package:flutter/material.dart';
import 'package:watsee_flutter/services/api.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  void _submit() async {
    setState(() { _loading = true; _error = null; _success = null;});
    try {
      final res = await Api.signup(_username.text.trim(), _email.text.trim(), _password.text.trim());
      if (res.containsKey('message') || res.containsKey('success')) {
        setState(() { _success = res['message'] ?? res['success'].toString(); });
      } else if (res.containsKey('error')) {
        setState(() { _error = res['error'].toString(); });
      } else {
        setState(() { _success = 'Registered — you can log in now.'; });
      }
    } catch (e) {
      setState(() { _error = 'Signup failed: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Widget _gradientHeader() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Center(child: Text('Create account', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          _gradientHeader(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
              SizedBox(height: 12),
              TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 12),
              TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              SizedBox(height: 16),
              if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
              if (_success != null) Text(_success!, style: TextStyle(color: Colors.green)),
              SizedBox(height: 12),
              _loading
                  ? SpinKitFadingCircle(size: 36)
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: Text('Sign up'),
                    ),
            ]),
          )
        ]),
      ),
    );
  }
}