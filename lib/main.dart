// main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart'; 
import 'database_helper.dart'; // Assuming this file is in the same directory

// -------------------- CONSTANTS --------------------
// NOTE: Use the provided server link
const String SERVER_IP = "one-music-1dmn.onrender.com"; 
const FlutterSecureStorage storage = FlutterSecureStorage();

// -------------------- MAIN --------------------

void main() async {
  // Ensure Flutter is initialized before accessing platform services like sqflite
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneChat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthChecker(), // Start with AuthChecker for permanent login
    );
  }
}

// -------------------- AUTH CHECKER (Permanent Login) --------------------

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> _checkLoginStatus() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // If logged in, go to MainPage, else go to LoginPage
        if (snapshot.data == true) {
          return const MainPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// -------------------- 🔑 LOGIN/SIGNUP PAGES --------------------

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final url = Uri.parse("https://$SERVER_IP/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password}),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        await storage.write(key: 'token', value: data['token']);
        await storage.write(key: 'username', value: username);
        if (mounted) {
          // Use pushReplacement to clear the login history
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed: ${data['message']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      // ⚠️ FIX: Replace Center with Padding and wrap the Center widget
      body: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: const Text('Login')),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                },
                child: const Text('Need an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    final username = _usernameController.text;
    final password = _passwordController.text;
    final name = _nameController.text;

    try {
      final url = Uri.parse("https://$SERVER_IP/signup");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password, "name": name}),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signup successful! Please log in.')));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signup failed: ${data['message']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      // ⚠️ FIX: Replace Center with Padding and wrap the Center widget
      body: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name/Alias')),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password (min 6 chars)'), obscureText: true),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- 🏠 MAIN PAGE --------------------

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _username = '';
  String _name = '';
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'token');
    final username = await storage.read(key: 'username');

    if (token == null || username == null) {
      if (mounted) {
        // If token is somehow lost here, redirect to login
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
      return;
    }

    try {
      final url = Uri.parse("https://$SERVER_IP/profile");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token}),
      );

      final data = json.decode(response.body);
      
      if (data['success']) {
        if (mounted) {
          setState(() {
            _username = data['username'];
            _name = data['name'];
            _groups = List<Map<String, dynamic>>.from(data['groups']);
          });
        }
      } else {
        // Token expired or invalid, log user out
        await storage.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Session expired: ${data['message']}. Please log in.')));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error loading profile. Showing cached data if available.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final token = await storage.read(key: 'token');
    try {
      final url = Uri.parse("https://$SERVER_IP/logout");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token}),
      );
    } catch (e) {
      print("Logout error (ignored): $e");
    }

    await storage.deleteAll();
    if (mounted) {
      // Navigate to Login and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (Route<dynamic> route) => false
      );
    }
  }
  
  void _navigateToChat(Map<String, dynamic> group) async {
    final token = await storage.read(key: 'token');
    // The chat page returns true if the group was left/deleted and main page needs to refresh
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          groupName: group['name'],
          username: _username,
          groupNumber: group['number'],
          token: token!,
          isCreator: group['is_creator'],
        ),
      ),
    );

    if (shouldRefresh == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneChat - Your Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              // Navigate to profile and refresh groups on return
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ProfilePage(username: _username, name: _name)),
              );
              _loadProfile();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfile),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ListTile(
                    leading: Icon(group['is_creator'] ? Icons.shield : Icons.group),
                    title: Text(group['name']),
                    subtitle: Text('ID: ${group['number']}'),
                    onTap: () => _navigateToChat(group),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "createGroup",
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePage()));
              _loadProfile();
            },
            label: const Text('Create'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "joinGroup",
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinPage()));
              _loadProfile();
            },
            label: const Text('Join'),
            icon: const Icon(Icons.group_add),
          ),
        ],
      ),
    );
  }
}

// -------------------- CREATE GROUP PAGE --------------------

class CreatePage extends StatefulWidget {
  const CreatePage({Key? key}) : super(key: key);
  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createGroup() async {
    setState(() => _isLoading = true);
    final groupName = _nameController.text.trim();
    final groupNumber = _numberController.text.trim();
    final token = await storage.read(key: 'token');

    if (groupName.isEmpty || groupNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("https://$SERVER_IP/create_group");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "token": token, 
          "groupName": groupName, 
          "groupNumber": groupNumber
        }),
      );

      final data = json.decode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        if (data['success']) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      // ⚠️ FIX: Replace Center with Padding and wrap the Center widget
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Group Name')),
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Unique Group ID (e.g., G12345)')),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _createGroup, child: const Text('Create Group')),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- JOIN GROUP PAGE --------------------

class JoinPage extends StatefulWidget {
  const JoinPage({Key? key}) : super(key: key);
  @override
  _JoinPageState createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController _numberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinGroup() async {
    setState(() => _isLoading = true);
    final groupNumber = _numberController.text.trim();
    final token = await storage.read(key: 'token');

    if (groupNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Group ID!')));
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("https://$SERVER_IP/join_group");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "groupNumber": groupNumber}),
      );

      final data = json.decode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        if (data['success']) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      // ⚠️ FIX: Replace Center with Padding and wrap the Center widget
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Group ID to Join')),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _joinGroup, child: const Text('Join Group')),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- PROFILE PAGE --------------------

class ProfilePage extends StatefulWidget {
  final String username;
  final String name;

  const ProfilePage({Key? key, required this.username, required this.name}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final newName = _nameController.text.trim();
    final token = await storage.read(key: 'token');

    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty!')));
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("https://$SERVER_IP/update_profile");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "newName": newName}),
      );

      final data = json.decode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        if (data['success']) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        // ⚠️ FIX: The original code had a Padding error here, but it was just a style error.
        // It should be Padding around a Column/ListView, not Center(padding:...)
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${widget.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _updateProfile, child: const Text('Update Profile')),
          ],
        ),
      ),
    );
  }
}


// -------------------- CHAT PAGE --------------------
class ChatPage extends StatefulWidget {
  final String groupName;
  final String username;
  final String groupNumber;
  final String token;
  final bool isCreator; 

  const ChatPage({
    Key? key,
    required this.groupName,
    required this.username,
    required this.groupNumber,
    required this.token,
    required this.isCreator,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  // Store the last successfully fetched timestamp to prevent fetching old data
  DateTime? _lastSyncedTime; 

  @override
  void initState() {
    super.initState();
    // 1. Load messages from local database immediately
    _loadLocalMessages().then((_) {
      // 2. Then, fetch new messages from the server
      fetchMessages().then((_) {
        _scrollToBottom();
      });
    });
    
    // Set up timer for polling every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer t) => fetchMessages(isPolling: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Loads messages from the local SQLite database
  Future<void> _loadLocalMessages() async {
    final localMessages = await DatabaseHelper.instance.getMessages(widget.groupNumber);
    if (mounted) {
      setState(() {
        messages = localMessages;
      });
    }
  }

  // Synchronizes local and server messages
  Future<void> fetchMessages({bool isPolling = false}) async {
    
    String? lastTimeISO;
    if (_lastSyncedTime != null) {
      // Convert the last successful sync time to ISO 8601 UTC string
      lastTimeISO = _lastSyncedTime!.toUtc().toIso8601String();
    }
    
    try {
      // 1. Fetch messages from the server
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupNumber}");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        // Pass the latest sync time to the server for incremental sync
        body: json.encode({"token": widget.token, "last_synced_time": lastTimeISO}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        List<Map<String, dynamic>> serverMessages =
            List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);

        if (serverMessages.isNotEmpty) {
           // Find the maximum time from the fetched messages and update the marker
           final maxTime = serverMessages
               .map((m) => DateTime.parse(m['time']))
               .reduce((a, b) => a.isAfter(b) ? a : b);
               
           _lastSyncedTime = maxTime;


          // 3. Save new messages to local DB
          await DatabaseHelper.instance.bulkInsertMessages(serverMessages.map((msg) => {
            DatabaseHelper.columnGroupNumber: widget.groupNumber,
            DatabaseHelper.columnSender: msg['sender'],
            DatabaseHelper.columnMessage: msg['message'],
            DatabaseHelper.columnTime: msg['time'], // ISO string from server
            DatabaseHelper.columnIsSynced: 1, // Synced
          }).toList());

          // 4. Update UI from local DB
          final localMessages = await DatabaseHelper.instance.getMessages(widget.groupNumber);
          
          if (mounted) {
            bool shouldScroll = localMessages.length > messages.length;

            setState(() {
              messages = localMessages;
            });

            if (shouldScroll) {
              _scrollToBottom();
            }
          }
        }
      } else {
        if (!isPolling && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not sync with server: ${data['message']}')));
        }
      }
    } catch (e) {
      print("Error fetching messages: $e");
      if (!isPolling && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Offline or Network Error. Showing local data.')));
      }
    }
  }

  // Send message now updates local DB first, then server.
  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Prepare message map with local time
    final now = DateTime.now().toUtc().toIso8601String();
    final localMessage = {
      DatabaseHelper.columnGroupNumber: widget.groupNumber,
      DatabaseHelper.columnSender: widget.username,
      DatabaseHelper.columnMessage: text,
      DatabaseHelper.columnTime: now,
      DatabaseHelper.columnIsSynced: 0, // Not yet synced (Pending)
    };

    // 2. Update local DB and UI instantly
    await DatabaseHelper.instance.insertMessage(localMessage);
    messageController.clear();
    await _loadLocalMessages();
    _scrollToBottom();
    
    setState(() => _isLoading = true);

    // 3. Send to server
    try {
      var url = Uri.parse("https://$SERVER_IP/send_message");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "groupNumber": widget.groupNumber,
          "message": text,
          "token": widget.token,
        }),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        // Message sent successfully, force a fetch to get the official server timestamp
        // and mark the message as synced (this avoids having to manually update the local message).
        await fetchMessages(); 
      } else {
        // Server failed. Message remains in local DB with is_synced = 0
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Server failed. Saved locally: ${data['message']}')));
        }
      }
    } catch (e) {
      // Network error. Message remains in local DB with is_synced = 0
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Network error. Message saved locally (pending).")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Leave Group implementation now deletes local messages
  Future<void> leaveGroup() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave'),
        content: const Text('Are you sure you want to leave this group? All local messages for this chat will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LEAVE')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      var url = Uri.parse("https://$SERVER_IP/leave_group");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token, "groupNumber": widget.groupNumber}),
      );
      var data = json.decode(response.body);
      
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
        if (data['success']) {
          // Delete local group messages
          await DatabaseHelper.instance.deleteGroupMessages(widget.groupNumber);
          // Pass true to MainPage to indicate a refresh/removal is needed
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error leaving group: $e')));
      }
    }
  }

  // Delete Group implementation now deletes local messages
  Future<void> deleteGroup() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('WARNING: Are you sure you want to delete this group and all its messages? This action is irreversible. All local messages will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      var url = Uri.parse("https://$SERVER_IP/delete_group");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token, "groupNumber": widget.groupNumber}),
      );
      var data = json.decode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
        if (data['success']) {
          // Delete local group messages
          await DatabaseHelper.instance.deleteGroupMessages(widget.groupNumber);
          // Pass true to MainPage to indicate a refresh/removal is needed
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
      }
    }
  }

  void _showGroupSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Group'),
              onTap: () {
                Navigator.pop(context); // Close dialog
                leaveGroup();
              },
            ),
            if (widget.isCreator) 
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Group (Admin)', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  deleteGroup();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showGroupSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMessages, 
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];
                  bool isMe = (msg['sender'] as String) == widget.username;
                  
                  // Check if the message is only local/not synced
                  bool isPending = (msg[DatabaseHelper.columnIsSynced] ?? 1) == 0; 
                  
                  // Parse the time string
                  final timeString = msg['time'] as String? ?? DateTime.now().toUtc().toIso8601String();
                  String displayTime = '';
                  try {
                    displayTime = DateTime.parse(timeString).toLocal().toString().substring(11, 16);
                  } catch (_) {
                    displayTime = '...'; 
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? (isPending ? Colors.yellow[100] : Colors.blue[100]) // Yellow for pending
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? "You" : (msg['sender'] as String),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(msg['message'] as String),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                displayTime,
                                style:
                                    const TextStyle(fontSize: 10, color: Colors.black54),
                                ),
                                if (isMe && isPending)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Icon(
                                        Icons.access_time, 
                                        size: 10, 
                                        color: Colors.red[800]
                                      ),
                                    )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: sendMessage,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: Colors.blue[900],
                        ),
                        child: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
