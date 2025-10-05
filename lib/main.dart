import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Global constants for app-wide use
const String mockLoggedInUser = 'FlutterDev';

// -----------------------------------------------------------------------------
// --- SOCKET MIXIN (Connection Logic) ---
// -----------------------------------------------------------------------------
// Note: This mixin pattern is used to attach the socket logic to the MyApp widget
mixin ChatState on State<MyApp> {
  // *** IMPORTANT: REPLACE THIS WITH YOUR ACTUAL RENDER SERVICE URL ***
  // Use https if your Render service enforces it.
  // For local testing: final String serverUrl = 'http://10.0.2.2:5000';
  final String serverUrl = 'https://one-music-1dmn.onrender.com/'; 
  
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    // Initialize socket immediately when MyApp starts
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket']) // Use WebSocket transport
        .disableAutoConnect()
        .build()
    );

    socket.connect();
    socket.onConnect((_) => print('SOCKET CONNECTED: ${socket.id}'));
    socket.onDisconnect((_) => print('SOCKET DISCONNECTED'));
    socket.on('status', (data) => print('SERVER STATUS: ${data['msg']}'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// --- MAIN APP STRUCTURE ---
// -----------------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ChatState {
  @override
  Widget build(BuildContext context) {
    // The socket object is now accessible via the ChatState mixin.
    return MaterialApp(
      title: 'ChattyApp',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A00E0),
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          color: Color(0xFF4A00E0), 
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const LoginScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------------------------------
// --- Reusable UI Widgets ---
// -----------------------------------------------------------------------------

Widget buildGradientButton({required String text, required VoidCallback onPressed}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30.0),
      gradient: const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: MaterialButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget buildGradientTextField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool isPassword = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: isPassword,
    style: const TextStyle(color: Colors.white, fontSize: 18),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
    ),
  );
}

// -----------------------------------------------------------------------------
// --- 1. LOGIN SCREEN ---
// -----------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    if (_phoneController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatHomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number and password.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF003DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              const Text('ChatFlow', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2.0, shadows: [Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(0, 3))])),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: <Widget>[
                    buildGradientTextField(controller: _phoneController, hintText: 'Phone Number', icon: Icons.phone_android, keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    buildGradientTextField(controller: _passwordController, hintText: 'Password', icon: Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 35),
                    buildGradientButton(text: 'LOG IN', onPressed: _login),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                      },
                      child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70, fontSize: 16, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- 2. SIGN UP SCREEN ---
// -----------------------------------------------------------------------------
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reusing the gradient container for consistency
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true, 
      body: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF003DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(child: Padding(
          padding: EdgeInsets.only(top: 150),
          child: Text("Sign Up Form Here", style: TextStyle(color: Colors.white, fontSize: 24)),
        )),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- 3. CHAT HOME PAGE (People & Groups) ---
// -----------------------------------------------------------------------------

class ChatHomePage extends StatelessWidget {
  const ChatHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4.0,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'PEOPLE', icon: Icon(Icons.person_outline)),
              Tab(text: 'GROUPS', icon: Icon(Icons.group_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PeopleSection(),
            GroupSection(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF00C6FF),
          onPressed: () {},
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// --- People Section Content ---
class PeopleSection extends StatelessWidget {
  const PeopleSection({super.key});
  final List<Map<String, String>> people = const [
    {'name': 'Alice', 'id': 'chat_alice'},
    {'name': 'Bob', 'id': 'chat_bob'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF8E2DE2), child: Text(people[index]['name']![0], style: const TextStyle(color: Colors.white))),
        title: Text(people[index]['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to start socket chat...'),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: people[index]['name']!,
              roomId: people[index]['id']!,
              isGroupChat: false, 
            ),
          ));
        },
      ),
    );
  }
}

// --- Groups Section Content ---
class GroupSection extends StatelessWidget {
  const GroupSection({super.key});
  final List<Map<String, String>> groups = const [
    {'name': 'Flutter Devs', 'id': 'group_flutter'},
    {'name': 'Weekend Trekkers', 'id': 'group_trek'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFF00C6FF), child: Icon(Icons.group, color: Colors.white)),
        title: Text(groups[index]['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to join group socket chat...'),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: groups[index]['name']!,
              roomId: groups[index]['id']!,
              isGroupChat: true, 
            ),
          ));
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- 4. PROFILE PAGE ---
// -----------------------------------------------------------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    // Navigate back to the LoginScreen and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            color: Colors.grey[50],
            child: const Column(children: [
                CircleAvatar(radius: 60, backgroundColor: Color(0xFF8E2DE2), child: Icon(Icons.person, size: 50, color: Colors.white70)),
                SizedBox(height: 20),
                Text('John Doe (Mock User)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
          ),
          ListTile(leading: const Icon(Icons.edit, color: Color(0xFF4A00E0)), title: const Text('Change Display Name'), onTap: () {}),
          ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notifications'), trailing: Switch(value: true, onChanged: (bool value) {})),
          ListTile(leading: const Icon(Icons.security), title: const Text('Privacy and Security'), onTap: () {}),
          
          const Divider(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Log Out', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => _logout(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- 5. CHAT SCREEN (WebSockets Integration) ---
// -----------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  final String chatName;
  final String roomId;
  final bool isGroupChat;

  const ChatScreen({
    super.key,
    required this.chatName,
    required this.roomId,
    this.isGroupChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  // Safely get the socket instance from the root of the app
  IO.Socket get socket => (context.findAncestorStateOfType<_MyAppState>() as _MyAppState).socket;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    // Request to join the room and load history upon entering the screen
    _joinChatRoom(); 
  }

  void _joinChatRoom() {
    if (socket.connected) {
      socket.emit('join_chat', {
        'room_id': widget.roomId,
        'username': mockLoggedInUser,
      });
    }
  }

  void _setupSocketListeners() {
    // Listener for receiving real-time messages
    socket.on('receive_message', (data) {
      if (data['room_id'] == widget.roomId) {
        setState(() {
          // Only add if the message is NOT from this user (to avoid duplication after local update)
          if (data['sender'] != mockLoggedInUser) {
             _messages.add(data);
          }
        });
        _scrollToBottom();
      }
    });

    // --- Listener for message history from the database ---
    socket.on('message_history', (data) {
      if (data['room_id'] == widget.roomId) {
        setState(() {
          _messages.clear(); 
          for (var msg in data['messages']) {
              _messages.add({
                  'room_id': msg['room_id'],
                  'sender': msg['sender'],
                  'message': msg['message'],
                  'isMe': msg['sender'] == mockLoggedInUser, // Check ownership
                  'timestamp': msg['timestamp'] 
              });
          }
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final messageData = {
      'room_id': widget.roomId,
      'sender': mockLoggedInUser,
      'message': text,
      'isMe': true, 
      'timestamp': DateTime.now().hour.toString() + ':' + DateTime.now().minute.toString().padLeft(2, '0') 
    };

    // 1. Instantly update local UI
    setState(() {
      _messages.add(messageData);
    });
    
    // 2. Emit to the server
    socket.emit('send_message', messageData);
    
    // 3. Clear and scroll
    _messageController.clear();
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    // Ensure scrolling happens after the UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: <Widget>[
          if (widget.isGroupChat)
            PopupMenuButton<String>(
              onSelected: (String result) {
                // Mock actions for leave/delete
                if (result == 'leave') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left Group! (Mock)')),);
                  Navigator.pop(context); 
                } else if (result == 'delete') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group Deleted! (Mock)'), backgroundColor: Colors.red));
                  Navigator.pop(context); 
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'leave', child: Text('Leave Group')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete Group', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      
      body: Column(
        children: <Widget>[
          // 1. Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // 2. Message Input Field
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final text = message['message'] as String;
    final sender = message['sender'] as String;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? const Color(0xFF00C6FF) : const Color(0xFFE0E0E0);
    final textColor = isMe ? Colors.white : Colors.black;

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && sender != 'SYSTEM') // Show sender name for others' messages
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0, left: 12.0, right: 12.0),
              child: Text(sender, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.0).copyWith(
                bottomLeft: isMe ? const Radius.circular(15.0) : const Radius.circular(5.0),
                bottomRight: isMe ? const Radius.circular(5.0) : const Radius.circular(15.0),
              ),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]
            ),
            child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
            child: Text(message['timestamp'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          )
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF4A00E0)), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Color(0xFF00C6FF), size: 30), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
