import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String SERVER_IP = "test-4udw.onrender.com";

class ChatPage extends StatefulWidget {
  final String username;
  final String token;
  final int groupId;

  ChatPage({required this.username, required this.token, required this.groupId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupId}");
      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          messages = data['messages'];
          _loading = false;
        });
      }
    } catch (e) {
      print("Fetch messages error: $e");
    }
  }

  Future<void> sendMessage() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/send_message/${widget.groupId}");
      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: json.encode({"message": _messageController.text}),
      );

      var data = json.decode(response.body);
      if (data['success']) {
        _messageController.clear();
        fetchMessages();
      }
    } catch (e) {
      print("Send message error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat Group ${widget.groupId}")),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var msg = messages[index];
                      return ListTile(
                        title: Text(msg['sender']),
                        subtitle: Text(msg['message']),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(onPressed: sendMessage, icon: const Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}