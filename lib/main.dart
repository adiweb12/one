import 'dart:math';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List songs;
  final int currentIndex;
  final Function(int) onSongChanged;

  const MusicPlayerPage({
    Key? key,
    required this.audioPlayer,
    required this.songs,
    required this.currentIndex,
    required this.onSongChanged,
  }) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late int _index;

  bool _isRepeatAll = false;
  bool _isShuffle = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex;

    widget.audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    widget.audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });
    widget.audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    // 🔥 Auto play next when song ends
    widget.audioPlayer.onPlayerComplete.listen((event) {
      if (_isShuffle) {
        _playSong(_random.nextInt(widget.songs.length));
      } else if (_index < widget.songs.length - 1) {
        _playSong(_index + 1);
      } else if (_isRepeatAll) {
        _playSong(0); // restart playlist
      } else {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _playSong(int newIndex) async {
    final song = widget.songs[newIndex];
    setState(() => _index = newIndex);

    await widget.audioPlayer.setSourceUrl(song.uri!);
    await widget.audioPlayer.resume();

    widget.onSongChanged(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.songs[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D83F2), Color(0xFFB86CF9)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkHeight: 220,
              artworkWidth: 220,
              nullArtworkWidget: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.music_note,
                    color: Colors.white, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(song.artist ?? "Unknown Artist",
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 30),

            // Progress bar
            Slider(
              activeColor: Colors.orangeAccent,
              inactiveColor: Colors.white38,
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds
                  .toDouble()
                  .clamp(0, _duration.inSeconds.toDouble()),
              onChanged: (value) async {
                final newPos = Duration(seconds: value.toInt());
                await widget.audioPlayer.seek(newPos);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position),
                      style: const TextStyle(color: Colors.white70)),
                  Text(_formatDuration(_duration),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Controls row with Shuffle + Repeat
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔀 Shuffle button
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: _isShuffle ? Colors.orange : Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() => _isShuffle = !_isShuffle);
                  },
                ),
                const SizedBox(width: 20),

                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white, size: 40),
                  onPressed:
                      _index > 0 ? () => _playSong(_index - 1) : null,
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white,
                    size: 64,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await widget.audioPlayer.pause();
                    } else {
                      await widget.audioPlayer.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 40),
                  onPressed: _index < widget.songs.length - 1
                      ? () => _playSong(_index + 1)
                      : null,
                ),

                const SizedBox(width: 20),
                // 🔁 Repeat All button
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: _isRepeatAll ? Colors.orange : Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() => _isRepeatAll = !_isRepeatAll);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}