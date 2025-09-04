import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(MyApp());
}

const String SERVER_IP = "test-4udw.onrender.com";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  bool _isLoading = false;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    String? username = await storage.read(key: 'username');
    String? token = await storage.read(key: 'token');

    if (username != null && token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainPage(username: username, token: token),
        ),
      );
    }
  }

  void login() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter username and password')));
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
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'token', value: token);

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MainPage(username: username, token: token)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: EdgeInsets.all(20),
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
                SizedBox(height: 30),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: 'username123',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '123u%^gkf',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          child: Text('LOGIN'),
                        ),
                      ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
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
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      var url = Uri.parse("https://$SERVER_IP/signup");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(
            {"username": username, "password": password, "name": name}),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('SIGN UP')),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: EdgeInsets.all(20),
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
                SizedBox(height: 30),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: signUp,
                          child: Text('SIGN UP'),
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
      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: ${response.statusCode}')));
        }
        return;
      }
      var data = json.decode(response.body);
      if (data['success']) {
        List<dynamic> userGroups = data['groups'] ?? [];
        setState(() {
          groups = userGroups
              .map<Map<String, dynamic>>(
                  (g) => {"name": g['name'], "number": g['number']})
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error fetching groups: $e')));
      }
    }
  }

  Future<void> refreshGroups() async => fetchGroups();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Center(child: Text('ONE')),
        actions: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(
                        username: widget.username, token: widget.token)),
              );
              await refreshGroups();
            },
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: ProfileImage(username: widget.username),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshGroups,
        child: groups.isEmpty
            ? ListView(
                children: [SizedBox(height: 100), Center(child: Text('No groups yet'))],
              )
            : ListView.builder(
                padding: EdgeInsets.all(20),
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
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text('GROUP OPTION'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreatePage(
                              username: widget.username, token: widget.token)),
                    );
                    await refreshGroups();
                  },
                  child: Text('Create New One'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => JoinPage(
                              username: widget.username, token: widget.token)),
                    );
                    await refreshGroups();
                  },
                  child: Text('Join Existing'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
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
          .showSnackBar(SnackBar(content: Text('Fill all fields')));
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
          title: Center(child: Text('CREATE GROUP')),
          backgroundColor: Colors.blue[900]),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                  labelText: 'GROUP NAME', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            TextField(
              controller: groupNumberController,
              decoration: InputDecoration(
                  labelText: 'GROUP NUMBER', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => createGroup(context),
              child: Text('CREATE'),
              style:
                  ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
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
          .showSnackBar(SnackBar(content: Text('Enter group number')));
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
          title: Center(child: Text('JOIN GROUP')),
          backgroundColor: Colors.blue[900]),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: groupNumberController,
              decoration: InputDecoration(
                  labelText: 'GROUP NUMBER', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => joinGroup(context),
              child: Text('JOIN'),
              style:
                  ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
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
  final storage = const FlutterSecureStorage();

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
        setState(() {
          displayedName = data['name'] as String?;
          nameController.text = displayedName ?? '';
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching profile: $e')));
      }
    }
  }

  void updateProfile() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/update_profile");
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({"token": widget.token, "newName": nameController.text}));
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      if (data['success']) setState(() => displayedName = nameController.text);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void logout() async {
    await storage.delete(key: 'username');
    await storage.delete(key: 'token');

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
        title: Text('PROFILE'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                  displayedName != null && displayedName!.isNotEmpty
                      ? displayedName![0].toUpperCase()
                      : '',
                  style:
                      TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                  labelText: 'NAME', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProfile,
              child: Text('UPDATE'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
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
    _timer = Timer.periodic(Duration(seconds: 3), (Timer t) => fetchMessages());
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

  Future<void> fetchMessages() async {
    try {
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupNumber}");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print("Error fetching messages: $e");
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
          "username": widget.username,
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
                padding: EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];
                  bool isMe = (msg['sender'] as String) == widget.username;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['sender'] as String,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 3),
                          Text(msg['message'] as String),
                          if (msg['time'] != null)
                            Text(
                              (msg['time'] as String).substring(11, 16),
                              style:
                                  TextStyle(fontSize: 10, color: Colors.black54),
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
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: sendMessage,
                        child: Icon(Icons.send),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(12),
                          backgroundColor: Colors.blue[900],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
