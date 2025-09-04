import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JoinGroupPage extends StatefulWidget {
  final String token;
  const JoinGroupPage({super.key, required this.token});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final TextEditingController _idController = TextEditingController();
  bool _loading = false;

  Future<void> _joinGroup() async {
    setState(() => _loading = true);
    var url = Uri.parse("https://test-4udw.onrender.com/join_group");
    var response = await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: json.encode({"groupNumber": _idController.text.trim()}));

    setState(() => _loading = false);
    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined group successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error joining group")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Group")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _idController, decoration: InputDecoration(labelText: "Group ID")),
          SizedBox(height: 20),
          _loading ? CircularProgressIndicator() : ElevatedButton(onPressed: _joinGroup, child: Text("Join")),
        ]),
      ),
    );
  }
}