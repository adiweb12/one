import 'package:flutter/material.dart';
import 'package:music_player_app/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.deepPurpleAccent,
          background: Colors.black,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
