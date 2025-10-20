import 'package:flutter/material.dart';
import 'package:watsee_flutter/screens/home_screen.dart';
import 'package:watsee_flutter/screens/login_screen.dart';
import 'package:watsee_flutter/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init(); // init shared preferences
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF00B4DB), Color(0xFF0083B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watsee',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: TextTheme(bodyText2: TextStyle(color: Colors.grey[900])),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthService.isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}