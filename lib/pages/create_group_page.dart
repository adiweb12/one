import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/storage.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  final _groupNumberController = TextEditingController();
  bool loading = false;
  String token = '';

  @override
  void initState() {
    super.initState();
    Storage.readToken().then((t) => token = t ?? '');
  }

  void createGroup() async {
    setState(() => loading = true);
    final res = await ApiService.createGroup(
        token, _groupNameController.text.trim(), _groupNumberController.text.trim());
    setState(() => loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(res['message'])));
    if (res['success'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(labelText: "Group Name"),
          ),
          TextField(
            controller: _groupNumberController,
            decoration: const InputDecoration(labelText: "Group Number"),
          ),
          const SizedBox(height: 20),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: createGroup, child: const Text("Create Group")),
        ]),
      ),
    );
  }
}
