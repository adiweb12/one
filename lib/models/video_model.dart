class VideoModel {
  final int id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail'] ?? '',
      videoUrl: json['video_url'] ?? json['video'] ?? '',
    );
  }
}