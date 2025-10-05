class Message {
  final String sender;
  final String text;
  final DateTime time;

  Message({required this.sender, required this.text, required this.time});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      text: json['message'],
      time: DateTime.parse(json['time']),
    );
  }
}
