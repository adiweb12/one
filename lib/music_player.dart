import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<SongModel> songs;
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

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late int _currentIndex;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;

    _bgController =
        AnimationController(vsync: this, duration: Duration(seconds: 8))
          ..repeat(reverse: true);

    widget.audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });

    widget.audioPlayer.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    widget.audioPlayer.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });
  }

  Future<void> _playSong(int index) async {
    final song = widget.songs[index];
    await widget.audioPlayer.setSourceUrl(song.uri!);
    await widget.audioPlayer.resume();
    setState(() => _currentIndex = index);
    widget.onSongChanged(index);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.songs[_currentIndex];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(Color(0xFF6D83F2), Color(0xFFB86CF9),
                      _bgController.value)!,
                  Color.lerp(Color(0xFFB86CF9), Color(0xFF6D83F2),
                      _bgController.value)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),

              // Artwork with Hero
              Hero(
                tag: "artwork-${song.id}",
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkHeight: 250,
                  artworkWidth: 250,
                  artworkBorder: BorderRadius.circular(20),
                  nullArtworkWidget: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 100),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Song Title & Artist
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                song.artist ?? "Unknown Artist",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Progress Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
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

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 40),
                    onPressed: () {
                      if (_currentIndex > 0) {
                        _playSong(_currentIndex - 1);
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  AnimatedScale(
                    scale: _isPlaying ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        color: Colors.white,
                        size: 80,
                      ),
                      onPressed: () async {
                        if (_isPlaying) {
                          await widget.audioPlayer.pause();
                        } else {
                          await widget.audioPlayer.resume();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 40),
                    onPressed: () {
                      if (_currentIndex < widget.songs.length - 1) {
                        _playSong(_currentIndex + 1);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}