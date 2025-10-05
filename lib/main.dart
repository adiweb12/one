// main.dart
// Single-file Flutter app (complete) using socket_io_client + http + flutter_secure_storage
// Put this in lib/main.dart of a Flutter project. Ensure pubspec.yaml has the required packages.

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------
// Configuration
// ---------------------------
const String SERVER_URL = 'https://one-music-1dmn.onrender.com'; // <-- Your backend URL
final FlutterSecureStorage secureStorage = FlutterSecureStorage();

// ---------------------------
// SocketService (singleton)
// ---------------------------
class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      _socket = IO.io(
        SERVER_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // we'll connect manually
            .build(),
      );
      _socket!.connect();
    }
    return _socket!;
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

// ---------------------------
// App state
// ---------------------------
class AppState {
  static String? username;
  static String? phone;
  static String? userId;
}

// ---------------------------
// Utilities
// ---------------------------
void showError(BuildContext ctx, String message) {
  if (!ctx.mounted) return;
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
}

void showInfo(BuildContext ctx, String message) {
  if (!ctx.mounted) return;
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------
// Main
// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppState.username = await secureStorage.read(key: 'username');
  AppState.phone = await secureStorage.read(key: 'phone');
  AppState.userId = await secureStorage.read(key: 'userId');
  // Initialize socket early
  SocketService.socket;
  runApp(const MyApp());
}

// ---------------------------
// MyApp
// ---------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final Widget home = AppState.username != null ? const ChatHomePage() : const LoginScreen();
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: home,
    );
  }
}

// ---------------------------
// Reusable UI helpers
// ---------------------------
Widget gradientButton(String text, VoidCallback onPressed) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: MaterialButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget gradientTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: isPassword,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
  );
}

// ---------------------------
// Login Screen
// ---------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      showError(context, 'Please enter phone and password.');
      return;
    }
    setState(() { loading = true; });
    try {
      final res = await http.post(Uri.parse('$SERVER_URL/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'phone': phone, 'password': pass}));
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        await secureStorage.write(key: 'username', value: body['username']);
        await secureStorage.write(key: 'phone', value: phone);
        await secureStorage.write(key: 'userId', value: body['id'].toString());
        AppState.username = body['username'];
        AppState.phone = phone;
        AppState.userId = body['id'].toString();
        showInfo(context, 'Welcome, ${AppState.username}');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatHomePage()));
      } else {
        showError(context, body['message'] ?? 'Login failed');
      }
    } catch (e) {
      showError(context, 'Error connecting: $e');
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF003DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('ChatFlow', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),
                gradientTextField(controller: phoneController, hint: 'Phone number', icon: Icons.phone_android, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                gradientTextField(controller: passController, hint: 'Password', icon: Icons.lock, isPassword: true),
                const SizedBox(height: 24),
                loading ? const CircularProgressIndicator(color: Colors.white) : gradientButton('LOG IN', login),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// SignUp Screen
// ---------------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool loading = false;

  Future<void> signup() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();
    if (username.isEmpty || phone.isEmpty || pass.isEmpty) {
      showError(context, 'Please fill all fields.');
      return;
    }
    setState(() { loading = true; });
    try {
      final res = await http.post(Uri.parse('$SERVER_URL/signup'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'phone': phone, 'password': pass}));
      final body = json.decode(res.body);
      if (res.statusCode == 201) {
        showInfo(context, 'Account created. Please log in.');
        Navigator.pop(context);
      } else {
        showError(context, body['message'] ?? 'Signup failed');
      }
    } catch (e) {
      showError(context, 'Error connecting: $e');
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF003DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80, left: 24, right: 24, bottom: 40),
          child: Column(
            children: [
              const Text('Join ChatFlow', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              // Simple white fields on gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    TextField(controller: usernameController, decoration: const InputDecoration(hintText: 'Username', hintStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, decoration: const InputDecoration(hintText: 'Phone', hintStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextField(controller: passController, decoration: const InputDecoration(hintText: 'Password', hintStyle: TextStyle(color: Colors.white70)), obscureText: true, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    loading ? const CircularProgressIndicator(color: Colors.white) : gradientButton('SIGN UP', signup),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// Chat Home (tabs for People/Groups)
// ---------------------------
class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});
  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}
class _ChatHomePageState extends State<ChatHomePage> {
  int _index = 0;

  Future<void> _logout() async {
    await secureStorage.deleteAll();
    AppState.username = null;
    AppState.phone = null;
    AppState.userId = null;
    SocketService.disconnect();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Create Group'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Group name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            try {
              final res = await http.post(Uri.parse('$SERVER_URL/create_group'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({'name': name, 'creator': AppState.username}),
              );
              final body = json.decode(res.body);
              if (res.statusCode == 201) {
                Navigator.pop(ctx);
                showInfo(context, 'Group created');
                setState(() => _index = 1); // switch to groups
              } else {
                showError(context, body['message'] ?? 'Create failed');
              }
            } catch (e) {
              showError(context, 'Error creating group: $e');
            }
          }, child: const Text('Create')),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Chats';
    return DefaultTabController(
      length: 2,
      initialIndex: _index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF4A00E0),
          actions: [
            IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PEOPLE', icon: Icon(Icons.person_outline)),
              Tab(text: 'GROUPS', icon: Icon(Icons.group_outlined)),
            ],
          ),
        ),
        body: const TabBarView(children: [PeopleSection(), GroupSection()]),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateGroupDialog,
          backgroundColor: const Color(0xFF00C6FF),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// People section - placeholder (no private chats implemented server-side)
class PeopleSection extends StatelessWidget {
  const PeopleSection({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(
      padding: EdgeInsets.all(32.0),
      child: Text('No one-to-one chat implemented. Use Groups for multi-user chat.', textAlign: TextAlign.center),
    ));
  }
}

// Group section - fetch groups for logged-in user
class GroupSection extends StatefulWidget {
  const GroupSection({super.key});
  @override
  State<GroupSection> createState() => _GroupSectionState();
}
class _GroupSectionState extends State<GroupSection> {
  bool loading = true;
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() { loading = true; });
    try {
      final username = AppState.username;
      if (username == null) return;
      final res = await http.get(Uri.parse('$SERVER_URL/user_groups/$username'));
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          groups = List<Map<String, dynamic>>.from(body['groups']);
        });
      } else {
        showError(context, body['message'] ?? 'Failed to fetch groups');
      }
    } catch (e) {
      showError(context, 'Error fetching groups: $e');
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (groups.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('You have not joined any groups. Create one!'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchGroups, child: const Text('Refresh')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchGroups,
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (ctx, i) {
          final g = groups[i];
          return ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF00C6FF), child: const Icon(Icons.group, color: Colors.white)),
            title: Text(g['name'] ?? 'Group'),
            subtitle: Text('Tap to join'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatName: g['name'] ?? 'Group', roomId: g['room_id'] ?? '', isGroupChat: true)))
                .then((_) => _fetchGroups());
            },
          );
        },
      ),
    );
  }
}

// ---------------------------
// Chat Screen
// ---------------------------
class ChatScreen extends StatefulWidget {
  final String chatName;
  final String roomId;
  final bool isGroupChat;
  const ChatScreen({super.key, required this.chatName, required this.roomId, this.isGroupChat = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool remoteTyping = false;

  IO.Socket get socket => SocketService.socket;
  String get me => AppState.username ?? 'Unknown';

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    socket.onConnect((_) {
      // join room after connect
      socket.emit('join_chat', {'room_id': widget.roomId, 'username': me});
    });

    socket.on('message_history', (data) {
      if (data == null) return;
      if (data['room_id'] != widget.roomId) return;
      messages.clear();
      for (var m in data['messages']) {
        messages.add({
          'sender': m['sender'],
          'message': m['message'],
          'isMe': m['sender'] == me,
          'timestamp': m['timestamp'],
        });
      }
      setState(() {});
      _scrollToBottom();
    });

    socket.on('receive_message', (data) {
      if (data == null) return;
      if (data['room_id'] != widget.roomId) return;
      // avoid duplicating optimistic message from self: check content and sender
      setState(() {
        messages.add({
          'sender': data['sender'],
          'message': data['message'],
          'isMe': data['sender'] == me,
          'timestamp': data['timestamp'],
        });
      });
      _scrollToBottom();
    });

    socket.on('typing', (data) {
      if (data == null) return;
      if (data['room_id'] != widget.roomId) return;
      if (data['username'] == me) return;
      setState(() {
        remoteTyping = data['typing'] == true;
      });
    });

    socket.on('group_deleted', (data) {
      if (data == null) return;
      if (data['room_id'] == widget.roomId) {
        if (mounted) {
          showError(context, 'This group was deleted.');
          Navigator.pop(context);
        }
      }
    });

    socket.onDisconnect((_) {
      // handle disconnect UI if needed
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage() {
    final text = msgController.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final ts = '${now.hour}:${now.minute.toString().padLeft(2,'0')}';

    // optimistic update
    setState(() {
      messages.add({'sender': me, 'message': text, 'isMe': true, 'timestamp': ts});
    });
    _scrollToBottom();

    socket.emit('send_message', {'room_id': widget.roomId, 'sender': me, 'message': text});
    msgController.clear();
    _setTyping(false);
  }

  void _setTyping(bool typing) {
    if (isTyping == typing) return;
    isTyping = typing;
    socket.emit('typing', {'room_id': widget.roomId, 'username': me, 'typing': typing});
  }

  Future<void> _handleGroupAction(String action) async {
    final Map<String, String> data = {'room_id': widget.roomId, 'username': me};
    final endpoint = action == 'leave' ? '/leave_group' : '/delete_group';
    try {
      final res = await http.post(Uri.parse('$SERVER_URL$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        showInfo(context, body['message'] ?? 'Action done');
        Navigator.pop(context);
      } else {
        showError(context, body['message'] ?? 'Action failed');
      }
    } catch (e) {
      showError(context, 'Server error: $e');
    }
  }

  @override
  void dispose() {
    socket.off('message_history');
    socket.off('receive_message');
    socket.off('typing');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typingWidget = remoteTyping ? const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text('Someone is typing...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
    ) : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          if (widget.isGroupChat)
            PopupMenuButton<String>(
              onSelected: (v) => _handleGroupAction(v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'leave', child: Text('Leave Group')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Group', style: TextStyle(color: Colors.red))),
              ],
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final m = messages[i];
                final isMe = m['isMe'] == true;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00C6FF) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe && widget.isGroupChat) Text(m['sender'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(m['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                        const SizedBox(height: 6),
                        Text(m['timestamp'] ?? '', style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45)),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
          typingWidget,
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF4A00E0)), onPressed: () => showInfo(context, 'Attachment not implemented')),
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: const InputDecoration(hintText: 'Type a message...', filled: true, fillColor: Color(0xFFF2F2F2), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(24)))),
                    onChanged: (v) {
                      _setTyping(v.trim().isNotEmpty);
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF00C6FF)), onPressed: _sendMessage)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
