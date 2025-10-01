// main.dart (Only showing ChatPage and imports - assume other classes are the same)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ⚠️ NEW IMPORT
import 'database_helper.dart'; 


void main() async {
  // Ensure Flutter is initialized before accessing platform services like sqflite
  WidgetsFlutterBinding.ensureInitialized();
  // ⚠️ Ensure the database is initialized as part of the app lifecycle if needed,
  // but lazy initialization in DatabaseHelper is sufficient here.
  runApp(MyApp());
}

// ... (LoginPage, SignUpPage, MainPage, CreatePage, JoinPage, ProfilePage, ProfileImage are unchanged or have minor changes related to imports/MainPage passing creator status) ...

// ---------------- CHAT PAGE ----------------
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
  // ⚠️ MODIFIED: List structure to match local DB format
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  // ⚠️ NEW: Store the last successfully fetched timestamp to prevent fetching old data
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
    // ⚠️ Polling calls fetchMessages, which now handles sync
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

  // ⚠️ NEW: Loads messages from the local SQLite database
  Future<void> _loadLocalMessages() async {
    final localMessages = await DatabaseHelper.instance.getMessages(widget.groupNumber);
    if (mounted) {
      setState(() {
        messages = localMessages;
      });
    }
  }

  // ⚠️ MODIFIED: Synchronizes local and server messages
  Future<void> fetchMessages({bool isPolling = false}) async {
    // Determine the time marker for fetching only new messages
    // For simplicity, we will fetch all messages every time, but compare to local data.
    // A more advanced approach would send the latest local timestamp to the server.
    
    try {
      // 1. Fetch ALL messages from the server (Current server behavior)
      var url = Uri.parse("https://$SERVER_IP/get_messages/${widget.groupNumber}");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"token": widget.token}),
      );
      var data = json.decode(response.body);

      if (data['success']) {
        List<Map<String, dynamic>> serverMessages =
            List<Map<String, dynamic>>.from(data['messages'] as List<dynamic>);

        // 2. Save new messages to local DB
        await DatabaseHelper.instance.bulkInsertMessages(serverMessages.map((msg) => {
          DatabaseHelper.columnGroupNumber: widget.groupNumber,
          DatabaseHelper.columnSender: msg['sender'],
          DatabaseHelper.columnMessage: msg['message'],
          DatabaseHelper.columnTime: msg['time'], // ISO string
          DatabaseHelper.columnIsSynced: 1, // Already synced
        }).toList());

        // 3. Update UI from local DB
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
      } else {
        // Handle server failure, but keep local data
        if (!isPolling && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not sync with server: ${data['message']}')));
        }
      }
    } catch (e) {
      print("Error fetching messages: $e");
      if (!isPolling && mounted) {
        // Display generic error, but local data remains
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Offline or Network Error. Showing local data.')));
      }
    }
  }

  // ⚠️ MODIFIED: Send message now updates local DB first, then server.
  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Prepare message map
    final now = DateTime.now().toUtc().toIso8601String();
    final localMessage = {
      DatabaseHelper.columnGroupNumber: widget.groupNumber,
      DatabaseHelper.columnSender: widget.username,
      DatabaseHelper.columnMessage: text,
      DatabaseHelper.columnTime: now,
      DatabaseHelper.columnIsSynced: 0, // Not yet synced
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
        // and mark the message as synced (though the server's time will likely replace it).
        await fetchMessages(); 
      } else {
        // Server failed. Message remains in local DB with is_synced = 0
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to send to server. Will try to sync later: ${data['message']}')));
        }
      }
    } catch (e) {
      // Network error. Message remains in local DB with is_synced = 0
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Network error. Message saved locally.")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ⚠️ MODIFIED: Leave Group implementation now deletes local messages
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
          // ⚠️ NEW: Delete local group messages
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

  // ⚠️ MODIFIED: Delete Group implementation now deletes local messages
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
          // ⚠️ NEW: Delete local group messages
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

  // Show dialog with group options (unchanged, uses modified leave/delete functions)
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
              // Refresh now calls fetchMessages which syncs and reloads from local DB
              onRefresh: fetchMessages, 
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];
                  bool isMe = (msg['sender'] as String) == widget.username;
                  
                  // ⚠️ Handle cases where the message is only local/not synced
                  bool isPending = (msg[DatabaseHelper.columnIsSynced] ?? 1) == 0; 
                  
                  // Parse the time string
                  final timeString = msg['time'] as String;
                  final displayTime = DateTime.parse(timeString).toLocal().toString().substring(11, 16);


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
