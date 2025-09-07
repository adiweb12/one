import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<String> songs;
  final int currentIndex;

  const MusicPlayerPage({
    super.key,
    required this.audioPlayer,
    required this.songs,
    required this.currentIndex,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _playSong(_currentIndex);

    widget.audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _handleNext();
      }
    });
  }

  Future<void> _playSong(int index) async {
    await widget.audioPlayer.setFilePath(widget.songs[index]);
    await widget.audioPlayer.play();
    setState(() => _currentIndex = index);
  }

  void _handleNext() {
    if (_isShuffle) {
      _playSong(_random.nextInt(widget.songs.length));
    } else if (_currentIndex < widget.songs.length - 1) {
      _playSong(_currentIndex + 1);
    } else if (_isRepeat) {
      _playSong(0);
    } else {
      widget.audioPlayer.stop();
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      _playSong(_currentIndex - 1);
    } else if (_isRepeat) {
      _playSong(widget.songs.length - 1);
    }
  }

  @override
  void dispose() {
    widget.audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songName = widget.songs[_currentIndex].split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(songName, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Song title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                songName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Seek bar
            StreamBuilder<Duration>(
              stream: widget.audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration =
                    widget.audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                      max: duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        widget.audioPlayer
                            .seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: _isShuffle ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isShuffle = !_isShuffle),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 40),
                  onPressed: _handlePrevious,
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      widget.audioPlayer.pause();
                    } else {
                      widget.audioPlayer.play();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 40),
                  onPressed: _handleNext,
                ),
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: _isRepeat ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isRepeat = !_isRepeat),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
