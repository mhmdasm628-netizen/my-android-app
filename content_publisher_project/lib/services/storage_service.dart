import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_post.dart';

class StorageService {
  static const String _key = 'user_video_posts_v1';

  static Future<List<VideoPost>> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list == null || list.isEmpty) {
      // Seed with sample post
      return [
        VideoPost(
          id: 'sample_1',
          title: 'أفضل 5 ميزات مخفية في أندرويد 2026',
          description: 'شرح عملي لأهم الميزات والحيل التي ستوفر وقتك في استخدام الهاتف.',
          hashtags: '#shorts #اندرويد #تكنولوجيا #نصائح #viral #fyp',
          publishedTikTok: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        )
      ];
    }
    return list.map((item) => VideoPost.fromJson(item)).toList();
  }

  static Future<void> savePosts(List<VideoPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = posts.map((p) => p.toJson()).toList();
    await prefs.setStringList(_key, list);
  }
}
