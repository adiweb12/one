import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'music_library.dart';

Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    // Android 13+ (API 33) needs new permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }

    // Storage/audio for older Android
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.adhimusic.channel.audio',
    androidNotificationChannelName: 'AdhiMusic',
    androidNotificationOngoing: true,
  );

  // Ask runtime permissions
  await requestPermissions();

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
