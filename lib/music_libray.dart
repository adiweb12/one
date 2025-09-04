import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_player.dart';

class MusicLibraryPage extends StatefulWidget {
  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _songs = [];
  SongModel? _currentSong;
  int _currentIndex = -1;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchSongs();

    _audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  Future<void> _fetchSongs() async {
    var songs = await _audioQuery.querySongs(
      sortType: SongSortType.DISPLAY_NAME,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    setState(() => _songs = songs);
  }

  Future<void> _playSong(int index) async {
    final song = _songs[index];
    setState(() {
      _currentSong = song;
      _currentIndex = index;
    });

    await _audioPlayer.setSourceUrl(song.uri!);
    await _audioPlayer.resume();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(
          audioPlayer: _audioPlayer,
          songs: _songs,
          currentIndex: _currentIndex,
          onSongChanged: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
              _currentSong = _songs[newIndex];
            });
          },
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (_currentSong == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayerPage(
              audioPlayer: _audioPlayer,
              songs: _songs,
              currentIndex: _currentIndex,
              onSongChanged: (newIndex) {
                setState(() {
                  _currentIndex = newIndex;
                  _currentSong = _songs[newIndex];
                });
              },
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
            ),
            child: Row(
              children: [
                Hero(
                  tag: "artwork-${_currentSong!.id}",
                  child: QueryArtworkWidget(
                    id: _currentSong!.id,
                    type: ArtworkType.AUDIO,
                    artworkHeight: 50,
                    artworkWidth: 50,
                    nullArtworkWidget: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentSong!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                        _currentSong!.artist ?? "Unknown Artist",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: _isPlaying ? 1.1 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        await _audioPlayer.resume();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Music"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D83F2), Color(0xFFB86CF9)],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _songs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _songs.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: ListTile(
                        leading: const Icon(Icons.music_note,
                            color: Colors.deepPurple),
                        title: Text(song.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist ?? "Unknown Artist"),
                        onTap: () => _playSong(index),
                      ),
                    );
                  },
                ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildMiniPlayer()),
        ],
      ),
    );
  }
}