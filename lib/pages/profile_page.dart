import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String name = '';
  List groups = [];
  final _nameController = TextEditingController();
  String token = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() async {
    final t = await Storage.readToken();
    if (t == null) return;
    token = t;

    final profile = await ApiService.getProfile(token);
    setState(() {
      username = profile['username'] ?? '';
      name = profile['name'] ?? '';
      groups = profile['groups'] ?? [];
      _nameController.text = name;
      loading = false;
    });
  }

  void updateProfile() async {
    final res = await ApiService.updateProfile(token, _nameController.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'])));
    if (res['success'] == true) loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                Text("Username: $username"),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: updateProfile, child: const Text("Update")),
                const SizedBox(height: 20),
                const Text("Groups:"),
                Expanded(
                  child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        return ListTile(
                          title: Text(g['name']),
                          subtitle: Text(g['number']),
                        );
                      }),
                ),
              ]),
            ),
    );
  }
}
