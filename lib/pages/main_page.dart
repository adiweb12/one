import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/group.dart';
import '../utils/storage.dart';
import 'chat_page.dart';
import 'create_group_page.dart';
import 'join_group_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Group> groups = [];
  bool loading = true;
  String token = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final t = await Storage.readToken();
    if (t == null) return;
    token = t;

    final res = await ApiService.fetchGroups(token);
    setState(() {
      groups = res;
      loading = false;
    });
  }

  void logout() async {
    await ApiService.logout(token);
    await Storage.deleteToken();
    await Storage.deleteUsername();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OneChat Groups"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()))
                    .then((_) => loadData());
              },
              icon: const Icon(Icons.person))
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final g = groups[index];
                return ListTile(
                  title: Text(g.name),
                  subtitle: Text(g.number),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ChatPage(group: g, token: token)));
                  },
                );
              }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateGroupPage()))
                  .then((_) => loadData());
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'join',
            onPressed: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const JoinGroupPage()))
                  .then((_) => loadData());
            },
            child: const Icon(Icons.group_add),
          ),
        ],
      ),
    );
  }
}
