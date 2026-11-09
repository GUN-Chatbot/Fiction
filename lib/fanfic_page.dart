import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

const _bg = Color(0xFF080C14);
const _surface = Color(0xFF0F1520);
const _card = Color(0xFF141C2E);
const _accent = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim = Color(0xFFE8F0FF);
const _textSub = Color(0xFF6B7FA3);
const _divider = Color(0xFF1E2A42);
const _heart = Color(0xFFFF4D6D);
const _heartSoft = Color(0x33FF4D6D);

const _colorA = Color(0xFF38BEFF);
const _colorB = Color(0xFF9B8FFF);
const _colorC = Color(0xFF4ECDC4);
const _colorD = Color(0xFFFFB347);

enum Sender { narrator, characterA, characterB, characterC, characterD }

Sender _senderFromString(String s) {
  switch (s) {
    case 'characterA': return Sender.characterA;
    case 'characterB': return Sender.characterB;
    case 'characterC': return Sender.characterC;
    case 'characterD': return Sender.characterD;
    default: return Sender.narrator;
  }
}

class ChatLine {
  final Sender sender;
  final String text;
  const ChatLine(this.sender, this.text);
}

class NovelComment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final String timeAgo;
  final String? avatarUrl; // ✅ เพิ่ม

  const NovelComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timeAgo,
    this.avatarUrl,
  });
}

class EpisodeModel {
  final String id;
  final String novelId;
  final int episodeNum;
  final String title;
  final List<ChatLine> chatLines;

  const EpisodeModel({
    required this.id,
    required this.novelId,
    required this.episodeNum,
    required this.title,
    this.chatLines = const [],
  });

  factory EpisodeModel.fromSupabase(Map<String, dynamic> row, List<dynamic> lines) {
    return EpisodeModel(
      id: row['id'] as String,
      novelId: row['novel_id'] as String,
      episodeNum: row['episode_num'] as int,
      title: row['title'] as String,
      chatLines: lines.map((l) => ChatLine(_senderFromString(l['sender'] as String), l['text'] as String)).toList(),
    );
  }
}

class NovelModel {
  final String id, title, author, genre, synopsis, coverColor;
  final String? coverImage, charAImage, charBImage, charCImage, charDImage;
  final String? charAName, charBName, charCName, charDName;
  final int views, likes;
  final List<NovelComment> comments;

  NovelModel({
    required this.id, required this.title, required this.author,
    required this.genre, required this.synopsis, required this.coverColor,
    this.coverImage, this.charAImage, this.charBImage, this.charCImage, this.charDImage,
    this.charAName, this.charBName, this.charCName, this.charDName,
    required this.views, this.likes = 0, this.comments = const [],
  });

  factory NovelModel.fromSupabase(Map<String, dynamic> row, List<dynamic> comments, int likeCount) {
    return NovelModel(
      id: row['id'] as String, title: row['title'] as String, author: row['author'] as String,
      genre: row['genre'] as String, synopsis: row['synopsis'] as String, coverColor: row['cover_color'] as String,
      coverImage: row['cover_image'] as String?, charAImage: row['char_a_image'] as String?,
      charBImage: row['char_b_image'] as String?, charCImage: row['char_c_image'] as String?,
      charDImage: row['char_d_image'] as String?, charAName: row['char_a_name'] as String?,
      charBName: row['char_b_name'] as String?, charCName: row['char_c_name'] as String?,
      charDName: row['char_d_name'] as String?, views: row['views'] as int, likes: likeCount,
      comments: comments.map((c) => NovelComment(
        id: c['id'].toString(), userId: c['user_id'] as String? ?? '',
        username: c['username'] as String, text: c['text'] as String,
        timeAgo: _timeAgo(DateTime.parse(c['created_at'] as String).toLocal()),
        avatarUrl: c['avatar_url'] as String?, // ✅ เพิ่ม
      )).toList(),
    );
  }

  NovelModel copyWith({int? likes, int? views, List<NovelComment>? comments}) => NovelModel(
    id: id, title: title, author: author, genre: genre, synopsis: synopsis, coverColor: coverColor,
    coverImage: coverImage, charAImage: charAImage, charBImage: charBImage, charCImage: charCImage,
    charDImage: charDImage, charAName: charAName, charBName: charBName, charCName: charCName,
    charDName: charDName, views: views ?? this.views, likes: likes ?? this.likes,
    comments: comments ?? this.comments,
  );
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'เพิ่งเมื่อกี้';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
  if (diff.inDays < 30) return '${diff.inDays} วันที่แล้ว';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} เดือนที่แล้ว';
  return '${(diff.inDays / 365).floor()} ปีที่แล้ว';
}

class _CharConfig {
  final Color color;
  final String? imageUrl;
  final String name;
  final bool isLeft;
  const _CharConfig({required this.color, this.imageUrl, required this.name, required this.isLeft});
}

_CharConfig _configFor(Sender sender, NovelModel novel) {
  switch (sender) {
    case Sender.characterA: return _CharConfig(color: _colorA, imageUrl: novel.charAImage, name: novel.charAName?.isNotEmpty == true ? novel.charAName! : '', isLeft: true);
    case Sender.characterB: return _CharConfig(color: _colorB, imageUrl: novel.charBImage, name: novel.charBName?.isNotEmpty == true ? novel.charBName! : '', isLeft: false);
    case Sender.characterC: return _CharConfig(color: _colorC, imageUrl: novel.charCImage, name: novel.charCName?.isNotEmpty == true ? novel.charCName! : '', isLeft: true);
    case Sender.characterD: return _CharConfig(color: _colorD, imageUrl: novel.charDImage, name: novel.charDName?.isNotEmpty == true ? novel.charDName! : '', isLeft: false);
    default: return const _CharConfig(color: _textSub, name: '', isLeft: true);
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final Color color;
  final String letter;
  const _CoverPlaceholder({required this.color, required this.letter});
  @override
  Widget build(BuildContext context) => Container(
    height: double.infinity, width: double.infinity, color: color,
    child: Center(child: Text(letter, style: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 160, fontWeight: FontWeight.w900))),
  );
}

Widget _gradBg(Color c) => Container(
  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c, c.withOpacity(0.4), _bg], stops: const [0, 0.6, 1])),
);

SnackBar _errSnack(String msg) => SnackBar(
  behavior: SnackBarBehavior.floating, backgroundColor: _card,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
  content: Row(children: [
    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18), const SizedBox(width: 8),
    Expanded(child: Text(msg, style: const TextStyle(color: _textPrim, fontSize: 13))),
  ]),
);

enum _EpStatus { notStarted, inProgress, done }

// =============================================================================
// FanficPage
// =============================================================================
class FanficPage extends StatefulWidget {
  const FanficPage({super.key});
  @override
  State<FanficPage> createState() => _FanficPageState();
}

class _FanficPageState extends State<FanficPage> {
  List<NovelModel> _novels = [];
  bool _loading = true;
  String? _error;
  String _selectedGenre = 'ทั้งหมด';

  static const List<String> _baseGenres = ['ทั้งหมด','โรแมนติก','แฟนตาซี','แอคชัน','สยองขวัญ','ตลก','ดราม่า','ระทึกขวัญ','ผจญภัย'];

  List<String> get _sortedGenres {
    final withNovels = _baseGenres.where((g) => g == 'ทั้งหมด' || _novels.any((n) => n.genre == g)).toList();
    final withoutNovels = _baseGenres.where((g) => g != 'ทั้งหมด' && !_novels.any((n) => n.genre == g)).toList();
    return [...withNovels, ...withoutNovels];
  }

  @override
  void initState() { super.initState(); _loadNovels(); }

  Future<void> _loadNovels() async {
    try {
      final sb = Supabase.instance.client;
      final novelsRes = await sb.from('novels').select().order('views', ascending: false);
      final List<NovelModel> loaded = [];
      for (final row in novelsRes as List) {
        final commentsRes = await sb.from('comments').select().eq('novel_id', row['id']).order('created_at', ascending: false);
        final likesRes = await sb.from('novel_likes').select().eq('novel_id', row['id']);
        loaded.add(NovelModel.fromSupabase(row, commentsRes as List, (likesRes as List).length));
      }
      if (mounted) setState(() { _novels = loaded; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<NovelModel> get _filteredNovels => _selectedGenre == 'ทั้งหมด' ? _novels : _novels.where((n) => n.genre == _selectedGenre).toList();
  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  Future<void> _refreshNovelStats(String novelId) async {
    try {
      final sb = Supabase.instance.client;
      final row = await sb.from('novels').select('views').eq('id', novelId).single();
      final likesRes = await sb.from('novel_likes').select('user_id').eq('novel_id', novelId);
      if (!mounted) return;
      setState(() {
        final idx = _novels.indexWhere((n) => n.id == novelId);
        if (idx != -1) _novels[idx] = _novels[idx].copyWith(views: row['views'] as int, likes: (likesRes as List).length);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: _textSub, size: 40), const SizedBox(height: 12),
        const Text('โหลดข้อมูลไม่สำเร็จ', style: TextStyle(color: _textPrim, fontSize: 15)), const SizedBox(height: 8),
        TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadNovels(); },
            child: const Text('ลองอีกครั้ง', style: TextStyle(color: _accent))),
      ]));
    }

    final novels = _filteredNovels;
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _sortedGenres.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final genre = _sortedGenres[i];
            final isSelected = genre == _selectedGenre;
            final hasNovels = genre == 'ทั้งหมด' || _novels.any((n) => n.genre == genre);
            return GestureDetector(
              onTap: hasNovels ? () => setState(() => _selectedGenre = genre) : () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating, backgroundColor: _card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _divider)),
                  duration: const Duration(seconds: 2),
                  content: Row(children: [
                    const Icon(Icons.lock_outline_rounded, color: _textSub, size: 16), const SizedBox(width: 8),
                    Text('หมวด "$genre" ยังไม่มีนิยาย', style: const TextStyle(color: _textSub, fontSize: 13)),
                  ]),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : _card, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _accent : _divider, width: isSelected ? 1.5 : 1.0),
                  boxShadow: isSelected ? [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!hasNovels) ...[const Icon(Icons.lock_outline_rounded, size: 11, color: _textSub), const SizedBox(width: 4)],
                  Text(genre, style: TextStyle(color: isSelected ? _bg : _textSub, fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0)),
                ]),
              ),
            );
          },
        ),
      ),
      const Divider(height: 1, color: _divider),
      Expanded(
        child: novels.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.menu_book_outlined, color: _textSub, size: 40), const SizedBox(height: 12),
                Text('ไม่มีนิยายในหมวด "$_selectedGenre"', style: const TextStyle(color: _textSub, fontSize: 14)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: novels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final novel = novels[index];
                  final coverColor = Color(int.parse('FF${novel.coverColor}', radix: 16));
                  final hasImage = novel.coverImage != null && novel.coverImage!.isNotEmpty;
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(novel: novel)));
                      if (mounted) _refreshNovelStats(novel.id);
                    },
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _divider),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          child: SizedBox(width: 90, child: hasImage
                              ? Image.network(novel.coverImage!, fit: BoxFit.cover, height: double.infinity,
                                  errorBuilder: (_, __, ___) => _CoverPlaceholder(color: coverColor, letter: novel.title.substring(0, 1)))
                              : _CoverPlaceholder(color: coverColor, letter: novel.title.substring(0, 1))),
                        ),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(6)),
                              child: Text(novel.genre, style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0)),
                            ),
                            Text(novel.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
                            Row(children: [
                              const Icon(Icons.person_outline_rounded, color: _textSub, size: 13), const SizedBox(width: 4),
                              Expanded(child: Text(novel.author, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _textSub, fontSize: 12))),
                              const Icon(Icons.remove_red_eye_outlined, color: _textSub, size: 13), const SizedBox(width: 4),
                              Text(_fmt(novel.views), style: const TextStyle(color: _textSub, fontSize: 12)),
                              const SizedBox(width: 10),
                              const Icon(Icons.favorite_rounded, color: _heart, size: 13), const SizedBox(width: 4),
                              Text(_fmt(novel.likes), style: const TextStyle(color: _textSub, fontSize: 12)),
                            ]),
                          ]),
                        )),
                        const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right_rounded, color: _textSub, size: 20)),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

// =============================================================================
// DetailPage
// =============================================================================
class DetailPage extends StatefulWidget {
  final NovelModel novel;
  const DetailPage({required this.novel, super.key});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin {
  late NovelModel _novel;
  bool _isLiked = false, _likeLoading = false;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _novel = widget.novel;
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut));
    _checkIfLiked();
    _incrementViews();
    _reloadComments();
  }

  @override
  void dispose() { _heartCtrl.dispose(); super.dispose(); }

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  Future<void> _incrementViews() async {
    try {
      await Supabase.instance.client.rpc('increment_novel_views', params: {'novel_id': _novel.id});
      if (mounted) setState(() => _novel = _novel.copyWith(views: _novel.views + 1));
    } catch (_) {}
  }

  Future<void> _checkIfLiked() async {
    try {
      final res = await Supabase.instance.client.from('novel_likes').select().eq('novel_id', _novel.id).eq('user_id', _userId).maybeSingle();
      if (mounted) setState(() => _isLiked = res != null);
    } catch (_) {}
  }

  Future<void> _reloadComments() async {
    try {
      final commentsRes = await Supabase.instance.client.from('comments').select().eq('novel_id', _novel.id).order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _novel = _novel.copyWith(
          comments: (commentsRes as List).map((c) => NovelComment(
            id: c['id'].toString(), userId: c['user_id'] as String? ?? '',
            username: c['username'] as String, text: c['text'] as String,
            timeAgo: _timeAgo(DateTime.parse(c['created_at'] as String).toLocal()),
            avatarUrl: c['avatar_url'] as String?, // ✅ เพิ่ม
          )).toList(),
        );
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);
    HapticFeedback.lightImpact();
    try {
      final sb = Supabase.instance.client;
      if (_isLiked) {
        await sb.from('novel_likes').delete().eq('novel_id', _novel.id).eq('user_id', _userId);
        if (mounted) setState(() { _isLiked = false; _novel = _novel.copyWith(likes: (_novel.likes - 1).clamp(0, 999999)); });
      } else {
        await sb.from('novel_likes').insert({'novel_id': _novel.id, 'user_id': _userId});
        if (mounted) {
          setState(() { _isLiked = true; _novel = _novel.copyWith(likes: _novel.likes + 1); });
          _heartCtrl.forward(from: 0);
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(_errSnack('เกิดข้อผิดพลาด ลองใหม่อีกครั้ง'));
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';
  void _openEpisodeSheet() => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EpisodeSheet(novel: _novel));

  @override
  Widget build(BuildContext context) {
    final coverColor = Color(int.parse('FF${_novel.coverColor}', radix: 16));
    final hasImage = _novel.coverImage != null && _novel.coverImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 320, pinned: true, backgroundColor: _bg, surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _textSub, size: 18), onPressed: () => Navigator.pop(context)),
          actions: [Padding(padding: const EdgeInsets.only(right: 8), child: _LikeButton(isLiked: _isLiked, likeCount: _novel.likes, loading: _likeLoading, scale: _heartScale, onTap: _toggleLike, fmt: _fmt))],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(fit: StackFit.expand, children: [
              if (hasImage) Image.network(_novel.coverImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _gradBg(coverColor)) else _gradBg(coverColor),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.3), _bg], stops: const [0, 0.5, 1]))),
              if (!hasImage) Center(child: Text(_novel.title.substring(0, 1), style: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 160, fontWeight: FontWeight.w900))),
              Positioned(bottom: 20, left: 24, right: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(8), border: Border.all(color: _accent.withOpacity(0.4))),
                    child: Text(_novel.genre, style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0))),
                const SizedBox(height: 8),
                Text(_novel.title, style: const TextStyle(color: _textPrim, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, color: _textSub, size: 15), const SizedBox(width: 5),
                  Text(_novel.author, style: const TextStyle(color: _textSub, fontSize: 13)), const SizedBox(width: 16),
                  const Icon(Icons.remove_red_eye_outlined, color: _textSub, size: 15), const SizedBox(width: 5),
                  Text('${_novel.views} ครั้ง', style: const TextStyle(color: _textSub, fontSize: 13)), const SizedBox(width: 16),
                  Icon(Icons.favorite_rounded, color: _isLiked ? _heart : _textSub, size: 15), const SizedBox(width: 5),
                  Text('${_fmt(_novel.likes)} ถูกใจ', style: const TextStyle(color: _textSub, fontSize: 13)),
                ]),
              ])),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 1.5, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(1)))),
            const SizedBox(height: 24),
            _CharacterPreview(novel: _novel),
            const Text("SYNOPSIS", style: TextStyle(color: _textSub, fontSize: 10, letterSpacing: 0, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(_novel.synopsis, style: const TextStyle(color: _textPrim, fontSize: 14, height: 1.7)),
            const SizedBox(height: 32),
            Container(height: 1, color: _divider),
            const SizedBox(height: 32),
            Row(children: [
              _BigLikeButton(isLiked: _isLiked, likeCount: _novel.likes, loading: _likeLoading, scale: _heartScale, onTap: _toggleLike, fmt: _fmt),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 54, child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]),
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _openEpisodeSheet,
                  icon: const Icon(Icons.menu_book_rounded, color: _bg, size: 20),
                  label: const Text("อ่านเลย", style: TextStyle(color: _bg, fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ))),
            ]),
            const SizedBox(height: 32),
            Container(height: 1, color: _divider),
            const SizedBox(height: 24),
            Row(children: [
              const Text("COMMENTS", style: TextStyle(color: _textSub, fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_novel.comments.length}', style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            if (_novel.comments.isEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
                  child: const Center(child: Text('ยังไม่มีความคิดเห็น เป็นคนแรกสิ!', style: TextStyle(color: _textSub, fontSize: 13)))),
            ..._novel.comments.map((c) {
              final localComment = c;
              return _CommentTile(
                key: ValueKey(localComment.id),
                comment: localComment,
                currentUserId: _userId,
                onDeleted: () => setState(() => _novel = _novel.copyWith(comments: _novel.comments.where((item) => item.id != localComment.id).toList())),
              );
            }),
            const SizedBox(height: 24),
            _CommentInput(novel: _novel, onCommentAdded: (nc) => setState(() => _novel = _novel.copyWith(comments: [nc, ..._novel.comments]))),
            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }
}

// =============================================================================
// _EpisodeSheet
// =============================================================================
class _EpisodeSheet extends StatefulWidget {
  final NovelModel novel;
  const _EpisodeSheet({required this.novel});
  @override
  State<_EpisodeSheet> createState() => _EpisodeSheetState();
}

class _EpisodeSheetState extends State<_EpisodeSheet> {
  List<EpisodeModel> _episodes = [];
  Map<String, int> _progress = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      final epRows = await sb.from('episodes').select().eq('novel_id', widget.novel.id).order('episode_num', ascending: true);
      final List<EpisodeModel> loaded = [];
      for (final row in epRows as List) {
        final lineRows = await sb.from('chat_lines').select().eq('episode_id', row['id']).order('order_num', ascending: true);
        loaded.add(EpisodeModel.fromSupabase(row, lineRows as List));
      }
      Map<String, int> prog = {};
      if (uid != null && loaded.isNotEmpty) {
        final progRows = await sb.from('reading_progress').select('episode_id, line_index').eq('user_id', uid).eq('novel_id', widget.novel.id);
        for (final p in progRows as List) {
          if (p['episode_id'] != null) prog[p['episode_id'] as String] = p['line_index'] as int;
        }
      }
      if (mounted) setState(() { _episodes = loaded; _progress = prog; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  bool _isUnlocked(int index) => true;

  _EpStatus _statusOf(EpisodeModel ep) {
    final saved = _progress[ep.id] ?? 0;
    if (saved == 0) return _EpStatus.notStarted;
    if (saved >= ep.chatLines.length) return _EpStatus.done;
    return _EpStatus.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.92, expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(color: _card, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: _divider))),
        child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _divider, borderRadius: BorderRadius.circular(2)))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [
            const Text('เลือกตอน', style: TextStyle(color: _textPrim, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (!_loading) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(20)),
                child: Text('${_episodes.length} ตอน', style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600))),
          ])),
          const Divider(height: 1, color: _divider),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _error != null
              ? Center(child: TextButton(onPressed: _load, child: const Text('โหลดไม่สำเร็จ — ลองอีกครั้ง', style: TextStyle(color: _accent))))
              : _episodes.isEmpty
              ? const Center(child: Text('ยังไม่มีตอน', style: TextStyle(color: _textSub)))
              : RefreshIndicator(color: _accent, backgroundColor: _card, onRefresh: _load,
                  child: ListView.separated(
                    controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _episodes.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final ep = _episodes[i];
                      final unlocked = _isUnlocked(i);
                      final status = _statusOf(ep);
                      final saved = _progress[ep.id] ?? 0;
                      return _EpisodeTile(
                        episode: ep, status: status, unlocked: unlocked, savedIdx: saved,
                        onTap: unlocked ? () async {
                          Navigator.pop(context);
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatReadPage(novel: widget.novel, episode: ep, initialIndex: status == _EpStatus.done ? 0 : saved)));
                          if (mounted) _load();
                        } : null,
                      );
                    },
                  ))),
        ]),
      ),
    );
  }
}

// =============================================================================
// _EpisodeTile
// =============================================================================
class _EpisodeTile extends StatelessWidget {
  final EpisodeModel episode;
  final _EpStatus status;
  final bool unlocked;
  final int savedIdx;
  final VoidCallback? onTap;
  const _EpisodeTile({required this.episode, required this.status, required this.unlocked, required this.savedIdx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = episode.chatLines.length;
    final progress = total > 0 ? (savedIdx / total).clamp(0.0, 1.0) : 0.0;
    Color badgeColor; String badgeText; IconData badgeIcon;
    if (!unlocked) { badgeColor = _textSub; badgeText = 'ล็อก'; badgeIcon = Icons.lock_rounded; }
    else { switch (status) {
      case _EpStatus.done: badgeColor = _colorC; badgeText = 'อ่านแล้ว'; badgeIcon = Icons.check_circle_rounded; break;
      case _EpStatus.inProgress: badgeColor = _colorD; badgeText = 'อ่านค้าง'; badgeIcon = Icons.schedule_rounded; break;
      case _EpStatus.notStarted: badgeColor = _accent; badgeText = 'ใหม่'; badgeIcon = Icons.fiber_new_rounded; break;
    }}
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? _surface : _bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: unlocked ? (status == _EpStatus.inProgress ? _colorD.withOpacity(0.5) : _divider) : _divider.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: unlocked ? _accentSoft : _divider.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                child: Center(child: unlocked ? Text('${episode.episodeNum}', style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w800)) : const Icon(Icons.lock_rounded, color: _textSub, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ตอนที่ ${episode.episodeNum}', style: TextStyle(color: unlocked ? _textSub : _textSub.withOpacity(0.4), fontSize: 11)),
              const SizedBox(height: 2),
              Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: unlocked ? _textPrim : _textSub.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withOpacity(0.35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(badgeIcon, color: badgeColor, size: 11), const SizedBox(width: 3),
                  Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600)),
                ])),
          ]),
          if (unlocked && status == _EpStatus.inProgress) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$savedIdx / $total บรรทัด', style: const TextStyle(color: _textSub, fontSize: 10)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: _colorD, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: _divider, valueColor: const AlwaysStoppedAnimation(_colorD), minHeight: 4)),
          ],
          if (!unlocked) ...[const SizedBox(height: 8), Text('อ่านตอนก่อนหน้าให้จบเพื่อปลดล็อก', style: TextStyle(color: _textSub.withOpacity(0.45), fontSize: 11, fontStyle: FontStyle.italic))],
          if (unlocked) ...[const SizedBox(height: 8), Row(children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: _textSub, size: 12), const SizedBox(width: 4),
            Text('$total บรรทัด', style: const TextStyle(color: _textSub, fontSize: 11)),
            const Spacer(),
            if (status != _EpStatus.done) const Row(children: [Icon(Icons.play_arrow_rounded, color: _accent, size: 16), SizedBox(width: 2), Text('อ่าน', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600))])
            else const Row(children: [Icon(Icons.replay_rounded, color: _textSub, size: 14), SizedBox(width: 2), Text('อ่านใหม่', style: TextStyle(color: _textSub, fontSize: 11))]),
          ])],
        ]),
      ),
    );
  }
}

// =============================================================================
// ChatReadPage
// =============================================================================
class ChatReadPage extends StatefulWidget {
  final NovelModel novel;
  final EpisodeModel episode;
  final int initialIndex;
  const ChatReadPage({super.key, required this.novel, required this.episode, this.initialIndex = 0});
  @override
  State<ChatReadPage> createState() => _ChatReadPageState();
}

class _ChatReadPageState extends State<ChatReadPage> {
  late final String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final List<ChatLine> _visible = [];
  final ScrollController _scroll = ScrollController();
  final _sb = Supabase.instance.client;
  int _index = 0;
  bool _finished = false, _animating = false, _isJapanese = false, _isTranslating = false;
  final Map<int, String> _jpTranslations = {};
  EpisodeModel? _nextEpisode;
  List<ChatLine> get _allLines => widget.episode.chatLines;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { _initReading(); _checkNextEpisode(); });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _checkNextEpisode() async {
    try {
      final epRes = await _sb.from('episodes').select().eq('novel_id', widget.novel.id).eq('episode_num', widget.episode.episodeNum + 1).maybeSingle();
      if (epRes != null && mounted) {
        final lineRows = await _sb.from('chat_lines').select().eq('episode_id', epRes['id']).order('order_num', ascending: true);
        setState(() => _nextEpisode = EpisodeModel.fromSupabase(epRes, lineRows as List));
      }
    } catch (e) { debugPrint('หาตอนต่อไปไม่เจอ: $e'); }
  }

  Future<String> _translateWithAI(String text) async {
    if (geminiApiKey.isEmpty) return text;
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
      final response = await model.generateContent([Content.text('แปลประโยคนี้เป็นภาษาญี่ปุ่น (ใช้ภาษาพูดทั่วไปในชีวิตประจำวัน) ตอบกลับแค่คำแปลเพียวๆ ห้ามมีคำอธิบาย: "$text"')]);
      return response.text?.trim().replaceAll('"', '') ?? text;
    } catch (e) { return text; }
  }

  Future<List<String>> _translateBatch(List<String> texts) async {
    if (geminiApiKey.isEmpty) return [];
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
      final prompt = 'แปลประโยคทั้งหมดนี้เป็นภาษาญี่ปุ่น (ใช้ภาษาพูดทั่วไปในชีวิตประจำวัน)\nข้อกำหนดสำคัญ:\n1. ตอบกลับเป็น JSON Array ของ String เท่านั้น ห้ามมี Key หรือคำอธิบายเพิ่มเติม\n2. ต้องแปลให้ครบทุกประโยค ห้ามข้าม รวบ หรือตัดประโยคทิ้งเด็ดขาด\n3. สำคัญมาก: จำนวนประโยคที่แปลกลับมาต้องมีทั้งหมด ${texts.length} ประโยคเป๊ะๆ เท่ากับต้นฉบับ\nตัวอย่างผลลัพธ์: ["แปลประโยค 1", "แปลประโยค 2"]\n\nข้อความต้นฉบับ:\n${jsonEncode(texts)}';
      final response = await model.generateContent([Content.text(prompt)]);
      String responseText = response.text?.trim() ?? '[]';
      if (responseText.startsWith('```json')) responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      else if (responseText.startsWith('```')) responseText = responseText.replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(responseText);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) { debugPrint('Batch Translation Error: $e'); return []; }
  }

  Future<void> _toggleLanguage() async {
    if (geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาใส่ API Key ของ Gemini ในโค้ดก่อนครับ'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isJapanese = !_isJapanese);
    if (_isJapanese) await _translateAllEpisodeLines();
  }

  Future<void> _translateAllEpisodeLines() async {
    if (_jpTranslations.length == _allLines.length) return;
    if (_isTranslating) return;
    setState(() => _isTranslating = true);
    try {
      final allTexts = _allLines.map((e) => e.text).toList();
      final results = await _translateBatch(allTexts);
      if (results.length == allTexts.length) {
        if (mounted) setState(() { for (int i = 0; i < allTexts.length; i++) _jpTranslations[i] = results[i]; });
      } else {
        for (int i = 0; i < allTexts.length; i++) {
          if (!mounted) break;
          if (!_jpTranslations.containsKey(i)) {
            final t = await _translateWithAI(allTexts[i]);
            if (mounted) setState(() => _jpTranslations[i] = t);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }
    } catch (e) { debugPrint('Error translating episode: $e'); }
    finally { if (mounted) setState(() => _isTranslating = false); }
  }

  Future<void> _initReading() async {
    final saved = widget.initialIndex;
    if (saved > 0 && saved < _allLines.length) {
      setState(() { _visible.addAll(_allLines.take(saved)); _index = saved; });
      await Future.delayed(const Duration(milliseconds: 150));
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
    if (mounted) _revealNext();
  }

  Future<void> _saveProgress() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return;
      await _sb.from('reading_progress').upsert({'user_id': uid, 'novel_id': widget.novel.id, 'episode_id': widget.episode.id, 'line_index': _finished ? _allLines.length : _index, 'total_lines': _allLines.length}, onConflict: 'user_id,novel_id,episode_id');
    } catch (_) {}
  }

  Future<void> _restartReading() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) await _sb.from('reading_progress').delete().eq('user_id', uid).eq('episode_id', widget.episode.id);
    } catch (_) {}
    setState(() { _visible.clear(); _index = 0; _finished = false; _animating = false; });
    if (_scroll.hasClients) await _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (mounted) _revealNext();
  }

  Future<void> _revealNext() async {
    if (_animating || _finished) return;
    if (_index >= _allLines.length) { setState(() => _finished = true); _saveProgress(); return; }
    _animating = true;
    try {
      setState(() { _visible.add(_allLines[_index]); _index++; });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) await _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      if (_index >= _allLines.length) setState(() => _finished = true);
      _saveProgress();
    } finally { _animating = false; }
  }

  @override
  Widget build(BuildContext context) {
    final total = _allLines.length;
    final progress = total > 0 ? _index / total : 0.0;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface, surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _textSub, size: 18), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.novel.title, style: const TextStyle(color: _textPrim, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0)),
          Text('ตอนที่ ${widget.episode.episodeNum}: ${widget.episode.title}', style: const TextStyle(color: _textSub, fontSize: 11, letterSpacing: 0)),
        ]),
        actions: [
          if (_isTranslating) const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))),
          Padding(padding: const EdgeInsets.only(right: 12), child: TextButton(
            onPressed: _toggleLanguage,
            style: TextButton.styleFrom(backgroundColor: _accentSoft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size(40, 30), padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: Text(_isJapanese ? 'TH' : 'JP', style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
          )),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LayoutBuilder(builder: (_, c) => Stack(children: [
            Container(height: 3, color: _divider),
            AnimatedContainer(duration: const Duration(milliseconds: 300), height: 3, width: c.maxWidth * progress, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]))),
          ])),
        ),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: _visible.length,
          itemBuilder: (_, i) => _AnimatedBubble(key: ValueKey(i), line: _visible[i], novel: widget.novel, isJapanese: _isJapanese, translatedText: _jpTranslations[i]),
        )),
        if (_finished)
          _FinishedBar(onBack: () => Navigator.pop(context), onRestart: _restartReading, nextEpisode: _nextEpisode, novel: widget.novel)
        else
          GestureDetector(onTap: _revealNext, behavior: HitTestBehavior.opaque, child: _TapHintBar(current: _index, total: total)),
      ]),
    );
  }
}

// =============================================================================
// _TapHintBar
// =============================================================================
class _TapHintBar extends StatefulWidget {
  final int current, total;
  const _TapHintBar({required this.current, required this.total});
  @override
  State<_TapHintBar> createState() => _TapHintBarState();
}

class _TapHintBarState extends State<_TapHintBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.18, width: double.infinity,
    decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _divider, width: 1.5))),
    child: Stack(children: [
      Center(child: FadeTransition(opacity: _anim, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.touch_app_outlined, color: _accent.withOpacity(0.8), size: 32), const SizedBox(height: 8),
        Text('แตะบริเวณนี้เพื่ออ่านต่อ', style: TextStyle(color: _accent.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
      ]))),
      Positioned(bottom: 16, left: 24, child: Text('${widget.current} / ${widget.total}', style: const TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

// =============================================================================
// _FinishedBar
// =============================================================================
class _FinishedBar extends StatelessWidget {
  final VoidCallback onBack, onRestart;
  final EpisodeModel? nextEpisode;
  final NovelModel novel;
  const _FinishedBar({required this.onBack, required this.onRestart, this.nextEpisode, required this.novel});

  @override
  Widget build(BuildContext context) {
    final hasNext = nextEpisode != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(color: _card, border: Border(top: BorderSide(color: _divider))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 40, height: 1, color: _divider),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('— จบตอน —', style: TextStyle(color: _textSub, fontSize: 13, letterSpacing: 0))),
          Container(width: 40, height: 1, color: _divider),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SizedBox(height: 46, child: OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay_rounded, color: _accent, size: 18),
            label: const Text('อ่านใหม่', style: TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _accent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 46, child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: hasNext ? const LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]) : const LinearGradient(colors: [_surface, _surface]),
              border: hasNext ? null : Border.all(color: _divider),
              boxShadow: hasNext ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: ElevatedButton.icon(
              onPressed: () { if (hasNext) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatReadPage(novel: novel, episode: nextEpisode!, initialIndex: 0))); else onBack(); },
              icon: Icon(hasNext ? Icons.skip_next_rounded : Icons.arrow_back_rounded, color: hasNext ? _bg : _textPrim, size: 18),
              label: Text(hasNext ? 'ตอนต่อไป' : 'กลับ', style: TextStyle(color: hasNext ? _bg : _textPrim, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ))),
        ]),
      ]),
    );
  }
}

// =============================================================================
// _AnimatedBubble
// =============================================================================
class _AnimatedBubble extends StatefulWidget {
  final ChatLine line; final NovelModel novel; final bool isJapanese; final String? translatedText;
  const _AnimatedBubble({super.key, required this.line, required this.novel, this.isJapanese = false, this.translatedText});
  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: _ChatBubble(line: widget.line, novel: widget.novel, isJapanese: widget.isJapanese, translatedText: widget.translatedText)));
}

// =============================================================================
// _ChatBubble
// =============================================================================
class _ChatBubble extends StatelessWidget {
  final ChatLine line; final NovelModel novel; final bool isJapanese; final String? translatedText;
  const _ChatBubble({super.key, required this.line, required this.novel, this.isJapanese = false, this.translatedText});

  @override
  Widget build(BuildContext context) {
    final displayText = isJapanese ? (translatedText ?? '${line.text} ...') : line.text;
    const jpFallback = ['Noto Sans JP', 'Meiryo', 'Hiragino Kaku Gothic ProN'];

    if (line.sender == Sender.narrator) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _divider)),
        child: Text(displayText, textAlign: TextAlign.center, style: TextStyle(color: _textPrim, fontSize: isJapanese ? 14 : 13, fontStyle: isJapanese ? FontStyle.normal : FontStyle.italic, height: 1.5, fontFamilyFallback: isJapanese ? jpFallback : null)),
      )));
    }

    final cfg = _configFor(line.sender, novel);
    final isLeft = cfg.isLeft;
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4, left: isLeft ? 0 : 56, right: isLeft ? 56 : 0),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLeft) ...[_AvatarWithName(config: cfg), const SizedBox(width: 8)],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLeft ? cfg.color.withOpacity(0.10) : cfg.color.withOpacity(0.18),
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isLeft ? 4 : 16), bottomRight: Radius.circular(isLeft ? 16 : 4)),
              border: Border.all(color: cfg.color.withOpacity(0.35)),
            ),
            child: Text(displayText, style: TextStyle(color: _textPrim, fontSize: isJapanese ? 16 : 14, height: 1.5, fontFamilyFallback: isJapanese ? jpFallback : null)),
          )),
          if (!isLeft) ...[const SizedBox(width: 8), _AvatarWithName(config: cfg)],
        ],
      ),
    );
  }
}

// =============================================================================
// _CharacterPreview
// =============================================================================
class _CharacterPreview extends StatelessWidget {
  final NovelModel novel;
  const _CharacterPreview({required this.novel});

  @override
  Widget build(BuildContext context) {
    final chars = <({_CharConfig cfg, String label})>[];
    if (novel.charAName != null || novel.charAImage != null) chars.add((cfg: _configFor(Sender.characterA, novel), label: _configFor(Sender.characterA, novel).name));
    if (novel.charBName != null || novel.charBImage != null) chars.add((cfg: _configFor(Sender.characterB, novel), label: _configFor(Sender.characterB, novel).name));
    if (novel.charCName != null || novel.charCImage != null) chars.add((cfg: _configFor(Sender.characterC, novel), label: _configFor(Sender.characterC, novel).name));
    if (novel.charDName != null || novel.charDImage != null) chars.add((cfg: _configFor(Sender.characterD, novel), label: _configFor(Sender.characterD, novel).name));
    if (chars.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("CHARACTERS", style: TextStyle(color: _textSub, fontSize: 10, letterSpacing: 0, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(children: chars.map((e) => Padding(padding: const EdgeInsets.only(right: 20), child: Column(children: [
        _AvatarCircle(config: e.cfg, radius: 28, borderWidth: 2.5), const SizedBox(height: 6),
        Text(e.label, style: TextStyle(color: e.cfg.color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]))).toList())),
      const SizedBox(height: 24),
    ]);
  }
}

// =============================================================================
// _AvatarCircle
// =============================================================================
class _AvatarCircle extends StatelessWidget {
  final _CharConfig config; final double radius; final double borderWidth;
  const _AvatarCircle({required this.config, this.radius = 18, this.borderWidth = 1.5});
  @override
  Widget build(BuildContext context) {
    final hasImage = config.imageUrl != null && config.imageUrl!.isNotEmpty;
    final initial = config.name.isNotEmpty ? config.name.substring(0, 1) : '?';
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: config.color, width: borderWidth), boxShadow: [BoxShadow(color: config.color.withOpacity(0.3), blurRadius: 8)]),
      child: CircleAvatar(radius: radius, backgroundColor: config.color.withOpacity(0.15), backgroundImage: hasImage ? NetworkImage(config.imageUrl!) : null,
          child: hasImage ? null : Text(initial, style: TextStyle(color: config.color, fontSize: radius * 0.65, fontWeight: FontWeight.w800))),
    );
  }
}

// =============================================================================
// _AvatarWithName
// =============================================================================
class _AvatarWithName extends StatelessWidget {
  final _CharConfig config;
  const _AvatarWithName({required this.config});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    _AvatarCircle(config: config), const SizedBox(height: 3),
    Text(config.name, style: TextStyle(color: config.color, fontSize: 9, fontWeight: FontWeight.w600)),
  ]);
}

// =============================================================================
// _LikeButton
// =============================================================================
class _LikeButton extends StatelessWidget {
  final bool isLiked; final int likeCount; final bool loading;
  final Animation<double> scale; final VoidCallback onTap; final String Function(int) fmt;
  const _LikeButton({required this.isLiked, required this.likeCount, required this.loading, required this.scale, required this.onTap, required this.fmt});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: isLiked ? _heartSoft : _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isLiked ? _heart.withOpacity(0.5) : _divider)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _heart, strokeWidth: 2))
              : ScaleTransition(scale: scale, child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? _heart : _textSub, size: 18)),
      const SizedBox(width: 5),
      Text(fmt(likeCount), style: TextStyle(color: isLiked ? _heart : _textSub, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  ));
}

// =============================================================================
// _BigLikeButton
// =============================================================================
class _BigLikeButton extends StatelessWidget {
  final bool isLiked; final int likeCount; final bool loading;
  final Animation<double> scale; final VoidCallback onTap; final String Function(int) fmt;
  const _BigLikeButton({required this.isLiked, required this.likeCount, required this.loading, required this.scale, required this.onTap, required this.fmt});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 250), width: 54, height: 54,
    decoration: BoxDecoration(
      color: isLiked ? _heartSoft : _card, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isLiked ? _heart.withOpacity(0.6) : _divider, width: isLiked ? 1.5 : 1.0),
      boxShadow: isLiked ? [BoxShadow(color: _heart.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))] : [],
    ),
    child: loading
        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _heart, strokeWidth: 2)))
        : ScaleTransition(scale: scale, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? _heart : _textSub, size: 22),
            const SizedBox(height: 2),
            Text(fmt(likeCount), style: TextStyle(color: isLiked ? _heart : _textSub, fontSize: 10, fontWeight: FontWeight.w700)),
          ])),
  ));
}

// =============================================================================
// _CommentTile
// =============================================================================
class _CommentTile extends StatefulWidget {
  final NovelComment comment;
  final String currentUserId;
  final VoidCallback onDeleted;
  const _CommentTile({super.key, required this.comment, required this.currentUserId, required this.onDeleted});
  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _isDeleting = false;

  Future<void> _deleteComment() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _divider)),
      title: const Text('ลบคอมเมนต์?', style: TextStyle(color: _textPrim, fontSize: 16, fontWeight: FontWeight.w700)),
      content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบคอมเมนต์นี้?', style: TextStyle(color: _textSub, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก', style: TextStyle(color: _textSub))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('ลบเลย', style: TextStyle(color: _bg, fontWeight: FontWeight.w700))),
      ],
    ));
    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await Supabase.instance.client.from('comments').delete().eq('id', widget.comment.id);
        widget.onDeleted();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(_errSnack('ลบไม่สำเร็จ: $e'));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) return const SizedBox.shrink();
    final isMyComment = widget.comment.userId == widget.currentUserId;
    final hasAvatar = widget.comment.avatarUrl != null && widget.comment.avatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ✅ แสดงรูปโปรไฟล์
        CircleAvatar(
          radius: 18,
          backgroundColor: _accentSoft,
          backgroundImage: hasAvatar ? NetworkImage(widget.comment.avatarUrl!) : null,
          child: hasAvatar ? null : Text(
            widget.comment.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.comment.username, style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
              Row(children: [
                Text(widget.comment.timeAgo, style: const TextStyle(color: _textSub, fontSize: 11)),
                if (isMyComment) ...[const SizedBox(width: 8), GestureDetector(onTap: _deleteComment, child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 15))],
              ]),
            ]),
            const SizedBox(height: 6),
            Text(widget.comment.text, style: const TextStyle(color: _textPrim, fontSize: 13, height: 1.5)),
          ]),
        )),
      ]),
    );
  }
}

// =============================================================================
// _CommentInput
// =============================================================================
class _CommentInput extends StatefulWidget {
  final NovelModel novel;
  final ValueChanged<NovelComment> onCommentAdded;
  const _CommentInput({required this.novel, required this.onCommentAdded});
  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      final sb = Supabase.instance.client;
      final user = sb.auth.currentUser;

      String username = 'ผู้อ่านนิรนาม';
      String? avatarUrl;
      try {
        final profile = await sb.from('profiles').select('full_name, avatar_url').eq('id', user!.id).single();
        username = (profile['full_name'] as String?)?.trim().isNotEmpty == true
            ? profile['full_name'] as String
            : user.email?.split('@').first ?? 'ผู้อ่านนิรนาม';
        avatarUrl = profile['avatar_url'] as String?;
      } catch (e) { debugPrint('PROFILE ERROR: $e'); }

      final inserted = await sb.from('comments').insert({
        'novel_id': widget.novel.id,
        'user_id': user!.id,
        'username': username,
        'avatar_url': avatarUrl, // ✅ ส่ง avatar_url
        'text': text,
      }).select().single();

      final newComment = NovelComment(
        id: inserted['id'].toString(),
        userId: inserted['user_id'] as String? ?? '',
        username: username,
        text: text,
        timeAgo: 'เพิ่งเมื่อกี้',
        avatarUrl: avatarUrl, // ✅ ใส่ใน model
      );

      if (!mounted) return;
      widget.onCommentAdded(newComment);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating, backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _accent)),
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: _accent, size: 18), SizedBox(width: 8),
          Text('ส่ง comment แล้ว!', style: TextStyle(color: _textPrim, fontSize: 13)),
        ]),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errSnack('ส่งไม่สำเร็จ: $e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextField(
      controller: _ctrl, style: const TextStyle(color: _textPrim, fontSize: 14), maxLines: null,
      decoration: InputDecoration(
        hintText: 'แสดงความคิดเห็น...', hintStyle: const TextStyle(color: _textSub, fontSize: 13),
        filled: true, fillColor: _card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
    )),
    const SizedBox(width: 10),
    GestureDetector(onTap: _submit, child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: _sending ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _bg, strokeWidth: 2))) : const Icon(Icons.send_rounded, color: _bg, size: 20),
    )),
  ]);
}