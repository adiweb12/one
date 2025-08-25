import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// LOGIN PAGE
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  void login() async {
    String username = usernameController.text;
    String password = passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fake login response (DartPad can't call localhost server)
      await Future.delayed(Duration(seconds: 1));
      var data = {"message": "Login Successful"};

      String message = data['message'];

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Login Status'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage(username: username)),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Something went wrong!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'GEEKHOOT',
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
                    hintText: '123\$%^gkf',
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
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// MAIN PAGE
class MainPage extends StatelessWidget {
  final String username;
  const MainPage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[100],
        title: Center(child: Text('ONE')),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blue[900],
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : "?",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ProfilePage(username: username)));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(child: Text('Welcome $username to Main Page!')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('GROUP OPTION'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePage(username: username)));
                  },
                  child: Text('Create New One'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => JoinPage(username: username)));
                  },
                  child: Text('Join To An Existing One'),
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

// CREATE GROUP PAGE
class CreatePage extends StatelessWidget {
  final String username;
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupNumberController = TextEditingController();

  CreatePage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Text(
            'CREATE GROUP',
            style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                labelText: 'GROUP NAME',
                hintText: 'ONE GROUP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: groupNumberController,
              decoration: InputDecoration(
                labelText: 'ENTER YOUR GROUP NUMBER',
                hintText: 'ONEGROUP123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_num),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group Created Successfully')));
              },
              child: Text('CREATE'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}

// JOIN GROUP PAGE
class JoinPage extends StatelessWidget {
  final String username;
  final TextEditingController groupNumberController = TextEditingController();

  JoinPage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Text(
            'JOIN GROUP',
            style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            TextField(
              controller: groupNumberController,
              decoration: InputDecoration(
                labelText: 'GROUP NUMBER',
                hintText: 'ONEGROUP123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_num),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joined Group Successfully')));
              },
              child: Text('JOIN'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}

// PROFILE PAGE
class ProfilePage extends StatelessWidget {
  final String username;
  ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'ONE',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[900],
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : "?",
                style: TextStyle(
                    fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Text(username,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'NAME :',
                hintText: 'ONE.V.S',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('UPDATED SUCCESSFULLY')));
              },
              child: Text('SAVE'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}
