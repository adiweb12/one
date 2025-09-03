import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_page.dart';

const String SERVER_IP = "test-4udw.onrender.com";

class GroupPage extends StatefulWidget {
  final String username;
  final String token;

  GroupPage({required this.username, required this.token});

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List groups = [];
  final TextEditingController groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/get_groups");
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          groups = data['groups'];
        });
      }
    } catch (e) {
      print("Fetch groups error: $e");
    }
  }

  Future<void> createGroup() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/create_group");
      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: json.encode({"group_name": groupNameController.text}),
      );

      var data = json.decode(response.body);
      if (data['success']) {
        fetchGroups();
        groupNameController.clear();
      }
    } catch (e) {
      print("Create group error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Groups")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: groupNameController,
                    decoration: const InputDecoration(labelText: "New Group"),
                  ),
                ),
                IconButton(onPressed: createGroup, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                var group = groups[index];
                return ListTile(
                  title: Text(group['name']),
                  subtitle: Text("ID: ${group['number']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          username: widget.username,
                          token: widget.token,
                          groupId: group['number'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}