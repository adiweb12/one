import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart'; // 👈 add this
import 'music_player.dart';

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _songs = [];
  int _currentIndex = 0;

  Future<void> pickSongs() async {
    // 👇 Check permission before opening FilePicker
    if (await Permission.storage.request().isGranted) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _songs = result.paths.whereType<String>().toList();
        });
      }
    } else {
      // Show a simple message if denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
      }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AdhiMusic"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: pickSongs,
          ),
        ],
      ),
      body: _songs.isEmpty
          ? const Center(child: Text("No songs loaded"))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final name = _songs[index].split('/').last;
                return ListTile(
                  title: Text(name),
                  leading: index == _currentIndex
                      ? const Icon(Icons.play_arrow, color: Colors.orange)
                      : const Icon(Icons.music_note),
                  onTap: () => openPlayer(index),
                );
              },
            ),
    );
  }
}
