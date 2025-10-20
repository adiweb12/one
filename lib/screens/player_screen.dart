import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:watsee_flutter/models/video_model.dart';

class PlayerScreen extends StatefulWidget {
  final VideoModel video;
  PlayerScreen({required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _vController;
  ChewieController? _chewieController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _vController = VideoPlayerController.network(widget.video.videoUrl);
      await _vController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _vController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );
    } catch (e) {
      print('Player init error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _vController?.dispose();
    super.dispose();
  }

  Widget _gradientTop() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFff6a00), Color(0xFFee0979), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(top: 36, left: 16, right: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(widget.video.title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, color: Colors.white))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        _gradientTop(),
        Expanded(
          child: Center(
            child: _loading
                ? CircularProgressIndicator()
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : Text('Unable to play this video'),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(widget.video.description, style: TextStyle(fontSize: 14)),
        )
      ]),
    );
  }
}