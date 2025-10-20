import 'package:flutter/material.dart';
import 'package:watsee_flutter/services/api.dart';
import 'package:watsee_flutter/models/video_model.dart';
import 'package:watsee_flutter/screens/player_screen.dart';
import 'package:watsee_flutter/services/auth_service.dart';
import 'package:watsee_flutter/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<VideoModel>> _futureVideos;

  @override
  void initState() {
    super.initState();
    _futureVideos = Api.fetchVideos();
  }

  void _logout() async {
    await AuthService.clear();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  Widget _buildGradientAppBar() {
    return Container(
      height: 110,
      padding: EdgeInsets.only(top: 36, left: 18, right: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF00B4DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Watsee', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12), elevation: 0),
            onPressed: _logout,
          )
        ],
      ),
    );
  }

  Widget _videoCard(VideoModel v) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(video: v))),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [Colors.white, Colors.white]),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
            child: Image.network(v.thumbnailUrl, width: 140, height: 160, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(width:140,color:Colors.grey[300],child: Icon(Icons.broken_image))),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(v.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(v.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Align(alignment: Alignment.bottomRight, child: Icon(Icons.play_circle_fill, size: 36, color: Colors.deepPurple))
              ]),
            ),
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        _buildGradientAppBar(),
        Expanded(
          child: FutureBuilder<List<VideoModel>>(
            future: _futureVideos,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Center(child: CircularProgressIndicator());
              } else if (snap.hasError) {
                return Center(child: Text('Failed to load videos: ${snap.error}'));
              } else {
                final videos = snap.data ?? [];
                if (videos.isEmpty) return Center(child: Text('No videos available'));
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() { _futureVideos = Api.fetchVideos(); });
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: videos.length,
                    itemBuilder: (_, i) => _videoCard(videos[i]),
                  ),
                );
              }
            },
          ),
        ),
      ]),
    );
  }
}