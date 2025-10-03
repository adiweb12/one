// main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_helper.dart'; 
// 🌟 NEW IMPORT: Required for GIPHY functionality
import 'package:giphy_get/giphy_get.dart'; 

// -------------------- CONSTANTS --------------------
// NOTE: Use the provided server link
const String SERVER_IP = "one-music-1dmn.onrender.com"; 
const FlutterSecureStorage storage = FlutterSecureStorage();
// 🌟 GIPHY API KEY: Replace the placeholder with your actual key
// const String GIPHY_API_KEY = "YOUR_GIPHY_API_KEY"; 
const String GIPHY_API_KEY = "Bb6tO0TsfIXOz77VFevRStSUpgWy6geO"; 


// -------------------- THEME COLORS --------------------
// Define a modern, deep primary color
final Color primaryColor = Colors.deepPurple.shade700;
final Color secondaryColor = Colors.teal.shade400;

// -------------------- MAIN --------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneChat',
      // Define a modern theme
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple).copyWith(
          secondary: secondaryColor,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: secondaryColor, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        )
      ),
      home: const AuthChecker(),
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
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }
        
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 20),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ElevatedButton(onPressed: _login, child: const Text('Login')),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                },
                child: Text('Need an account? Sign Up', style: TextStyle(color: secondaryColor)),
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
              const SnackBar(content: Text('Signup successful! Please log in.')));
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Your Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 20),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name/Alias')),
              const SizedBox(height: 20),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password (min 6 chars)'), obscureText: true),
              const SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- 🏠 MAIN PAGE (Offline Capable) --------------------

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _username = '';
  String _name = '';
  // 🌟 MODIFIED: Groups now stores unread_count
  List<Map<String, dynamic>> _groups = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalData(); // Load local data first for instant display
    _syncProfileGroupsAndUnreads(); // Then, sync with server
  }
  
  Future<void> _loadLocalData() async {
    final username = await storage.read(key: 'username');
    if (username == null) return;

    final localProfile = await DatabaseHelper.instance.getProfile(username);
    List<Map<String, dynamic>> localGroups = await DatabaseHelper.instance.getGroups();
    
    // 🌟 NEW: Calculate unread count for each group
    List<Map<String, dynamic>> groupsWithUnreads = [];
    for (var group in localGroups) {
        final groupNumber = group['number'] as String;
        final lastReadTime = await DatabaseHelper.instance.getLastReadTime(groupNumber);
        final unreadCount = await DatabaseHelper.instance.getUnreadCount(groupNumber, lastReadTime);
        
        String? latestTime = await DatabaseHelper.instance.getLatestMessageTime(groupNumber);

        groupsWithUnreads.add({
            ...group,
            'unread_count': unreadCount,
            'last_message_time': latestTime,
        });
    }


    if (mounted) {
      setState(() {
        _username = username;
        _name = localProfile?['name'] ?? username; 
        // 🌟 Use the list with unread counts
        _groups = groupsWithUnreads; 
        _isLoading = false; 
      });
    }
  }

  Future<void> _syncProfileGroupsAndUnreads({bool forceLoading = false}) async {
    if (forceLoading) setState(() => _isLoading = true);
    
    final token = await storage.read(key: 'token');
    final username = await storage.read(key: 'username');

    if (token == null || username == null) {
      if (mounted) {
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
          // 1. Save profile to local DB
          await DatabaseHelper.instance.saveProfile(data['username'], data['name']);

          // 2. Save groups to local DB
          List<Map<String, dynamic>> serverGroups = List<Map<String, dynamic>>.from(data['groups']);
          await DatabaseHelper.instance.saveGroups(serverGroups);
          
          // 3. Reload UI from local DB (for consistency and to calculate unread counts)
          await _loadLocalData();
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
      if (mounted && !forceLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offline. Showing cached groups.')));
      }
    } finally {
      if (mounted && forceLoading) setState(() => _isLoading = false);
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
      _syncProfileGroupsAndUnreads(forceLoading: true);
    } else {
      // 🌟 REFRESH: If chat page didn't delete the group, refresh to update unread count
      _loadLocalData(); 
    }
  }

  // Moved _logout logic to ProfilePage, but keep this utility function for the profile page to call
  Future<void> logout() async {
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
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (Route<dynamic> route) => false
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneChat - Your Groups'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _syncProfileGroupsAndUnreads(forceLoading: true)),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ProfilePage(
                  username: _username, 
                  name: _name,
                  onLogout: logout, // Pass the logout function
                )),
              );
              // Refresh groups and profile name on return
              _syncProfileGroupsAndUnreads(forceLoading: true); 
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: () => _syncProfileGroupsAndUnreads(forceLoading: true),
              child: _groups.isEmpty
                  ? Center(
                      child: Text(
                        'No groups yet. Join or create one!',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(15.0),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        final isCreator = group['is_creator'] as bool;
                        // 🌟 NEW: Get unread count
                        final unreadCount = group['unread_count'] as int; 
                        final lastMessageTime = group['last_message_time'] as String?;
                        
                        String displayTime = '';
                        if(lastMessageTime != null) {
                            try {
                                displayTime = DateTime.parse(lastMessageTime).toLocal().toString().substring(11, 16);
                            } catch (_) {
                                displayTime = '';
                            }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 8, // Higher elevation for modern look
                            shadowColor: primaryColor.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell( 
                              onTap: () => _navigateToChat(group),
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: isCreator ? secondaryColor : primaryColor,
                                      child: Icon(
                                        isCreator ? Icons.star_border : Icons.group,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                              children: [
                                                  Text(
                                                      group['name'],
                                                      style: const TextStyle(
                                                          fontSize: 19,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (unreadCount > 0) 
                                                      Padding(
                                                          padding: const EdgeInsets.only(left: 8.0),
                                                          // 🌟 NEW: Unread count badge
                                                          child: Chip( 
                                                              label: Text(
                                                                  unreadCount.toString(),
                                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                              ),
                                                              backgroundColor: Colors.red.shade600,
                                                              padding: EdgeInsets.zero,
                                                          ),
                                                      ),
                                              ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                  Text(
                                                      'ID: ${group['number']}',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                      ),
                                                  ),
                                                  // Display time of last message
                                                  if (displayTime.isNotEmpty)
                                                      Text(
                                                          displayTime,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: unreadCount > 0 ? Colors.red.shade600 : Colors.grey[500],
                                                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                                          ),
                                                      ),
                                              ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "createGroup",
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePage()));
              _syncProfileGroupsAndUnreads(forceLoading: true);
            },
            label: const Text('Create Group'),
            icon: const Icon(Icons.add),
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "joinGroup",
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinPage()));
              _syncProfileGroupsAndUnreads(forceLoading: true);
            },
            label: const Text('Join Group'),
            icon: const Icon(Icons.group_add),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Group Setup',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Group Name')),
              const SizedBox(height: 20),
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Unique Group ID (e.g., G12345)')),
              const SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Group ID',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Group ID to Join')),
              const SizedBox(height: 40),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ElevatedButton(onPressed: _joinGroup, child: const Text('Join Group')),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- PROFILE PAGE (Merged Logout) --------------------

class ProfilePage extends StatefulWidget {
  final String username;
  final String name;
  final VoidCallback onLogout; // Callback function for logout

  const ProfilePage({Key? key, required this.username, required this.name, required this.onLogout}) : super(key: key);

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
          await DatabaseHelper.instance.saveProfile(widget.username, newName);
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
      appBar: AppBar(title: const Text('Profile Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: secondaryColor,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Username: ${widget.username}', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const Divider(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : ElevatedButton(
                    onPressed: _updateProfile, 
                    child: const Text('Update Profile'),
                  ),
            
            const SizedBox(height: 50),

            // Logout Button (Merged from MainPage)
            ElevatedButton.icon(
              onPressed: () {
                // Show confirmation dialog before logging out
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: primaryColor))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          widget.onLogout(); // Execute the logout function
                        }, 
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// -------------------- CHAT PAGE (Outbox/Sync Logic) --------------------
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
  DateTime? _lastSyncedTime; 
  
  // 🌟 MODIFIED: Updated check to include GIPHY domain
  bool _isMedia(String message) {
    return message.toLowerCase().startsWith('http') && 
           (message.toLowerCase().contains('.gif') || 
            message.toLowerCase().contains('.png') ||
            message.toLowerCase().contains('.jpg') ||
            message.toLowerCase().contains('giphy.com')); // Check for GIPHY links
  }

  @override
  void initState() {
    super.initState();
    _loadLocalMessages().then((_) {
      _syncMessages().then((_) { 
        _scrollToBottom();
        // 🌟 NEW: Mark group as read immediately on opening chat
        _markGroupAsRead(); 
      });
    });
    
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer t) => _syncMessages(isPolling: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // 🌟 NEW: Mark group as read
  Future<void> _markGroupAsRead() async {
      // Use the latest message time from the server sync as the last read time, 
      // or current time if no messages or sync hasn't completed.
      final latestTime = messages.isNotEmpty 
          ? DateTime.parse(messages.last[DatabaseHelper.columnTime] as String) 
          : DateTime.now();
      
      await DatabaseHelper.instance.setLastReadTime(widget.groupNumber, latestTime);
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadLocalMessages() async {
    final localMessages = await DatabaseHelper.instance.getMessages(widget.groupNumber);
    if (mounted) {
      setState(() {
        messages = localMessages;
      });
    }
  }
  
  // --- OUTBOX PROCESSING (Local -> Server) ---
  Future<void> _processOutbox({bool isPolling = false}) async {
      final pendingMessages = await DatabaseHelper.instance.getPendingMessages(widget.groupNumber);
      
      if (pendingMessages.isEmpty) return;
      
      if (!isPolling) {
          if (mounted) setState(() => _isLoading = true);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attempting to sync ${pendingMessages.length} pending messages...')));
      }

      try {
          final url = Uri.parse("https://$SERVER_IP/send_message");
          final db = await DatabaseHelper.instance.database;

          await db.transaction((txn) async {
              for (var msg in pendingMessages) {
                  final response = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: json.encode({
                          "groupNumber": widget.groupNumber,
                          "message": msg[DatabaseHelper.columnMessage],
                          "token": widget.token,
                      }),
                  );
                  final data = json.decode(response.body);

                  if (data['success']) {
                      await txn.update(
                          DatabaseHelper.tableName,
                          {
                            DatabaseHelper.columnIsSynced: 1, 
                            DatabaseHelper.columnTime: data['time'] 
                          },
                          where: '${DatabaseHelper.columnId} = ?',
                          whereArgs: [msg[DatabaseHelper.columnId]],
                      );
                  } else {
                      print('Outbox sync failed for message ID ${msg[DatabaseHelper.columnId]}: ${data['message']}');
                  }
              }
          });
          
          await _loadLocalMessages(); 
          
          // 🌟 NEW: Mark as read after sending local message (since it's now synced/latest)
          _markGroupAsRead(); 

      } catch (e) {
          print("Outbox sync network error: $e");
      } finally {
          if (!isPolling && mounted) setState(() => _isLoading = false);
      }
  }


  // --- INBOX PROCESSING (Server -> Local) ---
  Future<void> _syncIncomingMessages({bool isPolling = false}) async {
    String? lastTimeISO;
    if (_lastSyncedTime != null) {
      lastTimeISO = _lastSyncedTime!.toUtc().toIso8601String();
    }
    
    try {
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupNumber}");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token, "last_synced_time": lastTimeISO}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        List<Map<String, dynamic>> serverMessages =
            List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);

        if (serverMessages.isNotEmpty) {
           final maxTime = serverMessages
               .map((m) => DateTime.parse(m['time']))
               .reduce((a, b) => a.isAfter(b) ? a : b);
               
           _lastSyncedTime = maxTime;

          await DatabaseHelper.instance.bulkInsertMessages(serverMessages.map((msg) => {
            DatabaseHelper.columnGroupNumber: widget.groupNumber,
            DatabaseHelper.columnSender: msg['sender'],
            DatabaseHelper.columnMessage: msg['message'],
            DatabaseHelper.columnTime: msg['time'],
            DatabaseHelper.columnIsSynced: 1, 
          }).toList());

          final localMessages = await DatabaseHelper.instance.getMessages(widget.groupNumber);
          
          if (mounted) {
            bool shouldScroll = localMessages.length > messages.length;

            setState(() {
              messages = localMessages;
            });

            if (shouldScroll) {
              _scrollToBottom();
              // 🌟 NEW: Mark as read whenever new messages are fetched
              _markGroupAsRead(); 
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

  Future<void> _syncMessages({bool isPolling = false}) async {
    await _processOutbox(isPolling: isPolling);
    await _syncIncomingMessages(isPolling: isPolling);
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final localMessage = {
      DatabaseHelper.columnGroupNumber: widget.groupNumber,
      DatabaseHelper.columnSender: widget.username,
      DatabaseHelper.columnMessage: text,
      DatabaseHelper.columnTime: now,
      DatabaseHelper.columnIsSynced: 0, 
    };

    await DatabaseHelper.instance.insertMessage(localMessage);
    messageController.clear();
    await _loadLocalMessages();
    _scrollToBottom();
    
    await _syncMessages(); 
  }
  
  // 🌟 CORE GIF INTEGRATION LOGIC
  Future<void> _sendSpecialMessage(String content) async {
    final now = DateTime.now().toUtc().toIso8601String();
    
    final localMessage = {
      DatabaseHelper.columnGroupNumber: widget.groupNumber,
      DatabaseHelper.columnSender: widget.username,
      DatabaseHelper.columnMessage: content, 
      DatabaseHelper.columnTime: now,
      DatabaseHelper.columnIsSynced: 0, 
    };

    await DatabaseHelper.instance.insertMessage(localMessage);
    await _loadLocalMessages();
    _scrollToBottom();
    await _syncMessages();
  }

  // 🌟 FUNCTIONAL GIF SELECTOR
  void _showGifStickerSelection() async {
    // Check if the API key is set before proceeding
    if (GIPHY_API_KEY.isEmpty || GIPHY_API_KEY == "YOUR_GIPHY_API_KEY") {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ GIPHY_API_KEY not set! Cannot open GIF picker.')),
        );
        return;
    }
    
    // Use the GiphyGet package to open the GIF selection screen
    GiphyGif? gif = await GiphyGet.getGif(
        context: context,
        apiKey: GIPHY_API_KEY, 
        tabColor: primaryColor,
        //showAttribution: false,
      //  fullScreenDialog: true,
        // Request only GIF media type
       // mediaType: GiphyMediaType.gif, 
    );
    
    if (gif != null && gif.images?.original?.url != null) {
      // Send the high-resolution original GIF URL as a message
      _sendSpecialMessage(gif.images!.original!.url!); 
    }
  }


  Future<void> leaveGroup() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave'),
        content: const Text('Are you sure you want to leave this group? All local data for this chat will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: primaryColor))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LEAVE', style: TextStyle(color: Colors.red))),
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
          await DatabaseHelper.instance.deleteGroupMessages(widget.groupNumber);
          await DatabaseHelper.instance.deleteGroupMetadata(widget.groupNumber);
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

  Future<void> deleteGroup() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('WARNING: Are you sure you want to delete this group and all its messages? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: primaryColor))),
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
          await DatabaseHelper.instance.deleteGroupMessages(widget.groupNumber);
          await DatabaseHelper.instance.deleteGroupMetadata(widget.groupNumber);
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
        title: Text('${widget.groupName} Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Group'),
              onTap: () {
                Navigator.pop(context); 
                leaveGroup();
              },
            ),
            if (widget.isCreator) 
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Group (Admin)', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); 
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
              onRefresh: _syncMessages, 
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];
                  bool isMe = (msg['sender'] as String) == widget.username;
                  bool isPending = (msg[DatabaseHelper.columnIsSynced] ?? 1) == 0; 
                  String content = msg['message'] as String;
                  bool isMediaMessage = _isMedia(content);
                  
                  final timeString = msg['time'] as String? ?? DateTime.now().toUtc().toIso8601String();
                  String displayTime = '';
                  try {
                    displayTime = DateTime.parse(timeString).toLocal().toString().substring(11, 16);
                  } catch (_) {
                    displayTime = '...'; 
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? (isPending ? secondaryColor.withOpacity(0.5) : primaryColor.withOpacity(0.8))
                            : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isMe ? 12 : 0),
                          topRight: Radius.circular(isMe ? 0 : 12),
                          bottomLeft: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg['sender'] as String,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          if (!isMe) const SizedBox(height: 3),
                          
                          // RENDER MEDIA: Display the GIF using Image.network
                          if (isMediaMessage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                content,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: isMe ? Colors.white : primaryColor,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Text('Failed to load media.', style: TextStyle(color: isMe ? Colors.white : Colors.red));
                                },
                                width: 150,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Text(
                              content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
                            ),
                            
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                displayTime,
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // 🌟 GIF Button calling the functional selector
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined),
                  color: primaryColor,
                  onPressed: _showGifStickerSelection,
                  tooltip: 'Send GIF/Sticker',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null, 
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[100],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : FloatingActionButton(
                        onPressed: sendMessage,
                        heroTag: 'sendBtn',
                        backgroundColor: primaryColor,
                        mini: true,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
