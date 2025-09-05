import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'music_library.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.adhimusic.channel.audio',
    androidNotificationChannelName: 'AdhiMusic',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdhiMusic',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MusicLibraryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
