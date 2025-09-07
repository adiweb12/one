import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  _SongListScreenState createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  void _checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _querySongs();
    } else {
      setState(() {
        _hasPermission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to view your music library.')),
      );
    }
  }

  void _querySongs() async {
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Center(
        child: Text(
          "Storage permission denied.\nPlease enable it in settings to access your music.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text(
          "No songs found on your device.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF333333),
          ],
        ),
      ),
      child: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            leading: const Icon(Icons.music_note, color: Colors.white70),
            title: Text(
              song.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist ?? "Unknown Artist",
              style: const TextStyle(color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
            onTap: () {
              // TODO: Implement playback logic here.
              // Example:
              // final player = AudioPlayer();
              // player.play(DeviceFileSource(song.data));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing: ${song.title}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
