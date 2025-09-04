import 'package:flutter/material.dart';
import 'create_group.dart';
import 'join_group.dart';
import 'profile.dart';
import 'chat_page.dart';

class GroupsPage extends StatelessWidget {
  final String username;
  final String token;

  const GroupsPage({super.key, required this.username, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Groups"),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(username: username, token: token)));
            },
          )
        ],
      ),
      body: Center(child: Text("Your groups will appear here")),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "create",
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupPage(token: token)));
            },
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "join",
            child: Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => JoinGroupPage(token: token)));
            },
          ),
        ],
      ),
    );
  }
}