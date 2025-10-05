class Group {
  final String name;
  final String number;

  Group({required this.name, required this.number});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['name'],
      number: json['number'],
    );
  }
}
