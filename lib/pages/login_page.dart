import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/storage.dart';
import 'main_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;

  void login() async {
    setState(() => loading = true);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final res = await ApiService.login(username, password);
    setState(() => loading = false);

    if (res['success'] == true) {
      await Storage.saveToken(res['token']);
      await Storage.saveUsername(username);

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainPage()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OneChat Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          const SizedBox(height: 20),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: login, child: const Text("Login")),
          TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupPage()));
            },
            child: const Text("Don't have an account? Signup"),
          )
        ]),
      ),
    );
  }
}
