import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'auth_page.dart';
import 'profile_page.dart';
import 'change_password_page.dart';
import 'fanfic_page.dart';
import 'vocab_page.dart';
import 'favorites_page.dart';
import 'Writefiction_page.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart'; // ใส่ชื่อไฟล์ provider ของคุณให้ถูกนะ
import 'chat.dart';
// import 'detail_page.dart';
// import 'chat_read_page.dart'; // อย่าลืม import ไฟล์ที่มี DetailPage และ ChatReadPage ของคุณเข้ามาด้วยนะครับ

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg = Color(0xFF080C14);
const _surface = Color(0xFF0F1520);
const _card = Color(0xFF141C2E);
const _accent = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim = Color(0xFFE8F0FF);
const _textSub = Color(0xFF6B7FA3);
const _divider = Color(0xFF1E2A42);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  int _currentIndex = 0;
  String? fullName;
  String? avatarUrl;

  // ✅ สร้าง Key สำหรับหน้า Vocab
  Key _vocabKey = UniqueKey();
  Key _fanficKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void _onPublishSuccess() {
    setState(() {
      _currentIndex = 1;
      _fanficKey = UniqueKey();
    });
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data != null && mounted) {
      setState(() {
        fullName = data['full_name'];
        avatarUrl = data['avatar_url'];
      });
    }
  }

  void _showProfileMenu(BuildContext context) {
    final user = supabase.auth.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _accent, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: _surface,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(
                                Icons.person_outline_rounded,
                                color: _textSub,
                                size: 26,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName ?? "My Profile",
                            style: const TextStyle(
                              color: _textPrim,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? "",
                            style: const TextStyle(
                              color: _textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: _divider, height: 1),
              _MenuTile(
                icon: Icons.person_outline_rounded,
                label: "แก้ไขโปรไฟล์",
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                  loadProfile();
                },
              ),
              _MenuTile(
                icon: Icons.lock_outline_rounded,
                label: "เปลี่ยนรหัสผ่าน",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
                },
              ),
              const Divider(color: _divider, height: 1),
              _MenuTile(
                icon: Icons.logout_rounded,
                label: "ออกจากระบบ",
                isRed: true,
                onTap: () async {
                  Navigator.pop(context);
                  await supabase.auth.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันจัดการตอนเปลี่ยนแท็บ
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      // ถ้ากดแท็บ 2 (หน้า Vocab) ให้สร้าง Key ใหม่เพื่อรีเซ็ตหน้าจอ
      if (index == 2) {
        _vocabKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          "Fanfic",
          style: TextStyle(
            color: _textPrim,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showProfileMenu(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 10),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _card,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: _textSub,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeScreen(),
          FanficPage(key: _fanficKey),
          VocabPage(key: _vocabKey), // ✅ เอา _vocabKey มาใส่ให้หน้านี้
          const FavoritesPage(),
          WriteFicHubPage(onPublishSuccess: _onPublishSuccess),
        ],
      ),
      // ✅ 1. เพิ่มปุ่มลอย (Floating Action Button) ตรงนี้ครับ!
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // สั่งให้เปลี่ยนไปหน้า ChatBot เมื่อกดปุ่ม
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (context) =>
                    ChatProvider(), // ✅ สร้าง Provider จังหวะเปิดหน้า
                child: const SenseiChatScreen(),
              ),
            ),
          );
        },
        backgroundColor: _accent, // ใช้สีฟ้าธีมแอปของคุณ
        foregroundColor: _bg, // สีไอคอนเป็นสีพื้นหลังเข้มๆ จะได้ตัดกันสวยๆ
        elevation: 8, // เพิ่มเงาให้ดูมีมิติ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ), // ทำขอบปุ่มให้โค้งมนนิดๆ เข้ากับสไตล์แอป
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          size: 28,
        ), // ไอคอนรูปหุ่นยนต์ AI
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          border: const Border(top: BorderSide(color: _divider)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped, // ✅ เรียกใช้ฟังก์ชันที่สร้างใหม่
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _accent,
          unselectedItemColor: _textSub,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: "Fanfic",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate_outlined),
              activeIcon: Icon(Icons.translate_rounded),
              label: "Vocab",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: "Favorite",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_outlined),
              activeIcon: Icon(Icons.edit_rounded),
              label: "Writefic",
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Home Screen
// ══════════════════════════════════════════════════════════════════════════════
class _HomeScreen extends StatefulWidget {
  const _HomeScreen();
  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final supabase = Supabase.instance.client;

  int activeIndex = 0;

  List<Map<String, dynamic>> _continueReading = [];
  bool _loadingReading = true;
  RealtimeChannel? _realtimeChannel;

  Map<String, dynamic>? _randomVocab;
  bool _vocabFlipped = false;
  bool _loadingVocab = true;
  late final FlutterTts _tts;

  List<Map<String, dynamic>> _featuredNovels = [];
  bool _loadingFeatured = true;

  // ✅ เปลี่ยนเป็นเก็บ List ของข้อมูลนิยายแทน เพื่อเอาทั้งรูปและข้อมูลไปใช้ตอนกดคลิก
  List<Map<String, dynamic>> _carouselNovels = [];
  bool _loadingCarousel = true;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setVolume(1.0);
    _tts.setSpeechRate(0.5);
    _loadContinueReading();
    _loadRandomVocab();
    _loadFeaturedNovels();
    _loadCarouselImages(); // ✅ เรียกฟังก์ชันโหลดรูปลงสไลด์
    _subscribeReadingProgress();
  }

  // ✅ ฟังก์ชันใหม่: โหลดภาพสไลด์แบบสุ่ม 5 เรื่อง
  Future<void> _loadCarouselImages() async {
    try {
      final res = await supabase
          .from('novels')
          .select('id, title, cover_image')
          .neq('cover_image', '') // เอาเฉพาะเรื่องที่มีรูป
          .not('cover_image', 'is', null)
          .limit(20); // ดึงมาเผื่อไว้ก่อน

      if (res.isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(res);
        list.shuffle(Random()); // สับไพ่แบบสุ่มมั่วๆ
        if (mounted) {
          setState(() {
            _carouselNovels = list
                .take(5)
                .toList(); // เอามาแค่ 5 เรื่องพอให้สไลด์สวยๆ
            _loadingCarousel = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingCarousel = false);
      }
    } catch (e) {
      debugPrint('Load Carousel Error: $e');
      if (mounted) setState(() => _loadingCarousel = false);
    }
  }

  // ✅ แก้ไข: โหลดนิยายแนะนำจาก "ยอดวิวสูงสุด 10 อันดับ"
  Future<void> _loadFeaturedNovels() async {
    try {
      // 1. ดึงนิยายเรียงตามยอด views จากมากไปน้อย จำกัด 10 เรื่อง
      final novelsData = await supabase
          .from('novels')
          .select('id, title, author, genre, cover_image, cover_color, views')
          .order('views', ascending: false)
          .limit(10);

      // 2. โหลดข้อมูลยอดคนกดใจทั้งหมด
      final likesData = await supabase.from('novel_likes').select('novel_id');

      // 3. นับจำนวนหัวใจจัดกลุ่มตาม id นิยาย
      final Map<String, int> likeCounts = {};
      for (final row in likesData as List) {
        final novelId = row['novel_id'] as String;
        likeCounts[novelId] = (likeCounts[novelId] ?? 0) + 1;
      }

      // 4. เอาจำนวนหัวใจมาใส่รวมกับข้อมูลนิยาย
      final List<Map<String, dynamic>> allNovels = [];
      for (final row in novelsData as List) {
        final novelId = row['id'] as String;
        allNovels.add({
          ...Map<String, dynamic>.from(row),
          'like_count': likeCounts[novelId] ?? 0,
        });
      }

      if (mounted) {
        setState(() {
          _featuredNovels = allNovels; // แสดงทั้ง 10 เรื่องเลย
          _loadingFeatured = false;
        });
      }
    } catch (e) {
      debugPrint('Load Featured Error: $e');
      if (mounted) setState(() => _loadingFeatured = false);
    }
  }

  void _subscribeReadingProgress() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    _realtimeChannel = supabase
        .channel('reading_progress_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reading_progress',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            if (record['user_id'] == userId && mounted) _loadContinueReading();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_randomVocab == null) return;
    if (_vocabFlipped) {
      await _tts.setLanguage('ja-JP');
      await _tts.speak(_randomVocab!['japanese'] ?? '');
    } else {
      await _tts.setLanguage('th-TH');
      await _tts.speak(_randomVocab!['thai'] ?? '');
    }
  }

  // ── อ่านต่อ: ดึง progress ต่อ episode ─────────────────────────────────────
  Future<void> _loadContinueReading() async {
    setState(() => _loadingReading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _loadingReading = false);
        return;
      }

      final progRows = await supabase
          .from('reading_progress')
          .select('line_index, total_lines, episode_id, novel_id, updated_at')
          .eq('user_id', user.id)
          .not('episode_id', 'is', null)
          .order('updated_at', ascending: false); // สำคัญมาก!

      // ✅ แก้ที่ 2: จัดกลุ่มนิยาย ให้โชว์แค่ 1 ตอน (ตอนล่าสุด) ต่อ 1 เรื่องเท่านั้น
      final Map<String, dynamic> latestProgressPerNovel = {};
      for (final row in progRows as List) {
        final novelId = row['novel_id'] as String?;
        if (novelId != null && !latestProgressPerNovel.containsKey(novelId)) {
          // เนื่องจากเราเรียงเวลาจากใหม่สุดมาแล้ว ข้อมูลอันแรกของเรื่องนั้นคือตอนล่าสุดเสมอ
          latestProgressPerNovel[novelId] = row;
        }
      }

      // ✅ แก้ที่ 3: เอาแค่ 10 เรื่องล่าสุดมาแสดง (และเอาเงื่อนไขซ่อนตอนที่อ่านจบ 100% ออก)
      final inProgress = latestProgressPerNovel.values.take(10).toList();

      final List<Map<String, dynamic>> result = [];
      for (final prog in inProgress) {
        try {
          final epId = prog['episode_id'] as String;
          final novelId = prog['novel_id'] as String;

          final epRow = await supabase
              .from('episodes')
              .select('id, episode_num, title, novel_id')
              .eq('id', epId)
              .single();

          final novelRow = await supabase
              .from('novels')
              .select('id, title, cover_image')
              .eq('id', novelId)
              .single();

          result.add({
            'line_index': prog['line_index'],
            'total_lines': prog['total_lines'],
            'episode_id': epId,
            'episodes': {
              ...Map<String, dynamic>.from(epRow),
              'novels': Map<String, dynamic>.from(novelRow),
            },
          });
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _continueReading = result;
          _loadingReading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingReading = false);
    }
  }

  Future<void> _loadRandomVocab() async {
    setState(() {
      _loadingVocab = true;
      _vocabFlipped = false;
    });
    try {
      final data = await supabase
          .from('vocab_cards')
          .select('id, thai, japanese, reading, category')
          .limit(100);
      if (data.isNotEmpty && mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        list.shuffle(Random());
        setState(() {
          _randomVocab = list.first;
          _loadingVocab = false;
        });
      } else {
        if (mounted) setState(() => _loadingVocab = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingVocab = false);
    }
  }

  Future<void> _openContinueReading(Map<String, dynamic> item) async {
    final episodeData = item['episodes'] as Map<String, dynamic>?;
    if (episodeData == null) return;

    final novelData = episodeData['novels'] as Map<String, dynamic>?;
    if (novelData == null) return;

    final novelId = novelData['id'] as String?;
    final episodeId = episodeData['id'] as String?;
    if (novelId == null || episodeId == null) return;

    try {
      final row = await supabase
          .from('novels')
          .select()
          .eq('id', novelId)
          .single();
      final commentsRes = await supabase
          .from('comments')
          .select()
          .eq('novel_id', novelId)
          .order('created_at', ascending: false);
      final likesRes = await supabase
          .from('novel_likes')
          .select()
          .eq('novel_id', novelId);

      final novel = NovelModel.fromSupabase(
        row,
        commentsRes as List,
        (likesRes as List).length,
      );

      final epRow = await supabase
          .from('episodes')
          .select()
          .eq('id', episodeId)
          .single();
      final lineRows = await supabase
          .from('chat_lines')
          .select()
          .eq('episode_id', episodeId)
          .order('order_num', ascending: true);
      final episode = EpisodeModel.fromSupabase(epRow, lineRows as List);

      final savedIdx = item['line_index'] as int? ?? 0;

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatReadPage(
            novel: novel,
            episode: episode,
            initialIndex: savedIdx,
          ),
        ),
      );
      _loadContinueReading();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดไม่สำเร็จ: $e',
            style: const TextStyle(color: _textPrim),
          ),
          backgroundColor: _card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ ฟังก์ชันช่วยเปิดหน้านิยายจาก Carousel
  Future<void> _openNovelFromId(String novelId) async {
    try {
      final row = await supabase
          .from('novels')
          .select()
          .eq('id', novelId)
          .single();
      final commentsRes = await supabase
          .from('comments')
          .select()
          .eq('novel_id', novelId)
          .order('created_at', ascending: false);
      final likesRes = await supabase
          .from('novel_likes')
          .select()
          .eq('novel_id', novelId);

      final novelModel = NovelModel.fromSupabase(
        row,
        commentsRes as List,
        (likesRes as List).length,
      );

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPage(novel: novelModel)),
      );
      _loadFeaturedNovels(); // รีเฟรชยอดวิวตอนกลับมา
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเปิดนิยายได้: $e',
            style: const TextStyle(color: _textPrim),
          ),
          backgroundColor: _card,
        ),
      );
    }
  }

  // ── UI: Carousel ───────────────────────────────────────────────────────────
  Widget _imageSlider() {
    if (_loadingCarousel) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_carouselNovels.isEmpty) {
      return const SizedBox.shrink(); // ถ้าไม่มีรูปในเน็ตเลย ก็ซ่อนสไลด์ไป
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _carouselNovels.length,
          itemBuilder: (context, index, _) {
            final novel = _carouselNovels[index];
            return GestureDetector(
              onTap: () => _openNovelFromId(novel['id']),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(novel['cover_image']),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                // ใส่ Gradient ดำๆ ด้านล่างเผื่ออยากโชว์ชื่อเรื่องในสไลด์ด้วย
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    novel['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, _) => setState(() => activeIndex = index),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselNovels.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: activeIndex == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: activeIndex == i ? _accent : _divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrim,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                "ดูทั้งหมด",
                style: TextStyle(color: _accent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  // ── UI: Continue Reading ───────────────────────────────────────────────────
  Widget _continueReadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("📖 อ่านต่อ"),
        if (_loadingReading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
            ),
          )
        else if (_continueReading.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _divider),
              ),
              child: const Column(
                children: [
                  Icon(Icons.menu_book_rounded, color: _textSub, size: 36),
                  SizedBox(height: 8),
                  Text(
                    "ยังไม่มีนิยายที่กำลังอ่านอยู่",
                    style: TextStyle(color: _textSub, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _continueReading.length,
              itemBuilder: (context, i) {
                final item = _continueReading[i];
                final episodeData =
                    item['episodes'] as Map<String, dynamic>? ?? {};
                final novelData =
                    episodeData['novels'] as Map<String, dynamic>? ?? {};
                final title = novelData['title'] as String? ?? 'ไม่มีชื่อ';
                final cover = novelData['cover_image'] as String?;
                final epNum = episodeData['episode_num'] as int? ?? 0;
                final epTitle = episodeData['title'] as String? ?? '';
                final lineIndex = item['line_index'] as int? ?? 0;
                final totalLines = item['total_lines'] as int? ?? 0;
                final progress = totalLines > 0
                    ? (lineIndex / totalLines).clamp(0.0, 1.0)
                    : 0.0;

                return GestureDetector(
                  onTap: () => _openContinueReading(item),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: cover != null
                              ? Image.network(
                                  cover,
                                  height: 80,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _coverPlaceholder(),
                                )
                              : _coverPlaceholder(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textPrim,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ตอน $epNum: $epTitle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _accent,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: _divider,
                                  color: _accent,
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$lineIndex / $totalLines',
                                style: const TextStyle(
                                  color: _textSub,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _coverPlaceholder() => Container(
    height: 80,
    width: 120,
    color: _surface,
    child: const Icon(Icons.book_rounded, color: _textSub, size: 32),
  );

  // ── UI: Random Vocab ───────────────────────────────────────────────────────
  Widget _randomVocabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("✨ คำศัพท์วันนี้"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _loadingVocab
              ? Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _divider),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _randomVocab == null
              ? Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _divider),
                  ),
                  child: const Center(
                    child: Text(
                      "ไม่พบคำศัพท์",
                      style: TextStyle(color: _textSub),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    final goingToBack = !_vocabFlipped;
                    setState(() => _vocabFlipped = !_vocabFlipped);
                    if (goingToBack)
                      Future.delayed(const Duration(milliseconds: 360), _speak);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _vocabFlipped
                        ? _vocabBack(key: const ValueKey('back'))
                        : _vocabFront(key: const ValueKey('front')),
                  ),
                ),
        ),
        if (_randomVocab != null && !_loadingVocab) ...[
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _loadRandomVocab,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shuffle_rounded, color: _accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "สุ่มคำใหม่",
                      style: TextStyle(color: _accent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _vocabFront({Key? key}) => Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A2640), Color(0xFF0F1A30)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _accent.withOpacity(0.35), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _accent.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "คำศัพท์",
                style: TextStyle(color: _accent, fontSize: 11),
              ),
            ),
            const Spacer(),
            const Icon(Icons.touch_app_rounded, color: _textSub, size: 16),
            const SizedBox(width: 4),
            const Text(
              "แตะเพื่อดูความหมาย",
              style: TextStyle(color: _textSub, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _randomVocab!['japanese'] ?? '',
          style: const TextStyle(
            color: _textPrim,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _vocabBack({Key? key}) => Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E2030), Color(0xFF0A1525)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFF4ECDC4).withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4ECDC4).withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x334ECDC4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "ความหมาย",
            style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _randomVocab!['japanese'] ?? '',
          style: const TextStyle(
            color: _textSub,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (_randomVocab!['reading'] != null)
          Text(
            '(${_randomVocab!['reading']})',
            style: const TextStyle(color: _textSub, fontSize: 13),
          ),
        const SizedBox(height: 8),
        Text(
          _randomVocab!['thai'] ?? '',
          style: const TextStyle(
            color: _textPrim,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_randomVocab!['category'] != null) ...[
          const SizedBox(height: 12),
          const Divider(color: _divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.label_outline_rounded,
                color: _textSub,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _randomVocab!['category'],
                style: const TextStyle(color: _textSub, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  // ── UI: Featured Novel Card ────────────────────────────────────────────────
  Widget _novelCard(Map<String, dynamic> novel) {
    final hasImage = (novel['cover_image'] as String?)?.isNotEmpty == true;
    final coverHex = novel['cover_color'] as String? ?? '38BEFF';
    final coverColor = Color(int.parse('FF$coverHex', radix: 16));
    final views = novel['views'] as int? ?? 0;
    final likes = novel['like_count'] as int? ?? 0;
    String fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

    return GestureDetector(
      onTap: () async {
        final novelId = novel['id'] as String?;
        if (novelId == null) return;
        try {
          final row = await supabase
              .from('novels')
              .select()
              .eq('id', novelId)
              .single();
          final commentsRes = await supabase
              .from('comments')
              .select()
              .eq('novel_id', novelId)
              .order('created_at', ascending: false);
          final likesRes = await supabase
              .from('novel_likes')
              .select()
              .eq('novel_id', novelId);

          final novelModel = NovelModel.fromSupabase(
            row,
            commentsRes as List,
            (likesRes as List).length,
          );

          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailPage(novel: novelModel)),
          );
          _loadFeaturedNovels();
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'โหลดไม่สำเร็จ: $e',
                style: const TextStyle(color: _textPrim),
              ),
              backgroundColor: _card,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 130,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: SizedBox(
                width: 90,
                child: hasImage
                    ? Image.network(
                        novel['cover_image']!,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _NovelCoverPlaceholder(
                          color: coverColor,
                          letter: (novel['title'] as String).substring(0, 1),
                        ),
                      )
                    : _NovelCoverPlaceholder(
                        color: coverColor,
                        letter: (novel['title'] as String).substring(0, 1),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        novel['genre'] ?? '',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      novel['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrim,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: _textSub,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            novel['author'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSub,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          color: _textSub,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fmt(views),
                          style: const TextStyle(color: _textSub, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF4D6D),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fmt(likes),
                          style: const TextStyle(color: _textSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: _textSub,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _imageSlider(),
          const SizedBox(height: 24),
          _continueReadingSection(),
          const SizedBox(height: 24),
          _randomVocabSection(),
          const SizedBox(height: 28),
          _sectionHeader("🔥 นิยายแนะนำ"),
          if (_loadingFeatured)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: _accent,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_featuredNovels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _divider),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.book_outlined, color: _textSub, size: 36),
                    SizedBox(height: 8),
                    Text(
                      "ยังไม่มีนิยาย",
                      style: TextStyle(color: _textSub, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _featuredNovels.map((n) => _novelCard(n)).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Novel Cover Placeholder
// ══════════════════════════════════════════════════════════════════════════════
class _NovelCoverPlaceholder extends StatelessWidget {
  final Color color;
  final String letter;
  const _NovelCoverPlaceholder({required this.color, required this.letter});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.5)],
      ),
    ),
    child: Center(
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 48,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper widget
// ══════════════════════════════════════════════════════════════════════════════
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isRed;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: isRed ? Colors.redAccent : _accent, size: 22),
    title: Text(
      label,
      style: TextStyle(
        color: isRed ? Colors.redAccent : _textPrim,
        fontSize: 15,
      ),
    ),
    onTap: onTap,
  );
}
