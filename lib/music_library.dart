import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import 'music_player.dart';

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _songs = [];
  int _currentIndex = -1;

  Future<void> pickSongs() async {
    bool granted = false;

    if (Platform.isAndroid) {
      // ✅ Correct permissions per Android version
      if (await Permission.audio.request().isGranted) {
        granted = true;
      } else if (await Permission.storage.request().isGranted) {
        granted = true; // For Android 12 and below
      }
    } else {
      // iOS or desktop → no special permission needed
      granted = true;
    }

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied")),
        );
      }
      return;
    }

    // Pick multiple audio files
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _songs = result.paths.whereType<String>().toList();
        _currentIndex = -1; // Reset selection
      });
    }
  }

  void openPlayer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          audioPlayer: _audioPlayer,
          songs: _songs,
          currentIndex: index,
        ),
      ),
    ).then((value) {
      // Update UI when returning from player
      setState(() {
        _currentIndex = index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AdhiMusic"),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: "Pick Songs",
            onPressed: pickSongs,
          ),
        ],
      ),
      body: _songs.isEmpty
          ? const Center(child: Text("No songs loaded. Tap + to pick files."))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final name = _songs[index].split('/').last;
                return ListTile(
                  title: Text(name),
                  leading: Icon(
                    index == _currentIndex
                        ? Icons.play_arrow
                        : Icons.music_note,
                    color: index == _currentIndex
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onTap: () => openPlayer(index),
                );
              },
            ),
    );
  }
}
