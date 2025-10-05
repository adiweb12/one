import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // NEW IMPORT

// --- Global State Management ---
class AppState {
  static String? loggedInUsername;
  static String? loggedInPhone;
  static String? loggedInUserId; // Changed to String to align with storage keys
}

// Global secure storage instance
const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

// -----------------------------------------------------------------------------
// --- SOCKET MIXIN (Connection Logic) ---
// -----------------------------------------------------------------------------

mixin ChatState on State<MyApp> {
  // *** IMPORTANT: REPLACE THIS WITH YOUR ACTUAL RENDER SERVICE URL ***
  // Use https if your Render service enforces it.
  // For local testing: final String serverUrl = 'http://10.0.2.2:5000';
  final String serverUrl = 'https://one-music-1dmn.onrender.com/'; 
  
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadUserSession();
  runApp(const MyApp());
}

// UPDATED: Load user session from Secure Storage
Future<void> _loadUserSession() async {
  AppState.loggedInUsername = await _secureStorage.read(key: 'username');
  AppState.loggedInPhone = await _secureStorage.read(key: 'phone');
  AppState.loggedInUserId = await _secureStorage.read(key: 'userId');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Added global key to allow accessing ChatState from anywhere
  static final globalKey = GlobalKey();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ChatState {
  @override
  Widget build(BuildContext context) {
    // Determine the starting screen based on session state
    final initialRoute = AppState.loggedInUsername != null 
      ? const ChatHomePage() 
      : const LoginScreen();

    return MaterialApp(
      key: MyApp.globalKey, // Assign the global key
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
      home: initialRoute, 
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------------------------------
// --- Reusable UI Widgets (No changes needed) ---
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
  final String serverUrl = (MyApp.globalKey.currentContext?.findAncestorStateOfType<ChatState>() as ChatState).serverUrl;

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone and password.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        
        // UPDATED: Store securely
        await _secureStorage.write(key: 'username', value: responseBody['username']);
        await _secureStorage.write(key: 'phone', value: phone);
        await _secureStorage.write(key: 'userId', value: responseBody['id'].toString()); // Store ID as string
        
        AppState.loggedInUsername = responseBody['username'];
        AppState.loggedInPhone = phone;
        AppState.loggedInUserId = responseBody['id'].toString();

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatHomePage()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? 'Login failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to server: $e'), backgroundColor: Colors.red),
        );
      }
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
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String serverUrl = (MyApp.globalKey.currentContext?.findAncestorStateOfType<ChatState>() as ChatState).serverUrl;

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'phone': phone, 'password': password}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created for ${responseBody['username']}! Please log in.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to Login Screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? 'Sign up failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to server: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true, 
      body: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF003DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 100, bottom: 40, left: 30, right: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Join ChatFlow', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 40),
              buildGradientTextField(controller: _usernameController, hintText: 'Username', icon: Icons.person_outline),
              const SizedBox(height: 20),
              buildGradientTextField(controller: _phoneController, hintText: 'Phone Number', icon: Icons.phone_android, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              buildGradientTextField(controller: _passwordController, hintText: 'Password', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 35),
              buildGradientButton(text: 'SIGN UP', onPressed: _signup),
            ],
          ),
        ),
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
          onPressed: () => _showCreateGroupDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController groupNameController = TextEditingController();
    final String serverUrl = (context.findAncestorStateOfType<_MyAppState>() as _MyAppState).serverUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: groupNameController,
          decoration: const InputDecoration(hintText: 'Group Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final name = groupNameController.text.trim();
              if (name.isEmpty) return;

              try {
                final response = await http.post(
                  Uri.parse('$serverUrl/create_group'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'name': name, 'creator': AppState.loggedInUsername}),
                );

                if (response.statusCode == 201) {
                  // Successfully created, refresh the groups list
                  if (context.mounted) {
                    Navigator.pop(context);
                    DefaultTabController.of(context).animateTo(1); // Switch to Groups tab
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created! Refreshing list...')));
                  }
                } else {
                  if (context.mounted) {
                    final responseBody = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseBody['message'] ?? 'Failed to create group')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFF0072FF))),
          ),
        ],
      ),
    );
  }
}

// --- People Section Content (Empty for now) ---
class PeopleSection extends StatelessWidget {
  const PeopleSection({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No active 1-on-1 chats. Users must be manually added to chat lists in a real app.', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Groups Section Content (Dynamic fetching) ---
class GroupSection extends StatefulWidget {
  const GroupSection({super.key});

  @override
  State<GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<GroupSection> {
  List<Map<String, String>> groups = [];
  bool isLoading = true;
  final String serverUrl = (MyApp.globalKey.currentContext?.findAncestorStateOfType<ChatState>() as ChatState).serverUrl;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      isLoading = true;
    });

    try {
      final username = AppState.loggedInUsername;
      if (username == null) {
        setState(() { isLoading = false; });
        return;
      }

      final response = await http.get(Uri.parse('$serverUrl/user_groups/$username'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          groups = List<Map<String, String>>.from(data['groups'].map((g) => {
            'name': g['name'],
            'id': g['room_id']
          }));
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load groups: ${json.decode(response.body)['message']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching groups: $e')));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have not joined any groups. Use the + button to create one!'),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _fetchGroups, child: const Text('Refresh Groups')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGroups,
      child: ListView.builder(
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
            )).then((_) => _fetchGroups()); // Refresh when returning from chat
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- 4. PROFILE PAGE ---
// -----------------------------------------------------------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // UPDATED: Use Secure Storage to log out
  Future<void> _logout(BuildContext context) async {
    await _secureStorage.deleteAll(); // Clear all stored credentials

    AppState.loggedInUsername = null;
    AppState.loggedInPhone = null;
    AppState.loggedInUserId = null;

    if (context.mounted) {
      // Navigate back to the LoginScreen and clear the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
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
            child: Column(children: [
                const CircleAvatar(radius: 60, backgroundColor: Color(0xFF8E2DE2), child: Icon(Icons.person, size: 50, color: Colors.white70)),
                const SizedBox(height: 20),
                Text(AppState.loggedInUsername ?? 'Guest', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(AppState.loggedInPhone ?? 'N/A', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ]),
          ),
          ListTile(leading: const Icon(Icons.edit, color: Color(0xFF4A00E0)), title: const Text('Change Display Name'), onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature not implemented on server.')));
          }),
          ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notifications'), trailing: Switch(value: true, onChanged: (bool value) {})),
          ListTile(leading: const Icon(Icons.security), title: const Text('Privacy and Security'), onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature not implemented.')));
          }),
          
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

  IO.Socket get socket => (context.findAncestorStateOfType<_MyAppState>() as _MyAppState).socket;
  String get serverUrl => (context.findAncestorStateOfType<_MyAppState>() as _MyAppState).serverUrl;
  String get currentUsername => AppState.loggedInUsername ?? 'Unknown';

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _joinChatRoom(); 
  }

  void _joinChatRoom() {
    if (socket.connected) {
      socket.emit('join_chat', {
        'room_id': widget.roomId,
        'username': currentUsername,
      });
    }
  }

  void _setupSocketListeners() {
    socket.on('receive_message', (data) {
      if (data['room_id'] == widget.roomId) {
        setState(() {
          // Add if sender is not current user OR if it's a SYSTEM message
          if (data['sender'] != currentUsername || data['sender'] == 'SYSTEM') {
             _messages.add(data);
          }
        });
        _scrollToBottom();
      }
    });

    socket.on('message_history', (data) {
      if (data['room_id'] == widget.roomId) {
        setState(() {
          _messages.clear(); 
          for (var msg in data['messages']) {
              _messages.add({
                  'room_id': msg['room_id'],
                  'sender': msg['sender'],
                  'message': msg['message'],
                  'isMe': msg['sender'] == currentUsername,
                  'timestamp': msg['timestamp'] 
              });
          }
        });
        _scrollToBottom();
      }
    });

    socket.on('group_deleted', (data) {
      if (data['room_id'] == widget.roomId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This group has been deleted!'), backgroundColor: Colors.red));
          Navigator.pop(context); 
        }
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final now = DateTime.now();
    final messageData = {
      'room_id': widget.roomId,
      'sender': currentUsername,
      'message': text,
      'isMe': true, 
      'timestamp': now.hour.toString() + ':' + now.minute.toString().padLeft(2, '0') 
    };

    // 1. Instantly update local UI (optimistic update)
    setState(() {
      _messages.add(messageData);
    });
    
    // 2. Emit to the server
    socket.emit('send_message', messageData);
    
    // 3. Clear and scroll
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _handleGroupAction(String action) async {
    final Map<String, dynamic> data = {'room_id': widget.roomId, 'username': currentUsername};
    String endpoint = '';

    if (action == 'leave') {
      endpoint = '/leave_group';
    } else if (action == 'delete') {
      endpoint = '/delete_group';
    } else {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(serverUrl + endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseBody['message'])));
          Navigator.pop(context); // Go back to group list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseBody['message'] ?? 'Action failed'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
  
  void _scrollToBottom() {
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
              onSelected: _handleGroupAction,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'leave', child: Text('Leave Group')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete Group', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      
      body: Column(
        children: <Widget>[
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
    final color = isMe ? const Color(0xFF00C6FF) : (sender == 'SYSTEM' ? Colors.amber[100] : const Color(0xFFE0E0E0));
    final textColor = isMe ? Colors.white : Colors.black;

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && sender != 'SYSTEM' && widget.isGroupChat) // Show sender name for others' messages in group chat
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
          IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF4A00E0)), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment feature not implemented.')));
          }),
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
