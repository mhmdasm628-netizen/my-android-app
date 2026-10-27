import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'models/video_post.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContentPublisherApp());
}

class ContentPublisherApp extends StatelessWidget {
  const ContentPublisherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ناشر المحتوى الذكي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF8B5CF6),
          secondary: const Color(0xFF6366F1),
          surface: const Color(0xFF131B2E),
        ),
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VideoPost> _posts = [];
  String _filter = 'all'; // all, pending, completed
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loaded = await StorageService.loadPosts();
    setState(() {
      _posts = loaded;
      _loading = false;
    });
  }

  Future<void> _saveData() async {
    await StorageService.savePosts(_posts);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<VideoPost> get _filteredPosts {
    return _posts.where((p) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final match = p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.hashtags.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_filter == 'pending') return !p.isCompleted;
      if (_filter == 'completed') return p.isCompleted;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _posts.length;
    final completed = _posts.where((p) => p.isCompleted).length;
    final pending = total - completed;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.purple, Colors.indigo]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.video_library_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ناشر المحتوى الذكي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text('تيك توك • يوتيوب • فيسبوك', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة فيديو', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _openPostDialog(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Metrics Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      _buildMetricCard('إجمالي الفيديوهات', total.toString(), Colors.purpleAccent),
                      const SizedBox(width: 8),
                      _buildMetricCard('بحاجة للنشر', pending.toString(), Colors.amberAccent),
                      const SizedBox(width: 8),
                      _buildMetricCard('مكتمل بالكامل', completed.toString(), Colors.greenAccent),
                    ],
                  ),
                ),

                // Search & Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث في العنوان أو الهاشتاجات...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF131B2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (val) => setState(() => _search = val),
                  ),
                ),
                const SizedBox(height: 8),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'الكل'),
                      const SizedBox(width: 6),
                      _buildFilterChip('pending', 'قيد النشر'),
                      const SizedBox(width: 6),
                      _buildFilterChip('completed', 'مكتمل (3/3)'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Feed
                Expanded(
                  child: _filteredPosts.isEmpty
                      ? const Center(
                          child: Text('لا توجد فيديوهات مطابقة للبحث', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            return _buildPostCard(post);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final active = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      selected: active,
      selectedColor: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFF131B2E),
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildPostCard(VideoPost post) {
    final progress = post.publishedCount / 3.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd • hh:mm a').format(post.createdAt),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                  onPressed: () => _openPostDialog(existing: post),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => _posts.removeWhere((p) => p.id == post.id));
                    _saveData();
                    _showToast('تم حذف الفيديو بنجاح');
                  },
                ),
              ],
            ),

            if (post.videoPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.movie_creation_outlined, size: 16, color: Colors.purpleAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ملف محلي: ${post.videoPath!.split("/").last}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Description & Hashtags
            if (post.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.description, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
            if (post.hashtags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(post.hashtags, style: const TextStyle(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 8),
            // Copy Full Text Button
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('نسخ العنوان والهاشتاجات', style: TextStyle(fontSize: 11)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: post.fullText));
                _showToast('تم نسخ العنوان والهاشتاجات للحافظة! 📋');
              },
            ),

            const SizedBox(height: 10),
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.greenAccent : const Color(0xFF7C3AED)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 12),
            // Platforms 3-in-a-row
            Row(
              children: [
                // YouTube
                Expanded(
                  child: _buildPlatformButton(
                    name: 'يوتيوب',
                    icon: Icons.play_arrow_rounded,
                    color: Colors.redAccent,
                    published: post.publishedYouTube,
                    onToggle: (val) {
                      setState(() => post.publishedYouTube = val);
                      _saveData();
                    },
                    onOpen: () async {
                      Clipboard.setData(ClipboardData(text: post.fullText));
                      _showToast('تم نسخ العنوان! جاري فتح يوتيوب...');
                      final uri = Uri.parse('https://m.youtube.com/upload');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Facebook
                Expanded(
                  child: _buildPlatformButton(
                    name: 'فيسبوك',
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                    published: post.publishedFacebook,
                    onToggle: (val) {
                      setState(() => post.publishedFacebook = val);
                      _saveData();
                    },
                    onOpen: () async {
                      Clipboard.setData(ClipboardData(text: post.fullText));
                      _showToast('تم نسخ النص والهاشتاجات! الصقها داخل فيسبوك');
                      final uri = Uri.parse('https://m.facebook.com/composer/');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // TikTok
                Expanded(
                  child: _buildPlatformButton(
                    name: 'تيك توك',
                    icon: Icons.music_note,
                    color: Colors.cyanAccent,
                    published: post.publishedTikTok,
                    onToggle: (val) {
                      setState(() => post.publishedTikTok = val);
                      _saveData();
                    },
                    onOpen: () async {
                      Clipboard.setData(ClipboardData(text: '${post.title} ${post.hashtags}'));
                      _showToast('تم نسخ العنوان والهاشتاجات! جاري فتح تيك توك...');
                      final uri = Uri.parse('https://www.tiktok.com/upload');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Native Share Sheet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share, size: 16, color: Colors.purpleAccent),
                label: const Text('مشاركة الفيديو عبر قائمة أندرويد الرسمية (Share)', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () {
                  if (post.videoPath != null) {
                    Share.shareXFiles([XFile(post.videoPath!)], text: post.fullText);
                  } else {
                    Share.share(post.fullText);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton({
    required String name,
    required IconData icon,
    required Color color,
    required bool published,
    required ValueChanged<bool> onToggle,
    required VoidCallback onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: published ? Colors.green.withOpacity(0.15) : Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: published ? Colors.greenAccent.withOpacity(0.4) : Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Checkbox(
                value: published,
                activeColor: Colors.greenAccent,
                checkColor: Colors.black,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (val) => onToggle(val ?? false),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: published ? Colors.white12 : color.withOpacity(0.8),
              minimumSize: const Size(double.infinity, 30),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onOpen,
            child: Text(
              published ? 'فتح $name' : 'نشر على $name',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: published ? Colors.white70 : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _openPostDialog({VideoPost? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final tagsCtrl = TextEditingController(text: existing?.hashtags ?? '');
    String? pickedVideoPath = existing?.videoPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'إضافة فيديو جديد' : 'تعديل الفيديو',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),

                    // Pick video button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.video_file, color: Colors.purpleAccent),
                      label: Text(pickedVideoPath == null ? 'اختر ملف الفيديو من جهازك' : 'تم اختيار: ${pickedVideoPath!.split("/").last}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(type: FileType.video);
                        if (res != null && res.files.single.path != null) {
                          setModalState(() {
                            pickedVideoPath = res.files.single.path;
                            if (titleCtrl.text.isEmpty) {
                              titleCtrl.text = res.files.single.name.replaceAll(RegExp(r'\.[^/.]+$'), '');
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'عنوان الفيديو *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'الوصف أو الملاحظات',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: tagsCtrl,
                      decoration: InputDecoration(
                        labelText: 'الهاشتاجات (مثال: #shorts #viral)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick tag chips
                    Wrap(
                      spacing: 6,
                      children: ['#shorts', '#reels', '#tiktok', '#viral', '#محتوى_عربي'].map((tag) {
                        return ActionChip(
                          label: Text(tag, style: const TextStyle(fontSize: 10)),
                          onPressed: () {
                            if (!tagsCtrl.text.contains(tag)) {
                              tagsCtrl.text = (tagsCtrl.text + ' ' + tag).trim();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حفظ الفيديو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) {
                          _showToast('يرجى إدخال عنوان للفيديو');
                          return;
                        }
                        if (existing == null) {
                          _posts.insert(
                            0,
                            VideoPost(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              hashtags: tagsCtrl.text.trim(),
                              videoPath: pickedVideoPath,
                              createdAt: DateTime.now(),
                            ),
                          );
                        } else {
                          existing.title = titleCtrl.text.trim();
                          existing.description = descCtrl.text.trim();
                          existing.hashtags = tagsCtrl.text.trim();
                          existing.videoPath = pickedVideoPath;
                        }
                        _saveData();
                        setState(() {});
                        Navigator.pop(ctx);
                        _showToast('تم حفظ الفيديو بنجاح! ✅');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
