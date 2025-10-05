import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_service.dart';
import '../models/group.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {
  final Group group;
  final String token;
  const ChatPage({super.key, required this.group, required this.token});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  late WebSocketChannel channel;
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    connectWS();
    loadMessages();
  }

  void connectWS() {
    // Replace with your actual WebSocket server URL
    channel = WebSocketChannel.connect(
        Uri.parse('wss://your-server-websocket-url/${widget.group.number}'));

    channel.stream.listen((data) {
      final jsonData = json.decode(data);
      setState(() {
        messages.add(Message(
            sender: jsonData['sender'],
            text: jsonData['message'],
            time: DateTime.parse(jsonData['time'])));
      });
    });
  }

  void loadMessages() async {
    final msgs = await ApiService.getMessages(widget.token, widget.group.number);
    setState(() {
      messages = msgs;
    });
  }

  void sendMessage() async {
    if (_controller.text.isEmpty) return;
    final text = _controller.text;
    _controller.clear();

    final res = await ApiService.sendMessage(widget.token, widget.group.number, text);
    if (res['success']) {
      // Optionally, send via WebSocket here too
      // channel.sink.add(json.encode({...}));
      loadMessages(); // reload latest messages
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.sender == widget.group.number;
                return ListTile(
                  title: Text(msg.sender),
                  subtitle: Text(msg.text),
                  trailing: Text(msg.time.toLocal().toString().split('.')[0]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: "Message..."),
                )),
                IconButton(onPressed: sendMessage, icon: const Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}
