import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';

import 'music_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init audio background
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
      debugShowCheckedModeBanner: false,
      home: const PermissionGate(),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Android 13+ requires READ_MEDIA_AUDIO instead of READ_EXTERNAL_STORAGE
    final storage = await Permission.storage.request();
    final audio = await Permission.audio.request();

    if (storage.isGranted || audio.isGranted) {
      setState(() => _granted = true);
    } else {
      // Ask again if denied
      if (storage.isDenied || audio.isDenied) {
        await _checkPermissions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) {
      return const MusicLibraryPage();
    } else {
      return const Scaffold(
        body: Center(
          child: Text(
            "Waiting for permissions...",
            style: TextStyle(fontSize: 18, color: Colors.deepPurple),
          ),
        ),
      );
    }
  }
}
