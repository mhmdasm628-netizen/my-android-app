import 'dart:convert';

class VideoPost {
  final String id;
  String title;
  String description;
  String hashtags;
  String? videoPath;
  String? thumbnailPath;
  bool publishedYouTube;
  bool publishedFacebook;
  bool publishedTikTok;
  final DateTime createdAt;

  VideoPost({
    required this.id,
    required this.title,
    this.description = '',
    this.hashtags = '',
    this.videoPath,
    this.thumbnailPath,
    this.publishedYouTube = false,
    this.publishedFacebook = false,
    this.publishedTikTok = false,
    required this.createdAt,
  });

  int get publishedCount =>
      (publishedYouTube ? 1 : 0) +
      (publishedFacebook ? 1 : 0) +
      (publishedTikTok ? 1 : 0);

  bool get isCompleted => publishedCount == 3;

  String get fullText => '$title\n\n$description\n\n$hashtags'.trim();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hashtags': hashtags,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'publishedYouTube': publishedYouTube,
      'publishedFacebook': publishedFacebook,
      'publishedTikTok': publishedTikTok,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VideoPost.fromMap(Map<String, dynamic> map) {
    return VideoPost(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      hashtags: map['hashtags'] ?? '',
      videoPath: map['videoPath'],
      thumbnailPath: map['thumbnailPath'],
      publishedYouTube: map['publishedYouTube'] ?? false,
      publishedFacebook: map['publishedFacebook'] ?? false,
      publishedTikTok: map['publishedTikTok'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());
  factory VideoPost.fromJson(String source) => VideoPost.fromMap(json.decode(source));
}
