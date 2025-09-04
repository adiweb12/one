import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(ChatApp());
}

const String SERVER_IP = "https://test-4udw.onrender.com"; // Change to your server IP

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool isLogin = true;

  Future<void> authenticate() async {
    String url = SERVER_IP + (isLogin ? "/login" : "/register");
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameCtrl.text,
        "password": passwordCtrl.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(username: data["username"]),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["error"] ?? "Error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: usernameCtrl, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: authenticate,
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "No account? Register" : "Have account? Login"),
            )
          ],
        ),
      ),
    );
  }
}

// --- CHAT PAGE ---
class ChatPage extends StatefulWidget {
  final String username;
  ChatPage({required this.username});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  List messages = [];
  final TextEditingController msgCtrl = TextEditingController();
  String currentRoom = "";

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    socket = IO.io(SERVER_IP, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    socket.connect();

    socket.on("connect", (_) {
      print("Connected to server");
    });

    socket.on("room_created", (data) {
      setState(() {
        currentRoom = data["room"];
        messages.clear();
      });
    });

    socket.on("room_joined", (data) {
      setState(() {
        currentRoom = data["room"];
        messages.clear();
      });
    });

    socket.on("receive_message", (data) {
      setState(() {
        messages.add(data);
      });
    });

    socket.on("error", (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    });
  }

  void sendMessage() {
    if (msgCtrl.text.isNotEmpty && currentRoom.isNotEmpty) {
      socket.emit("send_message", {
        "username": widget.username,
        "message": msgCtrl.text,
        "room": currentRoom,
      });
      msgCtrl.clear();
    }
  }

  void showRoomDialog() {
    TextEditingController roomCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Join or Create Room"),
          content: TextField(
            controller: roomCtrl,
            decoration: InputDecoration(hintText: "Enter room name"),
          ),
          actions: [
            TextButton(
              child: Text("Join"),
              onPressed: () {
                socket.emit("join_room", {
                  "room": roomCtrl.text,
                  "username": widget.username,
                });
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Create"),
              onPressed: () {
                socket.emit("create_room", {
                  "room": roomCtrl.text,
                  "username": widget.username,
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat - ${widget.username}")),
      body: Column(
        children: [
          if (currentRoom.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Room: $currentRoom", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ListTile(
                  title: Text(msg["username"]),
                  subtitle: Text(msg["message"]),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText: "Enter message")),
              ),
              IconButton(icon: Icon(Icons.send), onPressed: sendMessage)
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: showRoomDialog,
      ),
    );
  }
}
