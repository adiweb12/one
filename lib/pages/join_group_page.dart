import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/storage.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});
  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _groupNumberController = TextEditingController();
  bool loading = false;
  String token = '';

  @override
  void initState() {
    super.initState();
    Storage.readToken().then((t) => token = t ?? '');
  }

  void joinGroup() async {
    setState(() => loading = true);
    final res = await ApiService.joinGroup(token, _groupNumberController.text.trim());
    setState(() => loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'])));
    if (res['success'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
            controller: _groupNumberController,
            decoration: const InputDecoration(labelText: "Group Number"),
          ),
          const SizedBox(height: 20),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: joinGroup, child: const Text("Join Group")),
        ]),
      ),
    );
  }
}
