import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String token;
  final String groupId;
  final String username;
  const ChatPage({super.key, required this.token, required this.groupId, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List messages = [];

  Future<void> _sendMessage() async {
    var url = Uri.parse("https://test-4udw.onrender.com/send_message");
    await http.post(url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${widget.token}"},
        body: json.encode({"groupNumber": widget.groupId, "message": _messageController.text.trim()}));
    _messageController.clear();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    var url = Uri.parse("https://test-4udw.onrender.com/get_messages/${widget.groupId}");
    var response = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}"});
    if (response.statusCode == 200) {
      setState(() => messages = json.decode(response.body)["messages"]);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat - ${widget.groupId}")),
      body: Column(children: [
        Expanded(
            child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];
                  return ListTile(title: Text(msg["sender"]), subtitle: Text(msg["message"]));
                })),
        Row(children: [
          Expanded(child: TextField(controller: _messageController, decoration: InputDecoration(hintText: "Type message"))),
          IconButton(icon: Icon(Icons.send), onPressed: _sendMessage)
        ])
      ]),
    );
  }
}