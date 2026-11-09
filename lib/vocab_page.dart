import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vocab_quiz_page.dart';
// ============================================================================
// 1. CONSTANTS (ตั้งค่าสีและตัวแปรคงที่)
// ============================================================================
class AppColors {
  static const bg         = Color(0xFF080C14);
  static const surface    = Color(0xFF0F1520);
  static const card       = Color(0xFF141C2E);
  static const accent     = Color(0xFF38BEFF);
  static const accentSoft = Color(0x3338BEFF);
  static const textPrim   = Color(0xFFE8F0FF);
  static const textSub    = Color(0xFF6B7FA3);
  static const divider    = Color(0xFF1E2A42);
}

// ============================================================================
// 2. MODELS (โครงสร้างข้อมูล)
// ============================================================================
class VocabCard {
  final String id;
  final String thai;
  final String japanese;
  final String reading;
  final String category;
  final String? imageUrl;

  const VocabCard({
    required this.id,
    required this.thai,
    required this.japanese,
    required this.reading,
    required this.category,
    this.imageUrl,
  });

  factory VocabCard.fromSupabase(Map<String, dynamic> row) {
    return VocabCard(
      id: row['id'] as String,
      thai: row['thai'] as String,
      japanese: row['japanese'] as String,
      reading: (row['reading'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'ทั่วไป',
      imageUrl: row['image_url'] as String?,
    );
  }
}

// ============================================================================
// 3. MAIN PAGE (หน้าจอหลัก)
// ============================================================================
class VocabPage extends StatefulWidget {
  const VocabPage({super.key});

  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage> {
  final supabase = Supabase.instance.client;

  List<VocabCard> _cards = [];
  List<VocabCard> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'ทั้งหมด';
  List<String> _categories = ['ทั้งหมด'];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      
      final res = await supabase
    .from('vocab_cards')
    .select()
    .order('category')
    .order('sort_order', ascending: true, nullsFirst: false)
    .order('thai');
          
      final cards = (res as List)
          .map((r) => VocabCard.fromSupabase(r as Map<String, dynamic>))
          .toList();
          
      final cats = <String>{'ทั้งหมด'};
      for (final c in cards) {
        cats.add(c.category);
      }
      
      if (mounted) {
        setState(() {
          _cards = cards;
          _filtered = cards;
          _categories = cats.toList();
          _loading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _filterByCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _filtered = cat == 'ทั้งหมด'
          ? _cards
          : _cards.where((c) => c.category == cat).toList();
    });
  }

  // แยกส่วน Body ออกมาให้โค้ดดูสะอาดขึ้น
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return _ErrorView(onRetry: _loadCards);
    }
    if (_cards.isEmpty) {
      return const _EmptyView();
    }

    return Column(
      children: [
        _CategoryBar(
          categories: _categories,
          selected: _selectedCategory,
          onSelected: _filterByCategory,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Text(
                '${_filtered.length} คำ',
                style: const TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder( // เอา GridView ขึ้นมาใส่ใน child ของ Expanded เลย
            physics: const ClampingScrollPhysics(), // ตัวนี้บล็อกอาการเด้งได้ถูกต้องแล้วครับ
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _FlipCard(
              key: ValueKey(_filtered[i].id),
              card: _filtered[i],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ซ่อนปุ่ม Back
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'คำศัพท์ไทย–ญี่ปุ่น',
          style: TextStyle(
            color: AppColors.textPrim,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
     actions: [
  IconButton(
    icon: const Icon(Icons.quiz_rounded, color: AppColors.accent),
    tooltip: 'Quiz mode',
    onPressed: () {
      if (_cards.length < 4) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VocabQuizPage(cards: _filtered),
        ),
      );
    },
  ),
],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================================
// 4. WIDGETS: COMPONENTS (ชิ้นส่วน UI ต่างๆ)
// ============================================================================

// --- 4.1 แถบเลือกหมวดหมู่ ---
class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.divider,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isActive ? AppColors.bg : AppColors.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 4.2 การ์ดคำศัพท์ (พลิกได้) ---
class _FlipCard extends StatefulWidget {
  final VocabCard card;
  const _FlipCard({super.key, required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  late final FlutterTts _tts;
  bool _flipped = false;
  bool _isFavorited = false;
  bool _favLoading = false;

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
    _checkFavorite();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final res = await supabase
          .from('vocab_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('vocab_id', widget.card.id)
          .maybeSingle();
      if (mounted) setState(() => _isFavorited = res != null);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null || _favLoading) return;
    setState(() => _favLoading = true);
    try {
      if (_isFavorited) {
        await supabase
            .from('vocab_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('vocab_id', widget.card.id);
      } else {
        await supabase.from('vocab_favorites').insert({
          'user_id': user.id,
          'vocab_id': widget.card.id,
        });
      }
      if (mounted) setState(() => _isFavorited = !_isFavorited);
    } catch (e) {
      debugPrint('Favorite error: $e');
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _speak() async {
    if (_flipped) {
      await _tts.setLanguage('ja-JP');
      await _tts.speak(widget.card.japanese);
    } else {
      await _tts.setLanguage('th-TH');
      await _tts.speak(widget.card.thai);
    }
  }

  void _flip() {
    final goingToBack = !_flipped;
    _flipped ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _flipped = !_flipped);
    if (goingToBack) {
      Future.delayed(const Duration(milliseconds: 420), _speak);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final showBack = _anim.value >= 0.5;
        final angle = _anim.value * pi;

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
                        child: _CardBack(card: widget.card),
                      )
                    : _CardFront(card: widget.card),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: _favLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- 4.3 ด้านหน้าของการ์ด ---
class _CardFront extends StatelessWidget {
  final VocabCard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: hasImage
                  ? Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : _ImagePlaceholder(japanese: card.japanese),
                      errorBuilder: (_, __, ___) =>
                          _ImagePlaceholder(japanese: card.japanese),
                    )
                  : _ImagePlaceholder(japanese: card.japanese),
            ),
            Container(
              color: AppColors.card,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      card.category,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    card.thai,
                    style: const TextStyle(
                      color: AppColors.textPrim,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.touch_app_outlined,
                          color: AppColors.textSub, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        'แตะเพื่อดูภาษาญี่ปุ่น',
                        style: TextStyle(
                          color: AppColors.textSub.withOpacity(0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4.4 พื้นหลังภาพตอนโหลดไม่ขึ้น ---
class _ImagePlaceholder extends StatelessWidget {
  final String japanese;
  const _ImagePlaceholder({required this.japanese});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(
          japanese,
          style: TextStyle(
            color: AppColors.accent.withOpacity(0.15),
            fontSize: 56,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// --- 4.5 ด้านหลังของการ์ด ---
class _CardBack extends StatelessWidget {
  final VocabCard card;
  const _CardBack({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent.withOpacity(0.15), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SizedBox.expand(
        child: Center(
          // ✅ เพิ่ม SingleChildScrollView เพื่อให้เนื้อหาไถเลื่อนได้ถ้าคำยาวเกิน
          child: SingleChildScrollView( 
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ เพิ่ม FittedBox ป้องกันคำภาษาญี่ปุ่นล้นแนวนอน
                  FittedBox( 
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card.japanese,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (card.reading.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.reading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(height: 1, width: 40, color: AppColors.divider),
                  const SizedBox(height: 12),
                  Text(
                    card.thai,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrim,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. WIDGETS: STATES (หน้าจอสถานะต่างๆ เช่น โหลดพัง, ไม่มีข้อมูล)
// ============================================================================

// --- 5.1 หน้าจอ Error ---
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textSub, size: 40),
          const SizedBox(height: 12),
          const Text(
            'โหลดข้อมูลไม่สำเร็จ',
            style: TextStyle(color: AppColors.textPrim, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('ลองอีกครั้ง',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// --- 5.2 หน้าจอ Empty (ไม่มีข้อมูล) ---
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '日本語',
            style: TextStyle(
              color: AppColors.accentSoft,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีคำศัพท์',
            style: TextStyle(color: AppColors.textPrim, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'เพิ่มข้อมูลในตาราง vocab_cards',
            style: TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
        ],
      ),
    );
  }
}