import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fanfic_page.dart';
import 'novel_preview_page.dart';

const _bg = Color(0xFF080C14);
const _surface = Color(0xFF0F1520);
const _card = Color(0xFF141C2E);
const _accent = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim = Color(0xFFE8F0FF);
const _textSub = Color(0xFF6B7FA3);
const _divider = Color(0xFF1E2A42);
const _success = Color(0xFF34D399);
const _successSoft = Color(0x2234D399);
const _error = Color(0xFFFF4D6D);

const _colorA = Color(0xFF38BEFF);
const _colorB = Color(0xFF9B8FFF);
const _colorC = Color(0xFF4ECDC4);
const _colorD = Color(0xFFFFB347);

const _genres = [
  'โรแมนติก',
  'แฟนตาซี',
  'ระทึกขวัญ',
  'ดราม่า',
  'ตลก',
  'ผจญภัย',
  'วิทยาศาสตร์',
  'สยองขวัญ',
  'ประวัติศาสตร์',
  'อื่นๆ',
];

const _senders = [
  ('narrator', 'ผู้บรรยาย', _textSub),
  ('characterA', 'ตัวละคร A', _colorA),
  ('characterB', 'ตัวละคร B', _colorB),
  ('characterC', 'ตัวละคร C', _colorC),
  ('characterD', 'ตัวละคร D', _colorD),
];

const _senderLabel = {
  'narrator': 'ผู้บรรยาย',
  'characterA': 'ตัวละคร A',
  'characterB': 'ตัวละคร B',
  'characterC': 'ตัวละคร C',
  'characterD': 'ตัวละคร D',
};

const _senderColor = {
  'narrator': _textSub,
  'characterA': _colorA,
  'characterB': _colorB,
  'characterC': _colorC,
  'characterD': _colorD,
};

String _displaySenderName(String sender, Map<String, String> charNames) {
  if (sender == 'narrator') return 'ผู้บรรยาย';
  final customName = charNames[sender]?.trim();
  if (customName != null && customName.isNotEmpty) return customName;
  return _senderLabel[sender] ?? sender;
}

// =============================================================================
// Models
// =============================================================================
class _LineEntry {
  String sender, text;
  _LineEntry({required this.sender, required this.text});
}

class _EpisodeDraft {
  String title;
  List<_LineEntry> lines;
  _EpisodeDraft({required this.title, List<_LineEntry>? lines})
    : lines = lines ?? [];
}

// =============================================================================
// Draft storage
// =============================================================================
class _Draft {
  static const storageKey = 'fiction_write_draft';
  static const draftsStorageKey = 'fiction_write_drafts';
  static const legacyDraftId = 'legacy';
  static final titleCtrl = TextEditingController();
  static final authorCtrl = TextEditingController();
  static final synopsisCtrl = TextEditingController();
  static final charACtrl = TextEditingController();
  static final charBCtrl = TextEditingController();
  static final charCCtrl = TextEditingController();
  static final charDCtrl = TextEditingController();

  static String genre = 'โรแมนติก';
  static String coverColor = '38BEFF';
  static Uint8List? coverBytes;

  static Uint8List? charABytes;
  static Uint8List? charBBytes;
  static Uint8List? charCBytes;
  static Uint8List? charDBytes;
  static String? existingNovelId;
  static String? currentDraftId;
  static int episodeOffset = 0;

  // ✅ เปลี่ยนจาก lines เดี่ยว → list of episodes
  static List<_EpisodeDraft> episodes = [_EpisodeDraft(title: 'ตอนที่ 1')];

  static void clear() {
    titleCtrl.text = '';
    authorCtrl.text = '';
    synopsisCtrl.text = '';
    charACtrl.text = '';
    charBCtrl.text = '';
    charCCtrl.text = '';
    charDCtrl.text = '';
    genre = 'โรแมนติก';
    coverColor = '38BEFF';
    coverBytes = null;
    charABytes = null;
    charBBytes = null;
    charCBytes = null;
    charDBytes = null;
    existingNovelId = null;
    currentDraftId = null;
    episodeOffset = 0;
    episodes = [_EpisodeDraft(title: 'ตอนที่ 1')];
  }

  static Map<String, dynamic> toJson() => {
    'title': titleCtrl.text,
    'author': authorCtrl.text,
    'synopsis': synopsisCtrl.text,
    'charA': charACtrl.text,
    'charB': charBCtrl.text,
    'charC': charCCtrl.text,
    'charD': charDCtrl.text,
    'genre': genre,
    'coverColor': coverColor,
    'coverBytes': coverBytes == null ? null : base64Encode(coverBytes!),
    'charABytes': charABytes == null ? null : base64Encode(charABytes!),
    'charBBytes': charBBytes == null ? null : base64Encode(charBBytes!),
    'charCBytes': charCBytes == null ? null : base64Encode(charCBytes!),
    'charDBytes': charDBytes == null ? null : base64Encode(charDBytes!),
    'existingNovelId': existingNovelId,
    'episodeOffset': episodeOffset,
    'episodes': episodes
        .map(
          (episode) => {
            'title': episode.title,
            'lines': episode.lines
                .map((line) => {'sender': line.sender, 'text': line.text})
                .toList(),
          },
        )
        .toList(),
  };

  static void restore(Map<String, dynamic> data) {
    titleCtrl.text = data['title'] as String? ?? '';
    authorCtrl.text = data['author'] as String? ?? '';
    synopsisCtrl.text = data['synopsis'] as String? ?? '';
    charACtrl.text = data['charA'] as String? ?? '';
    charBCtrl.text = data['charB'] as String? ?? '';
    charCCtrl.text = data['charC'] as String? ?? '';
    charDCtrl.text = data['charD'] as String? ?? '';
    genre = data['genre'] as String? ?? 'โรแมนติก';
    coverColor = data['coverColor'] as String? ?? '38BEFF';
    Uint8List? decodeImage(String key) {
      final value = data[key] as String?;
      return value == null ? null : base64Decode(value);
    }

    coverBytes = decodeImage('coverBytes');
    charABytes = decodeImage('charABytes');
    charBBytes = decodeImage('charBBytes');
    charCBytes = decodeImage('charCBytes');
    charDBytes = decodeImage('charDBytes');
    existingNovelId = data['existingNovelId'] as String?;
    episodeOffset = data['episodeOffset'] as int? ?? 0;
    final savedEpisodes = data['episodes'] as List<dynamic>? ?? const [];
    episodes = savedEpisodes.map((value) {
      final episode = value as Map<String, dynamic>;
      final lines = episode['lines'] as List<dynamic>? ?? const [];
      return _EpisodeDraft(
        title: episode['title'] as String? ?? '',
        lines: lines.map((value) {
          final line = value as Map<String, dynamic>;
          return _LineEntry(
            sender: line['sender'] as String? ?? 'narrator',
            text: line['text'] as String? ?? '',
          );
        }).toList(),
      );
    }).toList();
    if (episodes.isEmpty) episodes = [_EpisodeDraft(title: 'ตอนที่ 1')];
  }

  static Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(draftsStorageKey);
    final drafts = saved == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(saved) as Map<String, dynamic>).map(
            (id, value) =>
                MapEntry(id, Map<String, dynamic>.from(value as Map)),
          );
    final legacy = prefs.getString(storageKey);
    if (legacy != null) {
      drafts.putIfAbsent(
        legacyDraftId,
        () => Map<String, dynamic>.from(
          jsonDecode(legacy) as Map<String, dynamic>,
        ),
      );
      await prefs.remove(storageKey);
      await prefs.setString(draftsStorageKey, jsonEncode(drafts));
    }
    return drafts;
  }

  static Future<void> saveCurrent() async {
    final id = currentDraftId;
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final drafts = await loadAll();
    drafts[id] = toJson();
    await prefs.setString(draftsStorageKey, jsonEncode(drafts));
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await loadAll();
    drafts.remove(id);
    if (drafts.isEmpty) {
      await prefs.remove(draftsStorageKey);
    } else {
      await prefs.setString(draftsStorageKey, jsonEncode(drafts));
    }
  }
}

// =============================================================================
// WriteFicPage
// =============================================================================
class WriteFicPage extends StatefulWidget {
  final VoidCallback? onPublishSuccess;
  final bool startFresh;
  final String? continueNovelId;
  final String? draftId;
  const WriteFicPage({
    super.key,
    this.onPublishSuccess,
    this.startFresh = false,
    this.continueNovelId,
    this.draftId,
  });
  @override
  State<WriteFicPage> createState() => _WriteFicPageState();
}

class _WriteFicPageState extends State<WriteFicPage>
    with TickerProviderStateMixin {
  int _step = 0;
  bool get _hasDraft =>
      _titleCtrl.text.trim().isNotEmpty ||
      _authorCtrl.text.trim().isNotEmpty ||
      _synopsisCtrl.text.trim().isNotEmpty ||
      _episodes.any((e) => e.lines.isNotEmpty);

  TextEditingController get _titleCtrl => _Draft.titleCtrl;
  TextEditingController get _authorCtrl => _Draft.authorCtrl;
  TextEditingController get _synopsisCtrl => _Draft.synopsisCtrl;
  TextEditingController get _charACtrl => _Draft.charACtrl;
  TextEditingController get _charBCtrl => _Draft.charBCtrl;
  TextEditingController get _charCCtrl => _Draft.charCCtrl;
  TextEditingController get _charDCtrl => _Draft.charDCtrl;

  String get _genre => _Draft.genre;
  String get _coverColor => _Draft.coverColor;
  Uint8List? get _coverBytes => _Draft.coverBytes;
  Uint8List? get _charABytes => _Draft.charABytes;
  Uint8List? get _charBBytes => _Draft.charBBytes;
  Uint8List? get _charCBytes => _Draft.charCBytes;
  Uint8List? get _charDBytes => _Draft.charDBytes;

  List<_EpisodeDraft> get _episodes => _Draft.episodes;
  Map<String, String> get _charNames => {
    'characterA': _charACtrl.text.trim(),
    'characterB': _charBCtrl.text.trim(),
    'characterC': _charCCtrl.text.trim(),
    'characterD': _charDCtrl.text.trim(),
  };

  bool _publishing = false;
  bool _initializing = false;
  String? _publishErr;
  Timer? _draftSaveTimer;

  late final AnimationController _stepAnim;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
    if (widget.startFresh || widget.continueNovelId != null) {
      _Draft.clear();
      _Draft.currentDraftId =
          widget.draftId ?? DateTime.now().microsecondsSinceEpoch.toString();
      _Draft.existingNovelId = widget.continueNovelId;
    } else {
      _Draft.clear();
      _Draft.currentDraftId = widget.draftId;
      _restoreDraft();
    }
    for (final controller in [
      _titleCtrl,
      _authorCtrl,
      _synopsisCtrl,
      _charACtrl,
      _charBCtrl,
      _charCCtrl,
      _charDCtrl,
    ]) {
      controller.addListener(_scheduleDraftSave);
    }
    if (widget.continueNovelId != null) {
      _initializing = true;
      _step = 1;
      _loadContinuation(widget.continueNovelId!);
    }
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    for (final controller in [
      _titleCtrl,
      _authorCtrl,
      _synopsisCtrl,
      _charACtrl,
      _charBCtrl,
      _charCCtrl,
      _charDCtrl,
    ]) {
      controller.removeListener(_scheduleDraftSave);
    }
    _stepAnim.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    try {
      final drafts = await _Draft.loadAll();
      final draftId = _Draft.currentDraftId;
      if (draftId == null) return;
      final saved = drafts[draftId];
      if (saved == null) return;
      _Draft.restore(saved);
      if (_Draft.existingNovelId != null) {
        _step = 1;
        await _loadContinuation(_Draft.existingNovelId!, preserveDraft: true);
      } else if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Restore writing draft failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เปิดฉบับร่างไม่สำเร็จ กรุณาตรวจสอบข้อมูลที่บันทึกไว้',
            ),
          ),
        );
      }
    }
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    try {
      await _Draft.saveCurrent();
    } catch (e) {
      debugPrint('Save writing draft failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกฉบับร่างไม่สำเร็จ')),
        );
      }
    }
  }

  Future<void> _loadContinuation(
    String novelId, {
    bool preserveDraft = false,
  }) async {
    if (mounted) setState(() => _initializing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนเขียนตอนต่อ');
      final sb = Supabase.instance.client;
      final novel = await sb
          .from('novels')
          .select()
          .eq('id', novelId)
          .eq('user_id', user.id)
          .single();
      final latestEpisode = await sb
          .from('episodes')
          .select('episode_num')
          .eq('novel_id', novelId)
          .order('episode_num', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextEpisodeNum = (latestEpisode?['episode_num'] as int? ?? 1) + 1;

      if (!preserveDraft || _Draft.existingNovelId != novelId) {
        _Draft.clear();
        _Draft.titleCtrl.text = novel['title'] as String? ?? '';
        _Draft.authorCtrl.text = novel['author'] as String? ?? '';
        _Draft.synopsisCtrl.text = novel['synopsis'] as String? ?? '';
        _Draft.genre = novel['genre'] as String? ?? 'โรแมนติก';
        _Draft.coverColor = novel['cover_color'] as String? ?? '38BEFF';
        _Draft.charACtrl.text = novel['char_a_name'] as String? ?? '';
        _Draft.charBCtrl.text = novel['char_b_name'] as String? ?? '';
        _Draft.charCCtrl.text = novel['char_c_name'] as String? ?? '';
        _Draft.charDCtrl.text = novel['char_d_name'] as String? ?? '';
        _Draft.episodes = [_EpisodeDraft(title: 'ตอนที่ $nextEpisodeNum')];
      }
      _Draft.existingNovelId = novelId;
      _Draft.episodeOffset = nextEpisodeNum - 1;
      if (mounted) setState(() => _initializing = false);
      _scheduleDraftSave();
    } catch (e) {
      debugPrint('Load novel for continuation failed: $e');
      if (mounted)
        setState(() {
          _initializing = false;
          _publishErr = 'โหลดนิยายเพื่อเขียนตอนต่อไม่สำเร็จ: $e';
        });
    }
  }

  void _goStep(int next) {
    _stepAnim.forward(from: 0);
    setState(() => _step = next);
  }

  Future<void> _pickCover() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _Draft.coverBytes = bytes);
    _scheduleDraftSave();
  }

  Future<void> _pickCharImage(String key) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      switch (key) {
        case 'A':
          _Draft.charABytes = bytes;
          break;
        case 'B':
          _Draft.charBBytes = bytes;
          break;
        case 'C':
          _Draft.charCBytes = bytes;
          break;
        case 'D':
          _Draft.charDBytes = bytes;
          break;
      }
    });
    _scheduleDraftSave();
  }

  void _removeCharImage(String key) {
    setState(() {
      switch (key) {
        case 'A':
          _Draft.charABytes = null;
          break;
        case 'B':
          _Draft.charBBytes = null;
          break;
        case 'C':
          _Draft.charCBytes = null;
          break;
        case 'D':
          _Draft.charDBytes = null;
          break;
      }
    });
    _scheduleDraftSave();
  }

  bool get _step1Valid =>
      _titleCtrl.text.trim().isNotEmpty &&
      _authorCtrl.text.trim().isNotEmpty &&
      _synopsisCtrl.text.trim().isNotEmpty;

  Future<String?> _uploadCharImage(Uint8List? bytes, String key) async {
    if (bytes == null) return null;
    final supabase = Supabase.instance.client;
    final fileName =
        'characters/${DateTime.now().millisecondsSinceEpoch}_$key.jpg';
    await supabase.storage
        .from('novel-covers')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return supabase.storage.from('novel-covers').getPublicUrl(fileName);
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() {
      _publishing = true;
      _publishErr = null;
    });
    HapticFeedback.mediumImpact();

    final nav = Navigator.of(context);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw StateError('กรุณาเข้าสู่ระบบก่อนเผยแพร่นิยาย');

      late final Map<String, dynamic> novelRow;
      if (_Draft.existingNovelId == null) {
        String? coverUrl;
        if (_coverBytes != null) {
          final fileName =
              'covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('novel-covers')
              .uploadBinary(
                fileName,
                _coverBytes!,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
          coverUrl = supabase.storage
              .from('novel-covers')
              .getPublicUrl(fileName);
        }

        final charUrls = await Future.wait([
          _uploadCharImage(_charABytes, 'A'),
          _uploadCharImage(_charBBytes, 'B'),
          _uploadCharImage(_charCBytes, 'C'),
          _uploadCharImage(_charDBytes, 'D'),
        ]);
        novelRow = await supabase
            .from('novels')
            .insert({
              'title': _titleCtrl.text.trim(),
              'author': _authorCtrl.text.trim(),
              'user_id': user.id,
              'genre': _genre,
              'synopsis': _synopsisCtrl.text.trim(),
              'cover_color': _coverColor,
              'cover_image': coverUrl,
              'views': 0,
              'char_a_name': _charACtrl.text.trim().isEmpty
                  ? null
                  : _charACtrl.text.trim(),
              'char_b_name': _charBCtrl.text.trim().isEmpty
                  ? null
                  : _charBCtrl.text.trim(),
              'char_c_name': _charCCtrl.text.trim().isEmpty
                  ? null
                  : _charCCtrl.text.trim(),
              'char_d_name': _charDCtrl.text.trim().isEmpty
                  ? null
                  : _charDCtrl.text.trim(),
              'char_a_image': charUrls[0],
              'char_b_image': charUrls[1],
              'char_c_image': charUrls[2],
              'char_d_image': charUrls[3],
            })
            .select()
            .single();
      } else {
        novelRow = await supabase
            .from('novels')
            .select()
            .eq('id', _Draft.existingNovelId!)
            .eq('user_id', user.id)
            .single();
      }

      final novelId = novelRow['id'] as String;
      Map<String, dynamic>? firstEpisodeRow;
      for (int epIdx = 0; epIdx < _episodes.length; epIdx++) {
        final ep = _episodes[epIdx];
        final epRes = await supabase
            .from('episodes')
            .insert({
              'novel_id': novelId,
              'episode_num': _Draft.episodeOffset + epIdx + 1,
              'title': ep.title.trim().isEmpty
                  ? 'ตอนที่ ${_Draft.episodeOffset + epIdx + 1}'
                  : ep.title.trim(),
            })
            .select()
            .single();
        firstEpisodeRow ??= epRes;
        if (ep.lines.isNotEmpty) {
          await supabase
              .from('chat_lines')
              .insert(
                ep.lines
                    .asMap()
                    .entries
                    .map(
                      (e) => {
                        'novel_id': novelId,
                        'episode_id': epRes['id'],
                        'sender': e.value.sender,
                        'text': e.value.text,
                        'order_num': e.key + 1,
                      },
                    )
                    .toList(),
              );
        }
      }

      final firstEpisode = firstEpisodeRow!;
      final episodeNumber = firstEpisode['episode_num'] as int;
      final readingNovel = NovelModel(
        id: novelId,
        title: novelRow['title'] as String,
        author: novelRow['author'] as String,
        genre: novelRow['genre'] as String,
        synopsis: novelRow['synopsis'] as String,
        coverColor: novelRow['cover_color'] as String,
        coverImage: novelRow['cover_image'] as String?,
        charAName: novelRow['char_a_name'] as String?,
        charBName: novelRow['char_b_name'] as String?,
        charCName: novelRow['char_c_name'] as String?,
        charDName: novelRow['char_d_name'] as String?,
        charAImage: novelRow['char_a_image'] as String?,
        charBImage: novelRow['char_b_image'] as String?,
        charCImage: novelRow['char_c_image'] as String?,
        charDImage: novelRow['char_d_image'] as String?,
        views: novelRow['views'] as int? ?? 0,
      );
      final readingEpisode = EpisodeModel(
        id: firstEpisode['id'] as String,
        novelId: novelId,
        episodeNum: episodeNumber,
        title: firstEpisode['title'] as String,
        chatLines: _episodes.first.lines
            .map(
              (line) => ChatLine(
                Sender.values.firstWhere(
                  (sender) => sender.name == line.sender,
                  orElse: () => Sender.narrator,
                ),
                line.text,
              ),
            )
            .toList(),
      );

      final publishedDraftId = _Draft.currentDraftId;
      _Draft.clear();
      if (publishedDraftId != null) {
        await _Draft.remove(publishedDraftId);
      }
      HapticFeedback.heavyImpact();
      if (mounted) {
        widget.onPublishSuccess?.call();
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ChatReadPage(novel: readingNovel, episode: readingEpisode),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _publishErr = e.toString();
          _publishing = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _Draft.existingNovelId == null ? 'เขียนนิยายใหม่' : 'เขียนตอนต่อ',
          style: TextStyle(
            color: _textPrim,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(current: _step, total: 3),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!_hasDraft) {
            Navigator.pop(context);
            return;
          }
          final leave = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: _card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'บันทึกฉบับร่างและออก?',
                style: TextStyle(
                  color: _textPrim,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'ข้อมูลที่กรอกไว้จะถูกบันทึกไว้ เพื่อกลับมาทำต่อภายหลัง',
                style: TextStyle(color: _textSub, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'อยู่ต่อ',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'บันทึกและออก',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
          if ((leave ?? false) && context.mounted) {
            await _saveDraft();
            if (!context.mounted) return;
            Navigator.pop(context);
          }
        },
        child: _initializing
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _publishErr != null && _Draft.existingNovelId != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _publishErr!,
                        style: const TextStyle(color: _error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            _loadContinuation(_Draft.existingNovelId!),
                        child: const Text(
                          'ลองอีกครั้ง',
                          style: TextStyle(color: _accent),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : FadeTransition(
                opacity: _stepFade,
                child: _step == 0
                    ? _Step1Info(
                        titleCtrl: _titleCtrl,
                        authorCtrl: _authorCtrl,
                        synopsisCtrl: _synopsisCtrl,
                        charACtrl: _charACtrl,
                        charBCtrl: _charBCtrl,
                        charCCtrl: _charCCtrl,
                        charDCtrl: _charDCtrl,
                        charABytes: _charABytes,
                        charBBytes: _charBBytes,
                        charCBytes: _charCBytes,
                        charDBytes: _charDBytes,
                        genre: _genre,
                        coverBytes: _coverBytes,
                        onGenre: (g) {
                          setState(() => _Draft.genre = g);
                          _scheduleDraftSave();
                        },
                        onPickCover: _pickCover,
                        onPickCharImage: _pickCharImage,
                        onRemoveCharImage: _removeCharImage,
                        onNext: _step1Valid ? () => _goStep(1) : null,
                      )
                    : _step == 1
                    ? _Step2Episodes(
                        key: const ValueKey('step2'),
                        episodes: _episodes,
                        episodeOffset: _Draft.episodeOffset,
                        charNames: _charNames,
                        onChanged: () {
                          setState(() {});
                          _scheduleDraftSave();
                        },
                        onNext: () => _goStep(2),
                        onBack: () => _Draft.existingNovelId == null
                            ? _goStep(0)
                            : Navigator.pop(context),
                      )
                    : _Step3Review(
                        title: _titleCtrl.text.trim(),
                        author: _authorCtrl.text.trim(),
                        genre: _genre,
                        synopsis: _synopsisCtrl.text.trim(),
                        coverColor: _coverColor,
                        coverBytes: _coverBytes,
                        episodes: _episodes,
                        episodeOffset: _Draft.episodeOffset,
                        charAName: _charACtrl.text.trim(),
                        charBName: _charBCtrl.text.trim(),
                        charCName: _charCCtrl.text.trim(),
                        charDName: _charDCtrl.text.trim(),
                        charABytes: _charABytes,
                        charBBytes: _charBBytes,
                        charCBytes: _charCBytes,
                        charDBytes: _charDBytes,
                        publishing: _publishing,
                        error: _publishErr,
                        onPublish: _publish,
                        onBack: () => _goStep(1),
                      ), // ปิด _Step3Review
              ), // ปิด FadeTransition child:
      ), // ปิด PopScope
    ); // ปิด Scaffold
  }
}

class WriteFicHubPage extends StatefulWidget {
  final VoidCallback? onPublishSuccess;
  const WriteFicHubPage({super.key, this.onPublishSuccess});

  @override
  State<WriteFicHubPage> createState() => _WriteFicHubPageState();
}

class _WriteFicHubPageState extends State<WriteFicHubPage> {
  bool _loading = true;
  bool _needsCreatorMigration = false;
  String? _loadError;
  List<Map<String, dynamic>> _novels = [];
  List<Map<String, dynamic>> _savedDrafts = [];
  static const _creatorMigrationSql =
      'alter table public.novels add column if not exists user_id uuid '
      'references auth.users (id) on delete set null;\n\n'
      'create index if not exists novels_user_id_idx '
      'on public.novels (user_id);';

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _needsCreatorMigration = false;
      });
    }
    try {
      final savedDrafts = await _Draft.loadAll();
      final drafts =
          savedDrafts.entries
              .map(
                (entry) => <String, dynamic>{'id': entry.key, ...entry.value},
              )
              .toList()
            ..sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));
      if (mounted) {
        setState(() {
          _savedDrafts = drafts;
          _loading = false;
        });
      }
      final user = Supabase.instance.client.auth.currentUser;
      final novels = user == null
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await Supabase.instance.client
                  .from('novels')
                  .select('id, title, author, genre, cover_color')
                  .eq('user_id', user.id),
            );
      if (mounted)
        setState(() {
          _novels = novels;
          _loading = false;
        });
    } on PostgrestException catch (e) {
      debugPrint('Load writer hub failed: $e');
      if (mounted)
        setState(() {
          _needsCreatorMigration =
              e.code == '42703' && e.message.contains('user_id');
          _loadError = _needsCreatorMigration
              ? 'ฐานข้อมูลยังไม่มี novels.user_id กรุณาคัดลอก SQL ด้านล่างไปรันที่ Supabase Dashboard > SQL Editor แล้วกดโหลดใหม่'
              : 'โหลดรายการนิยายของคุณไม่สำเร็จ: $e';
          _loading = false;
        });
    } catch (e) {
      debugPrint('Load writer hub failed: $e');
      if (mounted)
        setState(() {
          _loadError = 'โหลดรายการนิยายของคุณไม่สำเร็จ: $e';
          _loading = false;
        });
    }
  }

  Future<void> _copyCreatorMigration() async {
    await Clipboard.setData(const ClipboardData(text: _creatorMigrationSql));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอก SQL แล้ว')));
  }

  Future<void> _openWriter({bool startFresh = false, String? novelId}) async {
    final draftId = DateTime.now().microsecondsSinceEpoch.toString();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteFicPage(
          startFresh: startFresh,
          continueNovelId: novelId,
          draftId: draftId,
          onPublishSuccess: widget.onPublishSuccess,
        ),
      ),
    );
    if (mounted) _loadOptions();
  }

  Future<void> _openSavedDraft(String draftId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteFicPage(
          draftId: draftId,
          onPublishSuccess: widget.onPublishSuccess,
        ),
      ),
    );
    if (mounted) _loadOptions();
  }

  Future<void> _deleteSavedDraft(String draftId) async {
    try {
      await _Draft.remove(draftId);
      if (mounted) {
        setState(() {
          _savedDrafts.removeWhere((draft) => draft['id'] == draftId);
        });
      }
    } catch (e) {
      debugPrint('Delete writing draft failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบฉบับร่างไม่สำเร็จ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Text(
            'เริ่มเขียนนิยาย',
            style: TextStyle(
              color: _textPrim,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'สร้างเรื่องใหม่ ทำต่อจากฉบับร่าง หรือเพิ่มตอนให้เรื่องเดิม',
            style: TextStyle(color: _textSub, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _WriterActionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'สร้างนิยายใหม่',
            subtitle: 'เริ่มเรื่องและเขียนตอนแรก',
            onTap: () => _openWriter(startFresh: true),
          ),
          if (_savedDrafts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._savedDrafts.map((draft) {
              final title = (draft['title'] as String? ?? '').trim();
              final author = (draft['author'] as String? ?? '').trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WriterActionCard(
                  icon: Icons.edit_note_rounded,
                  title: title.isEmpty ? 'ฉบับร่างไม่มีชื่อ' : title,
                  subtitle: author.isEmpty
                      ? 'ทำต่อจากฉบับร่าง'
                      : 'ฉบับร่าง · $author',
                  onTap: () => _openSavedDraft(draft['id'] as String),
                  onDelete: () => _deleteSavedDraft(draft['id'] as String),
                ),
              );
            }),
          ],
          const SizedBox(height: 28),
          const Text(
            'นิยายของฉัน',
            style: TextStyle(
              color: _textPrim,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadError != null) ...[
            Text(
              _loadError!,
              style: const TextStyle(color: _error, fontSize: 12),
            ),
            if (_needsCreatorMigration) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _divider),
                ),
                child: SelectableText(
                  _creatorMigrationSql,
                  style: const TextStyle(color: _textPrim, fontSize: 11),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _copyCreatorMigration,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('คัดลอก SQL'),
                ),
              ),
            ],
            TextButton.icon(
              onPressed: _loading ? null : _loadOptions,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('โหลดใหม่'),
            ),
          ] else if (_novels.isEmpty)
            const Text(
              'นิยายที่คุณสร้างจะแสดงที่นี่ เพื่อให้เพิ่มตอนต่อได้',
              style: TextStyle(color: _textSub, fontSize: 13),
            )
          else
            ..._novels.map(
              (novel) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WriterActionCard(
                  icon: Icons.menu_book_rounded,
                  title: (novel['title'] as String?) ?? 'ไม่มีชื่อเรื่อง',
                  subtitle:
                      '${novel['author'] ?? ''} · ${novel['genre'] ?? ''}',
                  onTap: () => _openWriter(novelId: novel['id'] as String),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WriterActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _WriterActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: _divider),
    ),
    tileColor: _card,
    leading: Icon(icon, color: _accent, size: 26),
    title: Text(
      title,
      style: const TextStyle(color: _textPrim, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: _textSub, fontSize: 12),
    ),
    trailing: onDelete == null
        ? const Icon(Icons.chevron_right_rounded, color: _textSub)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onDelete,
                tooltip: 'ลบฉบับร่าง',
                icon: const Icon(Icons.delete_outline_rounded, color: _textSub),
              ),
              const Icon(Icons.chevron_right_rounded, color: _textSub),
            ],
          ),
  );
}

// =============================================================================
// Step Indicator
// =============================================================================
class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});
  static const _labels = ['ข้อมูล', 'ตอน', 'ตรวจสอบ'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 1.5,
                color: (i ~/ 2) < current ? _accent : _divider,
              ),
            );
          }
          final s = i ~/ 2;
          final done = s < current;
          final active = s == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? _accent
                      : active
                      ? _accentSoft
                      : _surface,
                  border: Border.all(
                    color: done || active ? _accent : _divider,
                    width: active ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, color: _bg, size: 14)
                      : Text(
                          '${s + 1}',
                          style: TextStyle(
                            color: active ? _accent : _textSub,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[s],
                style: TextStyle(
                  color: active
                      ? _accent
                      : done
                      ? _accent.withOpacity(0.7)
                      : _textSub,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Step 1 — ข้อมูล
// =============================================================================
class _Step1Info extends StatelessWidget {
  final TextEditingController titleCtrl, authorCtrl, synopsisCtrl;
  final TextEditingController charACtrl, charBCtrl, charCCtrl, charDCtrl;
  final Uint8List? charABytes, charBBytes, charCBytes, charDBytes;
  final String genre;
  final Uint8List? coverBytes;
  final void Function(String) onGenre;
  final VoidCallback onPickCover;
  final void Function(String) onPickCharImage;
  final void Function(String) onRemoveCharImage;
  final VoidCallback? onNext;

  const _Step1Info({
    required this.titleCtrl,
    required this.authorCtrl,
    required this.synopsisCtrl,
    required this.charACtrl,
    required this.charBCtrl,
    required this.charCCtrl,
    required this.charDCtrl,
    required this.charABytes,
    required this.charBBytes,
    required this.charCBytes,
    required this.charDBytes,
    required this.genre,
    required this.coverBytes,
    required this.onGenre,
    required this.onPickCover,
    required this.onPickCharImage,
    required this.onRemoveCharImage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        _SectionLabel('ชื่อเรื่อง'),
        _FicTextField(ctrl: titleCtrl, hint: 'ใส่ชื่อนิยาย...', maxLines: 1),
        const SizedBox(height: 20),
        _SectionLabel('ผู้เขียน'),
        _FicTextField(ctrl: authorCtrl, hint: 'ชื่อนามปากกา...', maxLines: 1),
        const SizedBox(height: 20),
        _SectionLabel('ประเภท'),
        _GenrePicker(selected: genre, onSelect: onGenre),
        const SizedBox(height: 20),
        _SectionLabel('คำอธิบาย'),
        _FicTextField(
          ctrl: synopsisCtrl,
          hint: 'เขียนเรื่องย่อสั้นๆ ดึงดูดผู้อ่าน...',
          maxLines: 5,
        ),
        const SizedBox(height: 20),
        _SectionLabel('ตัวละคร (ไม่จำเป็น)'),
        _CharacterFields(
          charACtrl: charACtrl,
          charABytes: charABytes,
          charBCtrl: charBCtrl,
          charBBytes: charBBytes,
          charCCtrl: charCCtrl,
          charCBytes: charCBytes,
          charDCtrl: charDCtrl,
          charDBytes: charDBytes,
          onPickImage: onPickCharImage,
          onRemoveImage: onRemoveCharImage,
        ),
        const SizedBox(height: 20),
        _SectionLabel('รูปปก (ไม่จำเป็น)'),
        _CoverImagePicker(bytes: coverBytes, onPick: onPickCover),
        const SizedBox(height: 36),
        _NextButton(
          label: 'ถัดไป: เพิ่มตอน',
          enabled: onNext != null,
          onTap: onNext ?? () {},
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}

// =============================================================================
// Step 2 — Episodes Manager
// =============================================================================
class _Step2Episodes extends StatefulWidget {
  final List<_EpisodeDraft> episodes;
  final int episodeOffset;
  final Map<String, String> charNames;
  final VoidCallback onChanged;
  final VoidCallback onNext, onBack;

  const _Step2Episodes({
    super.key,
    required this.episodes,
    required this.episodeOffset,
    required this.charNames,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_Step2Episodes> createState() => _Step2EpisodesState();
}

class _Step2EpisodesState extends State<_Step2Episodes> {
  void _addEpisode() {
    setState(() {
      widget.episodes.add(
        _EpisodeDraft(
          title: 'ตอนที่ ${widget.episodeOffset + widget.episodes.length + 1}',
        ),
      );
    });
    widget.onChanged();
  }

  void _removeEpisode(int i) {
    if (widget.episodes.length <= 1) return; // ต้องมีอย่างน้อย 1 ตอน
    setState(() => widget.episodes.removeAt(i));
    widget.onChanged();
  }

  void _openEpisodeEditor(int i) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EpisodeEditorPage(
          episode: widget.episodes[i],
          epNumber: widget.episodeOffset + i + 1,
          charNames: widget.charNames,
          onChanged: () {
            setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalLines = widget.episodes.fold<int>(
      0,
      (sum, ep) => sum + ep.lines.length,
    );

    return Column(
      children: [
        // ── Header stats ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _divider)),
          ),
          child: Row(
            children: [
              _StatBadge(
                label: 'ตอน',
                value: '${widget.episodes.length}',
                color: _accent,
              ),
              const SizedBox(width: 12),
              _StatBadge(
                label: 'บรรทัดรวม',
                value: '$totalLines',
                color: _colorC,
              ),
              const Spacer(),
              // ปุ่มเพิ่มตอน
              GestureDetector(
                onTap: _addEpisode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
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
                      Icon(Icons.add_rounded, color: _accent, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'เพิ่มตอน',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── List of episodes ──────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: widget.episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final ep = widget.episodes[i];
              return _EpisodeTile(
                episode: ep,
                epNumber: widget.episodeOffset + i + 1,
                canDelete: widget.episodes.length > 1,
                onTap: () => _openEpisodeEditor(i),
                onDelete: () => _removeEpisode(i),
              );
            },
          ),
        ),

        // ── Footer buttons ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _divider),
                  foregroundColor: _textSub,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Text('ย้อนกลับ'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NextButton(
                  label: 'ตรวจสอบและ Publish',
                  enabled: true,
                  onTap: widget.onNext,
                  icon: Icons.rate_review_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _StatBadge
// =============================================================================
class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
        ),
      ],
    ),
  );
}

// =============================================================================
// _EpisodeTile — การ์ดแต่ละตอนใน list
// =============================================================================
class _EpisodeTile extends StatelessWidget {
  final _EpisodeDraft episode;
  final int epNumber;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EpisodeTile({
    required this.episode,
    required this.epNumber,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = episode.lines.length;
    final hasLines = lineCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLines ? _accent.withOpacity(0.3) : _divider,
          ),
        ),
        child: Row(
          children: [
            // เลขตอน
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$epNumber',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ตอนที่ $epNumber',
                    style: const TextStyle(
                      color: _textSub,
                      fontSize: 10,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.title.trim().isEmpty
                        ? 'ยังไม่ได้ตั้งชื่อ'
                        : episode.title,
                    style: TextStyle(
                      color: episode.title.trim().isEmpty
                          ? _textSub
                          : _textPrim,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: episode.title.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // badge จำนวนบรรทัด
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasLines ? _colorC.withOpacity(0.12) : _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasLines ? _colorC.withOpacity(0.4) : _divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: hasLines ? _colorC : _textSub,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$lineCount บรรทัด',
                        style: TextStyle(
                          color: hasLines ? _colorC : _textSub,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // ปุ่มแก้ไข
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: _accent, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'แก้ไข',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _error.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: _error,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _EpisodeEditorPage — หน้าแก้ไขบทสนทนาของแต่ละตอน
// =============================================================================
class _EpisodeEditorPage extends StatefulWidget {
  final _EpisodeDraft episode;
  final int epNumber;
  final Map<String, String> charNames;
  final VoidCallback onChanged;

  const _EpisodeEditorPage({
    required this.episode,
    required this.epNumber,
    required this.charNames,
    required this.onChanged,
    super.key,
  });

  @override
  State<_EpisodeEditorPage> createState() => _EpisodeEditorPageState();
}

class _EpisodeEditorPageState extends State<_EpisodeEditorPage> {
  late final TextEditingController _titleCtrl;
  String _sender = 'characterA';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.episode.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addLine(String text) {
    if (text.trim().isEmpty) return;
    setState(
      () => widget.episode.lines.add(
        _LineEntry(sender: _sender, text: text.trim()),
      ),
    );
    widget.onChanged();
  }

  void _removeLine(int i) {
    setState(() => widget.episode.lines.removeAt(i));
    widget.onChanged();
  }

  void _saveTitle(String v) {
    widget.episode.title = v;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textSub, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'ตอนที่ ${widget.epNumber}',
          style: const TextStyle(
            color: _textPrim,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── ชื่อตอน ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: TextField(
              controller: _titleCtrl,
              onChanged: _saveTitle,
              style: const TextStyle(
                color: _textPrim,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.title_rounded,
                  color: _textSub,
                  size: 18,
                ),
                hintText: 'ชื่อตอน... (เช่น เปิดเทอมวันแรก)',
                hintStyle: const TextStyle(color: _textSub, fontSize: 13),
                filled: true,
                fillColor: _card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Chat Lines ─────────────────────────────────────────────────────
          Expanded(
            child: widget.episode.lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: _textSub,
                          size: 48,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'ยังไม่มีบทสนทนา',
                          style: TextStyle(color: _textSub, fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'เริ่มเพิ่มบรรทัดแรกด้านล่าง',
                          style: TextStyle(color: _textSub, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: widget.episode.lines.length,
                    onReorder: (o, n) {
                      setState(() {
                        if (n > o) n--;
                        widget.episode.lines.insert(
                          n,
                          widget.episode.lines.removeAt(o),
                        );
                      });
                      widget.onChanged();
                    },
                    itemBuilder: (_, i) => _LineCard(
                      key: ValueKey('$i-${widget.episode.lines[i].text}'),
                      line: widget.episode.lines[i],
                      index: i,
                      charNames: widget.charNames,
                      onRemove: () => _removeLine(i),
                    ),
                  ),
          ),

          // ── Input ──────────────────────────────────────────────────────────
          _ChatLineInput(
            selected: _sender,
            charNames: widget.charNames,
            onSender: (s) => setState(() => _sender = s),
            onAdd: _addLine,
          ),

          // ── Done button ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _NextButton(
              label: 'บันทึกตอนนี้',
              enabled: true,
              onTap: () => Navigator.pop(context),
              icon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 3 — Review & Publish
// =============================================================================
class _Step3Review extends StatelessWidget {
  final String title, author, genre, synopsis, coverColor;
  final Uint8List? coverBytes;
  final List<_EpisodeDraft> episodes;
  final int episodeOffset;
  final String charAName, charBName, charCName, charDName;
  final Uint8List? charABytes, charBBytes, charCBytes, charDBytes;
  final bool publishing;
  final String? error;
  final VoidCallback onPublish, onBack;

  const _Step3Review({
    required this.title,
    required this.author,
    required this.genre,
    required this.synopsis,
    required this.coverColor,
    required this.coverBytes,
    required this.episodes,
    required this.episodeOffset,
    required this.charAName,
    required this.charBName,
    required this.charCName,
    required this.charDName,
    required this.charABytes,
    required this.charBBytes,
    required this.charCBytes,
    required this.charDBytes,
    required this.publishing,
    required this.error,
    required this.onPublish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF$coverColor', radix: 16));
    final totalLines = episodes.fold<int>(
      0,
      (sum, ep) => sum + ep.lines.length,
    );

    final chars = <(Color, String, Uint8List?)>[
      if (charAName.isNotEmpty || charABytes != null)
        (_colorA, charAName.isEmpty ? 'A' : charAName, charABytes),
      if (charBName.isNotEmpty || charBBytes != null)
        (_colorB, charBName.isEmpty ? 'B' : charBName, charBBytes),
      if (charCName.isNotEmpty || charCBytes != null)
        (_colorC, charCName.isEmpty ? 'C' : charCName, charCBytes),
      if (charDName.isNotEmpty || charDBytes != null)
        (_colorD, charDName.isEmpty ? 'D' : charDName, charDBytes),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // Preview card
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 110,
                  child: coverBytes != null
                      ? Image.memory(
                          coverBytes!,
                          fit: BoxFit.cover,
                          height: double.infinity,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withOpacity(0.5)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              title.isNotEmpty ? title[0] : '?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
                          genre,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Text(
                        title.isNotEmpty ? title : '(ยังไม่ได้ใส่ชื่อ)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                          Text(
                            author,
                            style: const TextStyle(
                              color: _textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _ReviewRow(label: 'ชื่อเรื่อง', value: title),
        _ReviewRow(label: 'ผู้เขียน', value: author),
        _ReviewRow(label: 'ประเภท', value: genre),
        _ReviewRow(label: 'ซีนอปซิส', value: synopsis),
        _ReviewRow(label: 'ตอน', value: '${episodes.length} ตอน'),
        _ReviewRow(label: 'บรรทัดรวม', value: '$totalLines บรรทัด'),

        // ── สรุปตอน ──────────────────────────────────────────────────────
        const SizedBox(height: 16),
        const Text(
          'รายการตอน',
          style: TextStyle(
            color: _textSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        ...episodes.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${episodeOffset + e.key + 1}',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.title.trim().isEmpty
                          ? 'ตอนที่ ${episodeOffset + e.key + 1}'
                          : e.value.title,
                      style: const TextStyle(
                        color: _textPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value.lines.length} บรรทัด',
                    style: const TextStyle(color: _textSub, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── ตัวละคร ──────────────────────────────────────────────────────
        if (chars.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'ตัวละคร',
            style: TextStyle(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: chars
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.$1.withOpacity(0.12),
                            border: Border.all(color: c.$1, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: c.$1.withOpacity(0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: c.$3 != null
                              ? Image.memory(c.$3!, fit: BoxFit.cover)
                              : Icon(
                                  Icons.person_rounded,
                                  color: c.$1,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.$2,
                          style: TextStyle(
                            color: c.$1,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],

        const SizedBox(height: 24),
        Container(height: 1, color: _divider),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NovelPreviewPage(
                  title: title,
                  author: author,
                  genre: genre,
                  synopsis: synopsis,
                  coverColor: coverColor,
                  coverBytes: coverBytes,
                  episodes: episodes
                      .map(
                        (e) => EpisodeDraft(
                          title: e.title,
                          lines: e.lines
                              .map(
                                (l) =>
                                    LineEntry(sender: l.sender, text: l.text),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                  charNames: {
                    'characterA': charAName,
                    'characterB': charBName,
                    'characterC': charCName,
                    'characterD': charDName,
                  },
                  charImages: {
                    'characterA': charABytes,
                    'characterB': charBBytes,
                    'characterC': charCBytes,
                    'characterD': charDBytes,
                  },
                ),
              ),
            ),
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              color: _accent,
              size: 18,
            ),
            label: const Text(
              'ดูตัวอย่างโหมดอ่าน',
              style: TextStyle(
                color: _accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _accent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _accentSoft,
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _error.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(color: _error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _divider),
                foregroundColor: _textSub,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text('แก้ไข'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: publishing ? null : onPublish,
                    icon: publishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: _bg,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.rocket_launch_rounded,
                            color: _bg,
                            size: 20,
                          ),
                    label: Text(
                      publishing ? 'กำลัง Publish...' : 'Publish!',
                      style: const TextStyle(
                        color: _bg,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================
class _CharacterFields extends StatelessWidget {
  final TextEditingController charACtrl, charBCtrl, charCCtrl, charDCtrl;
  final Uint8List? charABytes, charBBytes, charCBytes, charDBytes;
  final void Function(String) onPickImage;
  final void Function(String) onRemoveImage;

  const _CharacterFields({
    required this.charACtrl,
    required this.charABytes,
    required this.charBCtrl,
    required this.charBBytes,
    required this.charCCtrl,
    required this.charCBytes,
    required this.charDCtrl,
    required this.charDBytes,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _divider),
    ),
    child: Column(
      children: [
        _CharRow(
          color: _colorA,
          label: 'ตัวละคร A',
          ctrl: charACtrl,
          bytes: charABytes,
          charKey: 'A',
          onPickImage: onPickImage,
          onRemoveImage: onRemoveImage,
        ),
        const SizedBox(height: 14),
        _CharRow(
          color: _colorB,
          label: 'ตัวละคร B',
          ctrl: charBCtrl,
          bytes: charBBytes,
          charKey: 'B',
          onPickImage: onPickImage,
          onRemoveImage: onRemoveImage,
        ),
        const SizedBox(height: 14),
        _CharRow(
          color: _colorC,
          label: 'ตัวละคร C',
          ctrl: charCCtrl,
          bytes: charCBytes,
          charKey: 'C',
          onPickImage: onPickImage,
          onRemoveImage: onRemoveImage,
        ),
        const SizedBox(height: 14),
        _CharRow(
          color: _colorD,
          label: 'ตัวละคร D',
          ctrl: charDCtrl,
          bytes: charDBytes,
          charKey: 'D',
          onPickImage: onPickImage,
          onRemoveImage: onRemoveImage,
        ),
      ],
    ),
  );
}

class _CharRow extends StatelessWidget {
  final Color color;
  final String label;
  final TextEditingController ctrl;
  final Uint8List? bytes;
  final String charKey;
  final void Function(String) onPickImage;
  final void Function(String) onRemoveImage;

  const _CharRow({
    required this.color,
    required this.label,
    required this.ctrl,
    required this.bytes,
    required this.charKey,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Stack(
        children: [
          GestureDetector(
            onTap: () => onPickImage(charKey),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color, width: 1.5),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.25), blurRadius: 8),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes != null
                  ? Image.memory(bytes!, fit: BoxFit.cover)
                  : Icon(Icons.person_add_rounded, color: color, size: 24),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: bytes != null
                ? GestureDetector(
                    onTap: () => onRemoveImage(charKey),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _error,
                        shape: BoxShape.circle,
                        border: Border.all(color: _card, width: 2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _card, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _bg,
                      size: 11,
                    ),
                  ),
          ),
        ],
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: _textPrim, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ใส่ชื่อตัวละคร...',
                hintStyle: const TextStyle(color: _textSub, fontSize: 12),
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LineCard extends StatelessWidget {
  final _LineEntry line;
  final int index;
  final Map<String, String> charNames;
  final VoidCallback onRemove;
  const _LineCard({
    super.key,
    required this.line,
    required this.index,
    required this.charNames,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = _senderColor[line.sender] ?? _textSub;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: _textSub,
                size: 18,
              ),
            ),
          ),
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displaySenderName(line.sender, charNames),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.text,
                  style: const TextStyle(
                    color: _textPrim,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textSub, size: 18),
            onPressed: onRemove,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _ChatLineInput extends StatefulWidget {
  final String selected;
  final Map<String, String> charNames;
  final void Function(String) onSender;
  final void Function(String) onAdd;
  const _ChatLineInput({
    required this.selected,
    required this.charNames,
    required this.onSender,
    required this.onAdd,
  });

  @override
  State<_ChatLineInput> createState() => _ChatLineInputState();
}

class _ChatLineInputState extends State<_ChatLineInput> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: const BoxDecoration(
      color: _surface,
      border: Border(top: BorderSide(color: _divider)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _senders.map((s) {
              final active = s.$1 == widget.selected;
              return GestureDetector(
                onTap: () => widget.onSender(s.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? s.$3.withOpacity(0.15) : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? s.$3 : _divider,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _displaySenderName(s.$1, widget.charNames),
                    style: TextStyle(
                      color: active ? s.$3 : _textSub,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: _textPrim, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'พิมพ์บทพูดหรือข้อความบรรยาย...',
                  hintStyle: const TextStyle(color: _textSub, fontSize: 13),
                  filled: true,
                  fillColor: _card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: _bg, size: 22),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  const _ReviewRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: _textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(color: _textPrim, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: _textSub,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
  );
}

class _FicTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  const _FicTextField({
    required this.ctrl,
    required this.hint,
    required this.maxLines,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: maxLines == 1 ? 1 : null,
    minLines: maxLines,
    style: const TextStyle(color: _textPrim, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textSub, fontSize: 13),
      filled: true,
      fillColor: _card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    ),
  );
}

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final IconData icon;
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: enabled ? 1 : 0.4,
    duration: const Duration(milliseconds: 200),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFF38BEFF), Color(0xFF1A8FD1)]
                : [_divider, _divider],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: enabled ? onTap : null,
          // ✅ เช็คเงื่อนไข: ถ้ากดได้ใช้สี _bg ถ้ากดไม่ได้ใช้สีขาว
          icon: Icon(icon, color: enabled ? _bg : Colors.white, size: 20),
          label: Text(
            label,
            style: TextStyle(
              color: enabled ? _bg : Colors.white, // ✅ เปลี่ยนสีฟอนต์ตรงนี้
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GenrePicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _GenrePicker({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _genres.map((g) {
      final active = g == selected;
      return GestureDetector(
        onTap: () => onSelect(g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _accentSoft : _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? _accent : _divider,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Text(
            g,
            style: TextStyle(
              color: active ? _accent : _textSub,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _CoverImagePicker extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  const _CoverImagePicker({required this.bytes, required this.onPick});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPick,
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bytes != null ? _accent.withOpacity(0.4) : _divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(bytes!, fit: BoxFit.cover),
                Container(color: Colors.black26),
                const Center(
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _textSub,
                  size: 36,
                ),
                SizedBox(height: 10),
                Text(
                  'แตะเพื่อเลือกรูปปก',
                  style: TextStyle(color: _textSub, fontSize: 13),
                ),
              ],
            ),
    ),
  );
}
