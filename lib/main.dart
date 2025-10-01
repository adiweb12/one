import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(MyApp());
}

// ⚠️ CHANGE THIS TO YOUR DEPLOYED FLASK SERVER URL
const String SERVER_IP = "onechatjdifivifrrfigiufitxtd6xy.onrender.com";

// Global storage instance for secure token handling
const _storage = FlutterSecureStorage();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Chat',
      theme: ThemeData(
        primaryColor: Colors.blue[900],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}

// ---------------- LOGIN PAGE ----------------
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = true; // Start as loading to check token

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  // Uses flutter_secure_storage to check for a stored token
  Future<void> checkLoginStatus() async {
    try {
      final String? token = await _storage.read(key: 'token');
      final String? username = await _storage.read(key: 'username');

      if (token != null && username != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(username: username, token: token),
          ),
        );
        return;
      }
    } catch (e) {
      print("Error checking secure storage: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter username and password')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var url = Uri.parse("https://$SERVER_IP/login");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        String token = data['token'];

        // --- Store Token and Username SECURELY ---
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'username', value: username);
        // ------------------------------------------

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(username: username, token: token),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue[900],
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'ONE CHAT',
                  style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    hintText: 'username123',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    // FIX 1: Escaped $ for literal character in string
                    hintText: '123\$\%^gkf',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    child: const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      // FIX 2: Correct builder signature
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- SIGN-UP PAGE ----------------
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  void signUp() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (username.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var url = Uri.parse("https://$SERVER_IP/signup");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password, "name": name}),
      );
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) {
        Navigator.pop(context); // Go back to login page
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('SIGN UP')),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: signUp,
                          child: const Text('SIGN UP'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- MAIN PAGE ----------------
class MainPage extends StatefulWidget {
  final String username;
  final String token;
  const MainPage({Key? key, required this.username, required this.token})
      : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/profile");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
      var data = json.decode(response.body);
      if (data['success']) {
        List userGroups = data['groups'] ?? [];
        if (mounted) {
          setState(() {
            groups = userGroups
                .map<Map<String, dynamic>>(
                    (g) => {"name": g['name'], "number": g['number']})
                .toList();
          });
        }
      } else {
        // Token might be invalid/expired, force secure logout
        if (mounted) {
          _forceLogout();
        }
      }
    } catch (e) {
      print("Error fetching groups: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching groups: $e')));
      }
    }
  }

  void _forceLogout() async {
    // Clear token from secure storage
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'username');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route route) => false,
    );
  }

  Future<void> refreshGroups() async => fetchGroups();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Center(child: Text('ONE CHAT')),
        actions: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    // FIX 3: Correct builder signature
                    builder: (context) =>
                        ProfilePage(username: widget.username, token: widget.token)),
              );
              refreshGroups(); // Refresh groups after potentially updating name
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ProfileImage(username: widget.username),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshGroups,
        child: groups.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No groups yet. Tap + to create or join.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  var group = groups[index];
                  return Card(
                    child: ListTile(
                      title: Text(group['name'] as String),
                      subtitle: Text("Group Number: ${group['number']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              groupName: group['name'] as String,
                              username: widget.username,
                              groupNumber: group['number'] as String,
                              token: widget.token,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('GROUP OPTION'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          // FIX 4: Correct builder signature
                          builder: (context) =>
                              CreatePage(username: widget.username, token: widget.token)),
                    );
                    await refreshGroups();
                  },
                  child: const Text('Create New One'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          // FIX 5: Correct builder signature
                          builder: (context) =>
                              JoinPage(username: widget.username, token: widget.token)),
                    );
                    await refreshGroups();
                  },
                  child: const Text('Join Existing'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[900],
      ),
    );
  }
}

// ---------------- CREATE PAGE ----------------
class CreatePage extends StatelessWidget {
  final String username;
  final String token;
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupNumberController = TextEditingController();

  CreatePage({Key? key, required this.username, required this.token})
      : super(key: key);

  void createGroup(BuildContext context) async {
    String groupName = groupNameController.text.trim();
    String groupNumber = groupNumberController.text.trim();

    if (groupName.isEmpty || groupNumber.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    try {
      var url = Uri.parse("https://$SERVER_IP/create_group");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(
            {"token": token, "groupName": groupName, "groupNumber": groupNumber}),
      );
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Center(child: Text('CREATE GROUP')),
          backgroundColor: Colors.blue[900]),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                  labelText: 'GROUP NAME', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: groupNumberController,
              decoration: const InputDecoration(
                  labelText: 'GROUP NUMBER', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => createGroup(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('CREATE'),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- JOIN PAGE ----------------
class JoinPage extends StatelessWidget {
  final String username;
  final String token;
  final TextEditingController groupNumberController = TextEditingController();

  JoinPage({Key? key, required this.username, required this.token})
      : super(key: key);

  void joinGroup(BuildContext context) async {
    String groupNumber = groupNumberController.text.trim();
    if (groupNumber.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter group number')));
      return;
    }

    try {
      var url = Uri.parse("https://$SERVER_IP/join_group");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": token, "groupNumber": groupNumber}),
      );
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Center(child: Text('JOIN GROUP')),
          backgroundColor: Colors.blue[900]),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: groupNumberController,
              decoration: const InputDecoration(
                  labelText: 'GROUP NUMBER', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => joinGroup(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('JOIN'),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- PROFILE PAGE ----------------
class ProfilePage extends StatefulWidget {
  final String username;
  final String token;
  const ProfilePage({Key? key, required this.username, required this.token})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  String? displayedName;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/profile");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
      var data = json.decode(response.body);
      if (data['success']) {
        if (mounted) {
          setState(() {
            displayedName = data['name'] as String?;
            nameController.text = displayedName ?? '';
          });
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching profile: $e')));
      }
    }
  }

  void updateProfile() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/update_profile");
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body:
              json.encode({"token": widget.token, "newName": nameController.text}));
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) {
        if (mounted) {
          setState(() => displayedName = nameController.text);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void logout() async {
    // 1. Send API call to server to delete session record
    try {
      var url = Uri.parse("https://$SERVER_IP/logout");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
    } catch (e) {
      print("Error during server logout: $e");
    }

    // 2. Clear token from secure storage
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'username'); 

    // 3. Navigate back to Login Page and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                  displayedName != null && displayedName!.isNotEmpty
                      ? displayedName![0].toUpperCase()
                      : widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : '',
                  style:
                      const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'NAME', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('UPDATE'),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- PROFILE IMAGE WIDGET ----------------
class ProfileImage extends StatelessWidget {
  final String username;
  const ProfileImage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '',
        style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ---------------- CHAT PAGE ----------------
class ChatPage extends StatefulWidget {
  final String groupName;
  final String username;
  final String groupNumber;
  final String token;

  const ChatPage({
    Key? key,
    required this.groupName,
    required this.username,
    required this.groupNumber,
    required this.token,
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

  @override
  void initState() {
    super.initState();
    fetchMessages().then((_) {
      _scrollToBottom();
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

  Future<void> fetchMessages({bool isPolling = false}) async {
    try {
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupNumber}");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        List<Map<String, dynamic>> newMessages =
            List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);

        if (mounted) {
          bool shouldScroll = newMessages.length > messages.length;

          setState(() {
            messages = newMessages;
          });

          if (shouldScroll) {
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print("Error fetching messages: $e");
      if (!isPolling && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching messages: $e')));
      }
    }
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
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
        messageController.clear();
        await fetchMessages(); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(data['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.blue[900],
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

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[300],
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
                          if (msg['time'] != null)
                            Text(
                              (msg['time'] as String).substring(11, 16),
                              style:
                                  const TextStyle(fontSize: 10, color: Colors.black54),
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
