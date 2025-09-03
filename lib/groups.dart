import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'create_group.dart';
import 'join_group.dart';

class GroupsPage extends StatefulWidget {
  final String username;
  final String token;

  const GroupsPage({super.key, required this.username, required this.token});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    var url = Uri.parse("https://test-4udw.onrender.com/profile");
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}",
      },
      body: json.encode({}),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        groups = data['groups'] ?? [];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          username: widget.username,
          token: widget.token,
        ),
      ),
    );
  }

  void _openCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupPage(token: widget.token),
      ),
    ).then((_) => fetchGroups());
  }

  void _openJoinGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinGroupPage(token: widget.token),
      ),
    ).then((_) => fetchGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups"),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const Center(child: Text("No groups yet"))
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    var group = groups[index];
                    return ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(group['name']),
                      subtitle: Text("ID: ${group['number']}"),
                    );
                  },
                ),
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'create') {
            _openCreateGroup();
          } else if (value == 'join') {
            _openJoinGroup();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'create', child: Text("Create Group")),
          const PopupMenuItem(value: 'join', child: Text("Join Group")),
        ],
        child: const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue,
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
