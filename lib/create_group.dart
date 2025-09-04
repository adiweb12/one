import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateGroupPage extends StatefulWidget {
  final String token;
  const CreateGroupPage({super.key, required this.token});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;

  Future<void> _createGroup() async {
    setState(() => _loading = true);
    var url = Uri.parse("https://test-4udw.onrender.com/create_group");
    var response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: json.encode({"groupName": _nameController.text.trim(), "groupNumber": _idController.text.trim()}));

    setState(() => _loading = false);
    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Group created successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating group")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _nameController, decoration: InputDecoration(labelText: "Group Name")),
          SizedBox(height: 10),
          TextField(controller: _idController, decoration: InputDecoration(labelText: "Group ID")),
          SizedBox(height: 20),
          _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _createGroup, child: Text("Create")),
        ]),
      ),
    );
  }
}