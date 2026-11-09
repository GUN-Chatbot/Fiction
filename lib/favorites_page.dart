import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fanfic_page.dart';

const _bg         = Color(0xFF080C14);
const _surface    = Color(0xFF0F1520);
const _card       = Color(0xFF141C2E);
const _accent     = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim   = Color(0xFFE8F0FF);
const _textSub    = Color(0xFF6B7FA3);
const _divider    = Color(0xFF1E2A42);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _fanficRebuildKey = 0; // ✅ เพิ่ม

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(_onTabChanged); // ✅ เพิ่ม
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging && _tabCtrl.index == 0) {
      setState(() => _fanficRebuildKey++); // ✅ force rebuild FanficTab
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged); // ✅ เพิ่ม
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor : _surface,
        surfaceTintColor: Colors.transparent,
        elevation       : 0,
        centerTitle     : true,
        automaticallyImplyLeading: false,
        title: const Text(
          'รายการที่ถูกใจ',
          style: TextStyle(
            color: _textPrim, fontSize: 16,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller          : _tabCtrl,
          indicatorColor      : _accent,
          indicatorWeight     : 2,
          labelColor          : _accent,
          unselectedLabelColor: _textSub,
          labelStyle          : const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'นิยาย'),
            Tab(icon: Icon(Icons.translate_outlined, size: 18), text: 'คำศัพท์'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children  : [
          _FanficTab(key: ValueKey(_fanficRebuildKey)), // ✅ เปลี่ยน key
          const _VocabTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: นิยาย
// =============================================================================
class _FanficTab extends StatefulWidget {
  const _FanficTab({super.key}); // ✅ เพิ่ม super.key

  @override
  State<_FanficTab> createState() => _FanficTabState();
}

class _FanficTabState extends State<_FanficTab>
    with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  bool get wantKeepAlive => false; // ✅ โหลดใหม่ทุกครั้งที่กลับมาที่ tab

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _channel = supabase
        .channel('novel_likes_realtime_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'novel_likes',
          callback: (_) => _load(showSpinner: false), // ✅ ไม่ filter — รับทุก event
        )
        .subscribe();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(showSpinner: false); // ✅ โหลดใหม่ทุกครั้งที่กลับมา tab
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (showSpinner && _items.isEmpty) {
      setState(() => _loading = true);
    }

    try {
      final data = await supabase
          .from('novel_likes')
          .select('novel_id, novels(id, title, author, genre, synopsis, cover_color, cover_image, views, char_a_name, char_b_name, char_c_name, char_d_name, char_a_image, char_b_image, char_c_image, char_d_image)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) setState(() {
        _items   = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('FanficTab error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String novelId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final old = List<Map<String, dynamic>>.from(_items);
    setState(() => _items.removeWhere((r) => r['novel_id'].toString() == novelId));
    try {
      await supabase.from('novel_likes').delete()
          .eq('user_id', user.id).eq('novel_id', novelId);
    } catch (_) {
      setState(() => _items = old);
    }
  }

  Color _parseCover(String? hex) {
    try { return Color(int.parse('FF${hex ?? '1A237E'}', radix: 16)); }
    catch (_) { return const Color(0xFF1A237E); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = supabase.auth.currentUser;
    if (_loading) return const Center(child: CircularProgressIndicator(color: _accent));
    if (user == null) return const _NotLoggedInView();
    if (_items.isEmpty) return const _EmptyView(
      icon: Icons.menu_book_outlined,
      text: 'ยังไม่มีนิยายที่ถูกใจ',
    );
    return RefreshIndicator(
      color    : _accent,
      onRefresh: () => _load(showSpinner: true),
      child    : ListView.builder(
        padding    : const EdgeInsets.all(16),
        itemCount  : _items.length,
        itemBuilder: (_, i) {
          final novel      = (_items[i]['novels'] ?? {}) as Map<String, dynamic>;
          final novelId    = novel['id']?.toString() ?? '';
          final title      = (novel['title'] ?? '').toString();
          final author     = (novel['author'] ?? '').toString();
          final genre      = (novel['genre'] ?? '').toString();
          final coverColor = _parseCover(novel['cover_color']?.toString());
          final coverImage = novel['cover_image']?.toString();
          final hasImage   = coverImage != null && coverImage.isNotEmpty;

          return GestureDetector(
            onTap: () async {
              final novelModel = NovelModel(
                id:         novel['id']?.toString() ?? '',
                title:      novel['title']?.toString() ?? '',
                author:     novel['author']?.toString() ?? '',
                genre:      novel['genre']?.toString() ?? '',
                synopsis:   novel['synopsis']?.toString() ?? '',
                coverColor: novel['cover_color']?.toString() ?? '38BEFF',
                coverImage: novel['cover_image']?.toString(),
                charAName:  novel['char_a_name']?.toString(),
                charBName:  novel['char_b_name']?.toString(),
                charCName:  novel['char_c_name']?.toString(),
                charDName:  novel['char_d_name']?.toString(),
                charAImage: novel['char_a_image']?.toString(),
                charBImage: novel['char_b_image']?.toString(),
                charCImage: novel['char_c_image']?.toString(),
                charDImage: novel['char_d_image']?.toString(),
                views:      (novel['views'] as int?) ?? 0,
              );
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(novel: novelModel)),
              );
              _load(showSpinner: false);
            },
            child: Container(
              margin     : const EdgeInsets.only(bottom: 14),
              decoration : BoxDecoration(
                color       : _card,
                borderRadius: BorderRadius.circular(16),
                border      : Border.all(color: _divider),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48, height: 64,
                    color: coverColor,
                    child: hasImage
                        ? Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(title.isNotEmpty ? title[0] : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            ),
                          )
                        : Center(
                            child: Text(title.isNotEmpty ? title[0] : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          ),
                  ),
                ),
                title: Text(title,
                    style: const TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(author, style: const TextStyle(color: _textSub, fontSize: 12)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(genre,
                          style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                trailing: GestureDetector(
                  onTap: () => _remove(novelId),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// TAB 2: คำศัพท์
// =============================================================================
class _VocabItem {
  final String  id;
  final String  thai;
  final String  japanese;
  final String  reading;
  final String  category;
  final String? imageUrl;

  const _VocabItem({
    required this.id, required this.thai, required this.japanese,
    required this.reading, required this.category, this.imageUrl,
  });

  factory _VocabItem.fromRow(Map<String, dynamic> row) => _VocabItem(
    id      : row['id']        as String,
    thai    : row['thai']      as String,
    japanese: row['japanese']  as String,
    reading : (row['reading']  as String?) ?? '',
    category: (row['category'] as String?) ?? 'ทั่วไป',
    imageUrl: row['image_url'] as String?,
  );
}

class _VocabTab extends StatefulWidget {
  const _VocabTab();

  @override
  State<_VocabTab> createState() => _VocabTabState();
}

class _VocabTabState extends State<_VocabTab>
    with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  List<_VocabItem> _items = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    _channel = supabase
        .channel('vocab_favorites_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vocab_favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _load(showSpinner: false),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (showSpinner && _items.isEmpty) {
      setState(() => _loading = true);
    }

    try {
      final data = await supabase
          .from('vocab_favorites')
          .select('vocab_id, vocab_cards(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      final items = (data as List).map((r) =>
          _VocabItem.fromRow(r['vocab_cards'] as Map<String, dynamic>)).toList();

      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      debugPrint('VocabTab error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String vocabId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final old = List<_VocabItem>.from(_items);
    setState(() => _items.removeWhere((c) => c.id == vocabId));
    try {
      await supabase.from('vocab_favorites').delete()
          .eq('user_id', user.id).eq('vocab_id', vocabId);
    } catch (_) { setState(() => _items = old); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = supabase.auth.currentUser;
    if (_loading) return const Center(child: CircularProgressIndicator(color: _accent));
    if (user == null) return const _NotLoggedInView();
    if (_items.isEmpty) return const _EmptyView(
      icon: Icons.translate_outlined,
      text: 'ยังไม่มีคำศัพท์ที่ถูกใจ',
    );
    return RefreshIndicator(
      color    : _accent,
      onRefresh: () => _load(showSpinner: true),
      child    : GridView.builder(
        padding          : const EdgeInsets.fromLTRB(16, 16, 16, 32),
        gridDelegate     : const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount  : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing : 12,
          childAspectRatio: 0.9,
        ),
        itemCount  : _items.length,
        itemBuilder: (_, i) => _VocabFlipCard(
          item    : _items[i],
          onRemove: () => _remove(_items[i].id),
        ),
      ),
    );
  }
}

class _VocabFlipCard extends StatefulWidget {
  final _VocabItem   item;
  final VoidCallback onRemove;
  const _VocabFlipCard({required this.item, required this.onRemove});

  @override
  State<_VocabFlipCard> createState() => _VocabFlipCardState();
}

class _VocabFlipCardState extends State<_VocabFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;
  late final FlutterTts          _tts;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
    _tts = FlutterTts();
    _tts.setVolume(1.0);
    _tts.setSpeechRate(0.5);
  }

  @override
  void dispose() { _ctrl.dispose(); _tts.stop(); super.dispose(); }

  void _flip() {
    final goingBack = !_flipped;
    _flipped ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _flipped = !_flipped);
    if (goingBack) {
      Future.delayed(const Duration(milliseconds: 420), () async {
        await _tts.setLanguage('ja-JP');
        await _tts.speak(widget.item.japanese);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final showBack = _anim.value >= 0.5;
        final angle    = _anim.value * pi;

        return Stack(
          children: [
            GestureDetector(
              onTap: _flip,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child    : _VocabCardBack(item: widget.item),
                      )
                    : _VocabCardFront(item: widget.item),
              ),
            ),
            Positioned(
              top: 6, right: 6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VocabCardFront extends StatelessWidget {
  final _VocabItem item;
  const _VocabCardFront({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: hasImage
                ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ImgPlaceholder(japanese: item.japanese))
                : _ImgPlaceholder(japanese: item.japanese)),
            Container(color: _card,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(item.category,
                        style: const TextStyle(color: _accent, fontSize: 8,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                  const SizedBox(height: 5),
                  Text(item.thai, style: const TextStyle(
                      color: _textPrim, fontSize: 20,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.touch_app_outlined, color: _textSub, size: 10),
                    const SizedBox(width: 3),
                    Text('แตะเพื่อดูภาษาญี่ปุ่น',
                        style: TextStyle(color: _textSub.withOpacity(0.7), fontSize: 9)),
                  ]),
                ])),
          ]),
      ),
    );
  }
}

class _VocabCardBack extends StatelessWidget {
  final _VocabItem item;
  const _VocabCardBack({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_accent.withOpacity(0.15), _card]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.1),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.japanese, textAlign: TextAlign.center,
                    style: const TextStyle(color: _accent, fontSize: 36,
                      fontWeight: FontWeight.w800, height: 1.2)),
                if (item.reading.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.reading, textAlign: TextAlign.center,
                      style: const TextStyle(color: _textSub, fontSize: 13, height: 1.4)),
                ],
                const SizedBox(height: 14),
                Container(height: 1, width: 40, color: _divider),
                const SizedBox(height: 12),
                Text(item.thai, textAlign: TextAlign.center,
                    style: const TextStyle(color: _textPrim, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  final String japanese;
  const _ImgPlaceholder({required this.japanese});

  @override
  Widget build(BuildContext context) => Container(
    color: _surface,
    child: Center(child: Text(japanese,
        style: TextStyle(color: _accent.withOpacity(0.15),
            fontSize: 56, fontWeight: FontWeight.w900))),
  );
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, color: _textSub, size: 44),
        SizedBox(height: 12),
        Text('ต้องเข้าสู่ระบบก่อน', style: TextStyle(color: _textPrim, fontSize: 15)),
        SizedBox(height: 4),
        Text('เพื่อดูรายการที่ถูกใจ', style: TextStyle(color: _textSub, fontSize: 12)),
      ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _EmptyView({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: _accentSoft, size: 44),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: _textPrim, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('กดหัวใจในหน้าต่างๆ ได้เลย',
            style: TextStyle(color: _textSub, fontSize: 12)),
      ]),
    );
  }
}