import 'package:flutter/material.dart';
import 'package:watsee_flutter/screens/signup_screen.dart';
import 'package:watsee_flutter/screens/home_screen.dart';
import 'package:watsee_flutter/services/api.dart';
import 'package:watsee_flutter/services/auth_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  void _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.login(_email.text.trim(), _password.text.trim());
      if (res.containsKey('access_token')) {
        await AuthService.setToken(res['access_token']);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else if (res.containsKey('error')) {
        setState(() { _error = res['error'].toString(); });
      } else {
        setState(() { _error = 'Unexpected response from server'; });
      }
    } catch (e) {
      setState(() { _error = 'Login failed: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Widget _buildGradientHeader() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFff6a00), Color(0xFFee0979), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Center(
        child: Text('Watsee', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGradientHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
              child: Column(
                children: [
                  TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
                  SizedBox(height: 12),
                  TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
                  SizedBox(height: 20),
                  if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 12),
                  _loading
                      ? SpinKitFadingCircle(size: 36.0)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 6,
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: _submit,
                          child: Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupScreen())),
                    child: Text('Don\'t have an account? Sign up'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}