import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import 'group_page.dart';

const String SERVER_IP = "test-4udw.onrender.com";

class ProfilePage extends StatefulWidget {
  final String username;
  final String token;

  ProfilePage({required this.username, required this.token});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  List groups = [];
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/profile");
      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          name = data['name'];
          groups = data['groups'];
          _loading = false;
        });
      }
    } catch (e) {
      print("Profile fetch error: $e");
    }
  }

  Future<void> updateProfile() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/update_profile");
      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: json.encode({"newName": _nameController.text}),
      );

      var data = json.decode(response.body);
      if (data['success']) {
        fetchProfile();
        _nameController.clear();
      }
    } catch (e) {
      print("Update profile error: $e");
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Username: ${widget.username}"),
                  const SizedBox(height: 10),
                  Text("Name: $name"),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Update Name"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: updateProfile, child: const Text("Update")),
                  const SizedBox(height: 20),
                  const Text("Groups:"),
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
                                builder: (_) => GroupPage(
                                  username: widget.username,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}