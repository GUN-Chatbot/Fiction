import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:traveldb_neeracha/home_page.dart';
import 'novel_preview_page.dart';

const _bg         = Color(0xFF080C14);
const _surface    = Color(0xFF0F1520);
const _card       = Color(0xFF141C2E);
const _accent     = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim   = Color(0xFFE8F0FF);
const _textSub    = Color(0xFF6B7FA3);
const _divider    = Color(0xFF1E2A42);
const _success    = Color(0xFF34D399);
const _successSoft= Color(0x2234D399);
const _error      = Color(0xFFFF4D6D);

const _colorA = Color(0xFF38BEFF);
const _colorB = Color(0xFF9B8FFF);
const _colorC = Color(0xFF4ECDC4);
const _colorD = Color(0xFFFFB347);

const _genres = [
  'โรแมนติก', 'แฟนตาซี', 'ระทึกขวัญ', 'ดราม่า',
  'ตลก', 'ผจญภัย', 'วิทยาศาสตร์', 'สยองขวัญ',
  'ประวัติศาสตร์', 'อื่นๆ',
];

const _coverColors = [
  '38BEFF', 'FF4D6D', '34D399', 'F59E0B',
  'A78BFA', 'FB923C', 'EC4899', '6EE7B7',
];

const _senders = [
  ('narrator',   'ผู้บรรยาย', _textSub),
  ('characterA', 'ตัวละคร A', _colorA),
  ('characterB', 'ตัวละคร B', _colorB),
  ('characterC', 'ตัวละคร C', _colorC),
  ('characterD', 'ตัวละคร D', _colorD),
];

const _senderLabel = {
  'narrator'  : 'ผู้บรรยาย',
  'characterA': 'ตัวละคร A',
  'characterB': 'ตัวละคร B',
  'characterC': 'ตัวละคร C',
  'characterD': 'ตัวละคร D',
};

const _senderColor = {
  'narrator'  : _textSub,
  'characterA': _colorA,
  'characterB': _colorB,
  'characterC': _colorC,
  'characterD': _colorD,
};

// =============================================================================
// Models
// =============================================================================
class _LineEntry {
  String sender, text;
  _LineEntry({required this.sender, required this.text});
}

class _EpisodeDraft {
  String           title;
  List<_LineEntry> lines;
  _EpisodeDraft({required this.title, List<_LineEntry>? lines})
      : lines = lines ?? [];
}

// =============================================================================
// Draft storage
// =============================================================================
class _Draft {
  static final titleCtrl    = TextEditingController();
  static final authorCtrl   = TextEditingController();
  static final synopsisCtrl = TextEditingController();
  static final charACtrl    = TextEditingController();
  static final charBCtrl    = TextEditingController();
  static final charCCtrl    = TextEditingController();
  static final charDCtrl    = TextEditingController();

  static String     genre      = 'โรแมนติก';
  static String     coverColor = '38BEFF';
  static Uint8List? coverBytes;

  static Uint8List? charABytes;
  static Uint8List? charBBytes;
  static Uint8List? charCBytes;
  static Uint8List? charDBytes;

  // ✅ เปลี่ยนจาก lines เดี่ยว → list of episodes
  static List<_EpisodeDraft> episodes = [_EpisodeDraft(title: 'ตอนที่ 1')];

  static void clear() {
    titleCtrl.text    = '';
    authorCtrl.text   = '';
    synopsisCtrl.text = '';
    charACtrl.text    = '';
    charBCtrl.text    = '';
    charCCtrl.text    = '';
    charDCtrl.text    = '';
    genre      = 'โรแมนติก';
    coverColor = '38BEFF';
    coverBytes = null;
    charABytes = null;
    charBBytes = null;
    charCBytes = null;
    charDBytes = null;
    episodes   = [_EpisodeDraft(title: 'ตอนที่ 1')];
  }
}

// =============================================================================
// WriteFicPage
// =============================================================================
class WriteFicPage extends StatefulWidget {
  final VoidCallback? onPublishSuccess;
  const WriteFicPage({super.key, this.onPublishSuccess});
  @override
  State<WriteFicPage> createState() => _WriteFicPageState();
}

class _WriteFicPageState extends State<WriteFicPage> with TickerProviderStateMixin {
  int _step = 0;
   bool get _hasDraft =>
      _titleCtrl.text.trim().isNotEmpty ||
      _authorCtrl.text.trim().isNotEmpty ||
      _synopsisCtrl.text.trim().isNotEmpty ||
      _episodes.any((e) => e.lines.isNotEmpty);

  TextEditingController get _titleCtrl    => _Draft.titleCtrl;
  TextEditingController get _authorCtrl   => _Draft.authorCtrl;
  TextEditingController get _synopsisCtrl => _Draft.synopsisCtrl;
  TextEditingController get _charACtrl    => _Draft.charACtrl;
  TextEditingController get _charBCtrl    => _Draft.charBCtrl;
  TextEditingController get _charCCtrl    => _Draft.charCCtrl;
  TextEditingController get _charDCtrl    => _Draft.charDCtrl;

  String     get _genre      => _Draft.genre;
  String     get _coverColor => _Draft.coverColor;
  Uint8List? get _coverBytes => _Draft.coverBytes;
  Uint8List? get _charABytes => _Draft.charABytes;
  Uint8List? get _charBBytes => _Draft.charBBytes;
  Uint8List? get _charCBytes => _Draft.charCBytes;
  Uint8List? get _charDBytes => _Draft.charDBytes;

  List<_EpisodeDraft> get _episodes => _Draft.episodes;

  bool    _publishing = false;
  String? _publishErr;

  late final AnimationController _stepAnim;
  late final Animation<double>   _stepFade;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() { _stepAnim.dispose(); super.dispose(); }

  void _goStep(int next) { _stepAnim.forward(from: 0); setState(() => _step = next); }

  Future<void> _pickCover() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _Draft.coverBytes = bytes);
  }

  Future<void> _pickCharImage(String key) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      switch (key) {
        case 'A': _Draft.charABytes = bytes; break;
        case 'B': _Draft.charBBytes = bytes; break;
        case 'C': _Draft.charCBytes = bytes; break;
        case 'D': _Draft.charDBytes = bytes; break;
      }
    });
  }

  void _removeCharImage(String key) {
    setState(() {
      switch (key) {
        case 'A': _Draft.charABytes = null; break;
        case 'B': _Draft.charBBytes = null; break;
        case 'C': _Draft.charCBytes = null; break;
        case 'D': _Draft.charDBytes = null; break;
      }
    });
  }

  bool get _step1Valid =>
      _titleCtrl.text.trim().isNotEmpty &&
      _authorCtrl.text.trim().isNotEmpty &&
      _synopsisCtrl.text.trim().isNotEmpty;

  Future<String?> _uploadCharImage(Uint8List? bytes, String key) async {
    if (bytes == null) return null;
    final supabase  = Supabase.instance.client;
    final fileName  = 'characters/${DateTime.now().millisecondsSinceEpoch}_$key.jpg';
    await supabase.storage.from('novel-covers').uploadBinary(
      fileName, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return supabase.storage.from('novel-covers').getPublicUrl(fileName);
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() { _publishing = true; _publishErr = null; });
    HapticFeedback.mediumImpact();

    // ✅ เก็บ navigator ก่อน await เพื่อป้องกัน context หมดอายุ
    final nav = Navigator.of(context);

    try {
      final supabase = Supabase.instance.client;

      // 1. upload cover
      String? coverUrl;
      if (_coverBytes != null) {
        final fileName = 'covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('novel-covers').uploadBinary(
          fileName, _coverBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        coverUrl = supabase.storage.from('novel-covers').getPublicUrl(fileName);
      }

      // 2. upload รูปตัวละคร
      final charUrls = await Future.wait([
        _uploadCharImage(_charABytes, 'A'),
        _uploadCharImage(_charBBytes, 'B'),
        _uploadCharImage(_charCBytes, 'C'),
        _uploadCharImage(_charDBytes, 'D'),
      ]);

      // 3. insert novel
      final novelRes = await supabase.from('novels').insert({
        'title'       : _titleCtrl.text.trim(),
        'author'      : _authorCtrl.text.trim(),
        'genre'       : _genre,
        'synopsis'    : _synopsisCtrl.text.trim(),
        'cover_color' : _coverColor,
        'cover_image' : coverUrl,
        'views'       : 0,
        'char_a_name' : _charACtrl.text.trim().isEmpty ? null : _charACtrl.text.trim(),
        'char_b_name' : _charBCtrl.text.trim().isEmpty ? null : _charBCtrl.text.trim(),
        'char_c_name' : _charCCtrl.text.trim().isEmpty ? null : _charCCtrl.text.trim(),
        'char_d_name' : _charDCtrl.text.trim().isEmpty ? null : _charDCtrl.text.trim(),
        'char_a_image': charUrls[0],
        'char_b_image': charUrls[1],
        'char_c_image': charUrls[2],
        'char_d_image': charUrls[3],
      }).select().single();

      final novelId = novelRes['id'] as String;

      // 4. ✅ insert episodes + chat_lines ทีละตอน
      for (int epIdx = 0; epIdx < _episodes.length; epIdx++) {
        final ep = _episodes[epIdx];

        // insert episode
        final epRes = await supabase.from('episodes').insert({
          'novel_id'   : novelId,
          'episode_num': epIdx + 1,
          'title'      : ep.title.trim().isEmpty ? 'ตอนที่ ${epIdx + 1}' : ep.title.trim(),
        }).select().single();

        final episodeId = epRes['id'] as String;

        // insert chat_lines ของตอนนี้
        if (ep.lines.isNotEmpty) {
          await supabase.from('chat_lines').insert(
            ep.lines.asMap().entries.map((e) => {
              'novel_id'  : novelId,
              'episode_id': episodeId,
              'sender'    : e.value.sender,
              'text'      : e.value.text,
              'order_num' : e.key + 1,
            }).toList(),
          );
        }
      }

      _Draft.clear();
      HapticFeedback.heavyImpact();
      if (mounted) {
        widget.onPublishSuccess?.call();
      }
    } catch (e) {
      if (mounted) setState(() { _publishErr = e.toString(); _publishing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor : _surface,
        surfaceTintColor: Colors.transparent,
        elevation       : 0,
        centerTitle: true,
        title: const Text('เขียนนิยายใหม่',
            style: TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700,letterSpacing: 0,)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(current: _step, total: 3),
        ),
      ),
      body: PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    if (!_hasDraft) { Navigator.pop(context); return; }
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ออกโดยไม่บันทึก?',
            style: TextStyle(color: _textPrim, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('ข้อมูลที่กรอกไว้จะหายไปทั้งหมด',
            style: TextStyle(color: _textSub, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('อยู่ต่อ',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออก',
                style: TextStyle(color: _error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if ((leave ?? false) && context.mounted) {
      _Draft.clear();
      Navigator.pop(context);
    }
  },
  child: FadeTransition(   // ← FadeTransition เดิม ต่อเนื่องไปตามปกติ
        opacity: _stepFade,
        child: _step == 0
          ? _Step1Info(
              titleCtrl        : _titleCtrl,
              authorCtrl       : _authorCtrl,
              synopsisCtrl     : _synopsisCtrl,
              charACtrl        : _charACtrl,
              charBCtrl        : _charBCtrl,
              charCCtrl        : _charCCtrl,
              charDCtrl        : _charDCtrl,
              charABytes       : _charABytes,
              charBBytes       : _charBBytes,
              charCBytes       : _charCBytes,
              charDBytes       : _charDBytes,
              genre            : _genre,
              coverColor       : _coverColor,
              coverBytes       : _coverBytes,
              onGenre          : (g) => setState(() => _Draft.genre = g),
              onCoverColor     : (c) => setState(() => _Draft.coverColor = c),
              onPickCover      : _pickCover,
              onPickCharImage  : _pickCharImage,
              onRemoveCharImage: _removeCharImage,
              onNext           : _step1Valid ? () => _goStep(1) : null,
            )
          : _step == 1
          ? _Step2Episodes(
              key     : const ValueKey('step2'),
              episodes: _episodes,
              onChanged: () => setState(() {}),
              onNext  : () => _goStep(2),
              onBack  : () => _goStep(0),
            )
          : _Step3Review(
              title     : _titleCtrl.text.trim(),
              author    : _authorCtrl.text.trim(),
              genre     : _genre,
              synopsis  : _synopsisCtrl.text.trim(),
              coverColor: _coverColor,
              coverBytes: _coverBytes,
              episodes  : _episodes,
              charAName : _charACtrl.text.trim(),
              charBName : _charBCtrl.text.trim(),
              charCName : _charCCtrl.text.trim(),
              charDName : _charDCtrl.text.trim(),
              charABytes: _charABytes,
              charBBytes: _charBBytes,
              charCBytes: _charCBytes,
              charDBytes: _charDBytes,
              publishing: _publishing,
              error     : _publishErr,
              onPublish : _publish,
             onBack    : () => _goStep(1),
            ),        // ปิด _Step3Review
        ),            // ปิด FadeTransition child:
      ),              // ปิด PopScope
    );                // ปิด Scaffold
  }
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
      child: Row(children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 1.5,
            color: (i ~/ 2) < current ? _accent : _divider,
          ));
        }
        final s      = i ~/ 2;
        final done   = s < current;
        final active = s == current;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _accent : active ? _accentSoft : _surface,
              border: Border.all(color: done || active ? _accent : _divider, width: active ? 2 : 1.5),
            ),
            child: Center(child: done
                ? const Icon(Icons.check_rounded, color: _bg, size: 14)
                : Text('${s + 1}', style: TextStyle(color: active ? _accent : _textSub, fontSize: 11, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 4),
          Text(_labels[s], style: TextStyle(
            color: active ? _accent : done ? _accent.withOpacity(0.7) : _textSub,
            fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0,
          )),
        ]);
      })),
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
  final String     genre, coverColor;
  final Uint8List? coverBytes;
  final void Function(String) onGenre;
  final void Function(String) onCoverColor;
  final VoidCallback  onPickCover;
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
    required this.coverColor,
    required this.coverBytes,
    required this.onGenre,
    required this.onCoverColor,
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
        _FicTextField(ctrl: synopsisCtrl, hint: 'เขียนเรื่องย่อสั้นๆ ดึงดูดผู้อ่าน...', maxLines: 5),
        const SizedBox(height: 20),
        _SectionLabel('ตัวละคร (ไม่จำเป็น)'),
        _CharacterFields(
          charACtrl: charACtrl, charABytes: charABytes,
          charBCtrl: charBCtrl, charBBytes: charBBytes,
          charCCtrl: charCCtrl, charCBytes: charCBytes,
          charDCtrl: charDCtrl, charDBytes: charDBytes,
          onPickImage  : onPickCharImage,
          onRemoveImage: onRemoveCharImage,
        ),
        const SizedBox(height: 20),
        _SectionLabel('สีปก'),
        _ColorPicker(selected: coverColor, onSelect: onCoverColor),
        const SizedBox(height: 20),
        _SectionLabel('รูปปก (ไม่จำเป็น)'),
        _CoverImagePicker(bytes: coverBytes, onPick: onPickCover),
        const SizedBox(height: 36),
        _NextButton(
          label  : 'ถัดไป: เพิ่มตอน',
          enabled: onNext != null,
          onTap  : onNext ?? () {},
          icon   : Icons.arrow_forward_rounded,
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
  final VoidCallback onChanged;
  final VoidCallback onNext, onBack;

  const _Step2Episodes({super.key,
    required this.episodes,
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
      widget.episodes.add(_EpisodeDraft(title: 'ตอนที่ ${widget.episodes.length + 1}'));
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
          episode   : widget.episodes[i],
          epNumber  : i + 1,
          onChanged : () { setState(() {}); widget.onChanged(); },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalLines = widget.episodes.fold<int>(0, (sum, ep) => sum + ep.lines.length);

    return Column(children: [
      // ── Header stats ──────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _divider))),
        child: Row(children: [
          _StatBadge(label: 'ตอน', value: '${widget.episodes.length}', color: _accent),
          const SizedBox(width: 12),
          _StatBadge(label: 'บรรทัดรวม', value: '$totalLines', color: _colorC),
          const Spacer(),
          // ปุ่มเพิ่มตอน
          GestureDetector(
            onTap: _addEpisode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _accentSoft, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withOpacity(0.4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: _accent, size: 16),
                SizedBox(width: 4),
                Text('เพิ่มตอน', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
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
              episode  : ep,
              epNumber : i + 1,
              canDelete: widget.episodes.length > 1,
              onTap    : () => _openEpisodeEditor(i),
              onDelete : () => _removeEpisode(i),
            );
          },
        ),
      ),

      // ── Footer buttons ────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(children: [
          OutlinedButton(
            onPressed: widget.onBack,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _divider), foregroundColor: _textSub,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('ย้อนกลับ'),
          ),
          const SizedBox(width: 12),
          Expanded(child: _NextButton(
            label  : 'ตรวจสอบและ Publish',
            enabled: true,
            onTap  : widget.onNext,
            icon   : Icons.rate_review_outlined,
          )),
        ]),
      ),
    ]);
  }
}

// =============================================================================
// _StatBadge
// =============================================================================
class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
    ]),
  );
}

// =============================================================================
// _EpisodeTile — การ์ดแต่ละตอนใน list
// =============================================================================
class _EpisodeTile extends StatelessWidget {
  final _EpisodeDraft episode;
  final int           epNumber;
  final bool          canDelete;
  final VoidCallback  onTap;
  final VoidCallback  onDelete;

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
    final hasLines  = lineCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasLines ? _accent.withOpacity(0.3) : _divider),
        ),
        child: Row(children: [
          // เลขตอน
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _accentSoft, borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text('$epNumber',
                style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ตอนที่ $epNumber',
                style: const TextStyle(color: _textSub, fontSize: 10, letterSpacing: 0)),
            const SizedBox(height: 2),
            Text(
              episode.title.trim().isEmpty ? 'ยังไม่ได้ตั้งชื่อ' : episode.title,
              style: TextStyle(
                color     : episode.title.trim().isEmpty ? _textSub : _textPrim,
                fontSize  : 14,
                fontWeight: FontWeight.w700,
                fontStyle : episode.title.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ])),
          const SizedBox(width: 8),

          // badge จำนวนบรรทัด
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasLines ? _colorC.withOpacity(0.12) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: hasLines ? _colorC.withOpacity(0.4) : _divider),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: hasLines ? _colorC : _textSub, size: 11),
                const SizedBox(width: 4),
                Text('$lineCount บรรทัด',
                    style: TextStyle(
                      color: hasLines ? _colorC : _textSub,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
            const SizedBox(height: 6),
            Row(children: [
              // ปุ่มแก้ไข
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentSoft, borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, color: _accent, size: 11),
                  SizedBox(width: 3),
                  Text('แก้ไข', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
              if (canDelete) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _error.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _error.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: _error, size: 12),
                  ),
                ),
              ],
            ]),
          ]),
        ]),
      ),
    );
  }
}

// =============================================================================
// _EpisodeEditorPage — หน้าแก้ไขบทสนทนาของแต่ละตอน
// =============================================================================
class _EpisodeEditorPage extends StatefulWidget {
  final _EpisodeDraft episode;
  final int           epNumber;
  final VoidCallback  onChanged;

  const _EpisodeEditorPage({
    required this.episode,
    required this.epNumber,
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
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  void _addLine(String text) {
    if (text.trim().isEmpty) return;
    setState(() => widget.episode.lines.add(_LineEntry(sender: _sender, text: text.trim())));
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
        backgroundColor : _surface,
        surfaceTintColor: Colors.transparent,
        elevation       : 0,
        leading: IconButton(
          icon     : const Icon(Icons.arrow_back_ios_new, color: _textSub, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('ตอนที่ ${widget.epNumber}',
            style: const TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        // ── ชื่อตอน ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(bottom: BorderSide(color: _divider)),
          ),
          child: TextField(
            controller: _titleCtrl,
            onChanged : _saveTitle,
            style     : const TextStyle(color: _textPrim, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon   : const Icon(Icons.title_rounded, color: _textSub, size: 18),
              hintText     : 'ชื่อตอน... (เช่น เปิดเทอมวันแรก)',
              hintStyle    : const TextStyle(color: _textSub, fontSize: 13),
              filled       : true,
              fillColor    : _card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border       : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
            ),
          ),
        ),

        // ── Chat Lines ─────────────────────────────────────────────────────
        Expanded(
          child: widget.episode.lines.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.chat_bubble_outline_rounded, color: _textSub, size: 48),
                  SizedBox(height: 14),
                  Text('ยังไม่มีบทสนทนา', style: TextStyle(color: _textSub, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('เริ่มเพิ่มบรรทัดแรกด้านล่าง', style: TextStyle(color: _textSub, fontSize: 12)),
                ]))
              : ReorderableListView.builder(
                  padding   : const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount : widget.episode.lines.length,
                  onReorder : (o, n) {
                    setState(() {
                      if (n > o) n--;
                      widget.episode.lines.insert(n, widget.episode.lines.removeAt(o));
                    });
                    widget.onChanged();
                  },
                  itemBuilder: (_, i) => _LineCard(
                    key     : ValueKey('$i-${widget.episode.lines[i].text}'),
                    line    : widget.episode.lines[i],
                    index   : i,
                    onRemove: () => _removeLine(i),
                  ),
                ),
        ),

        // ── Input ──────────────────────────────────────────────────────────
        _ChatLineInput(
          selected: _sender,
          onSender: (s) => setState(() => _sender = s),
          onAdd   : _addLine,
        ),

        // ── Done button ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: _NextButton(
            label  : 'บันทึกตอนนี้',
            enabled: true,
            onTap  : () => Navigator.pop(context),
            icon   : Icons.check_rounded,
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// Step 3 — Review & Publish
// =============================================================================
class _Step3Review extends StatelessWidget {
  final String     title, author, genre, synopsis, coverColor;
  final Uint8List? coverBytes;
  final List<_EpisodeDraft> episodes;
  final String     charAName, charBName, charCName, charDName;
  final Uint8List? charABytes, charBBytes, charCBytes, charDBytes;
  final bool       publishing;
  final String?    error;
  final VoidCallback onPublish, onBack;

  const _Step3Review({
    required this.title,      required this.author,
    required this.genre,      required this.synopsis,
    required this.coverColor, required this.coverBytes,
    required this.episodes,
    required this.charAName,  required this.charBName,
    required this.charCName,  required this.charDName,
    required this.charABytes, required this.charBBytes,
    required this.charCBytes, required this.charDBytes,
    required this.publishing, required this.error,
    required this.onPublish,  required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final color      = Color(int.parse('FF$coverColor', radix: 16));
    final totalLines = episodes.fold<int>(0, (sum, ep) => sum + ep.lines.length);

    final chars = <(Color, String, Uint8List?)>[
      if (charAName.isNotEmpty || charABytes != null) (_colorA, charAName.isEmpty ? 'A' : charAName, charABytes),
      if (charBName.isNotEmpty || charBBytes != null) (_colorB, charBName.isEmpty ? 'B' : charBName, charBBytes),
      if (charCName.isNotEmpty || charCBytes != null) (_colorC, charCName.isEmpty ? 'C' : charCName, charCBytes),
      if (charDName.isNotEmpty || charDBytes != null) (_colorD, charDName.isEmpty ? 'D' : charDName, charDBytes),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // Preview card
        Container(
          height    : 160,
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _divider)),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(width: 110, child: coverBytes != null
                  ? Image.memory(coverBytes!, fit: BoxFit.cover, height: double.infinity)
                  : Container(
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(0.5)])),
                      child: Center(child: Text(title.isNotEmpty ? title[0] : '?',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 60, fontWeight: FontWeight.w900))),
                    )),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(6)),
                  child: Text(genre, style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0)),
                ),
                Text(title.isNotEmpty ? title : '(ยังไม่ได้ใส่ชื่อ)', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textPrim, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, color: _textSub, size: 13), const SizedBox(width: 4),
                  Text(author, style: const TextStyle(color: _textSub, fontSize: 12)),
                ]),
              ]),
            )),
          ]),
        ),

        const SizedBox(height: 24),
        _ReviewRow(label: 'ชื่อเรื่อง', value: title),
        _ReviewRow(label: 'ผู้เขียน',  value: author),
        _ReviewRow(label: 'ประเภท',    value: genre),
        _ReviewRow(label: 'ซีนอปซิส', value: synopsis),
        _ReviewRow(label: 'ตอน',       value: '${episodes.length} ตอน'),
        _ReviewRow(label: 'บรรทัดรวม', value: '$totalLines บรรทัด'),

        // ── สรุปตอน ──────────────────────────────────────────────────────
        const SizedBox(height: 16),
        const Text('รายการตอน', style: TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0)),
        const SizedBox(height: 10),
        ...episodes.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider)),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                e.value.title.trim().isEmpty ? 'ตอนที่ ${e.key + 1}' : e.value.title,
                style: const TextStyle(color: _textPrim, fontSize: 13, fontWeight: FontWeight.w600),
              )),
              Text('${e.value.lines.length} บรรทัด', style: const TextStyle(color: _textSub, fontSize: 11)),
            ]),
          ),
        )),

        // ── ตัวละคร ──────────────────────────────────────────────────────
        if (chars.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('ตัวละคร', style: TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: chars.map((c) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.$1.withOpacity(0.12),
                  border: Border.all(color: c.$1, width: 1.5),
                  boxShadow: [BoxShadow(color: c.$1.withOpacity(0.25), blurRadius: 8)],
                ),
                clipBehavior: Clip.antiAlias,
                child: c.$3 != null
                    ? Image.memory(c.$3!, fit: BoxFit.cover)
                    : Icon(Icons.person_rounded, color: c.$1, size: 24),
              ),
              const SizedBox(height: 6),
              Text(c.$2, style: TextStyle(color: c.$1, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          )).toList()),
        ],

      const SizedBox(height: 24),
Container(height: 1, color: _divider),
const SizedBox(height: 20),

SizedBox(
  width : double.infinity,
  height: 48,
  child : OutlinedButton.icon(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovelPreviewPage(
          title     : title,
          author    : author,
          genre     : genre,
          synopsis  : synopsis,
          coverColor: coverColor,
          coverBytes: coverBytes,
          episodes  : episodes
              .map((e) => EpisodeDraft(
                    title: e.title,
                    lines: e.lines
                        .map((l) => LineEntry(sender: l.sender, text: l.text))
                        .toList(),
                  ))
              .toList(),
          charNames : {
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
    icon : const Icon(Icons.remove_red_eye_outlined, color: _accent, size: 18),
    label: const Text(
      'ดูตัวอย่างโหมดอ่าน',
      style: TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      side : const BorderSide(color: _accent, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: _accentSoft,
    ),
  ),
),

const SizedBox(height: 12),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _error.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _error.withOpacity(0.4))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: _error, size: 18), const SizedBox(width: 10),
              Expanded(child: Text(error!, style: const TextStyle(color: _error, fontSize: 12))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        Row(children: [
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _divider), foregroundColor: _textSub,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('แก้ไข'),
          ),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 52, child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton.icon(
              onPressed: publishing ? null : onPublish,
              icon: publishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _bg, strokeWidth: 2.5))
                  : const Icon(Icons.rocket_launch_rounded, color: _bg, size: 20),
              label: Text(publishing ? 'กำลัง Publish...' : 'Publish!',
                  style: const TextStyle(color: _bg, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ))),
        ]),
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
    required this.charACtrl, required this.charABytes,
    required this.charBCtrl, required this.charBBytes,
    required this.charCCtrl, required this.charCBytes,
    required this.charDCtrl, required this.charDBytes,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _divider)),
    child: Column(children: [
      _CharRow(color: _colorA, label: 'ตัวละคร A', ctrl: charACtrl, bytes: charABytes, charKey: 'A', onPickImage: onPickImage, onRemoveImage: onRemoveImage),
      const SizedBox(height: 14),
      _CharRow(color: _colorB, label: 'ตัวละคร B', ctrl: charBCtrl, bytes: charBBytes, charKey: 'B', onPickImage: onPickImage, onRemoveImage: onRemoveImage),
      const SizedBox(height: 14),
      _CharRow(color: _colorC, label: 'ตัวละคร C', ctrl: charCCtrl, bytes: charCBytes, charKey: 'C', onPickImage: onPickImage, onRemoveImage: onRemoveImage),
      const SizedBox(height: 14),
      _CharRow(color: _colorD, label: 'ตัวละคร D', ctrl: charDCtrl, bytes: charDBytes, charKey: 'D', onPickImage: onPickImage, onRemoveImage: onRemoveImage),
    ]),
  );
}

class _CharRow extends StatelessWidget {
  final Color  color;
  final String label;
  final TextEditingController ctrl;
  final Uint8List? bytes;
  final String     charKey;
  final void Function(String) onPickImage;
  final void Function(String) onRemoveImage;

  const _CharRow({
    required this.color, required this.label, required this.ctrl,
    required this.bytes, required this.charKey,
    required this.onPickImage, required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Stack(children: [
      GestureDetector(
        onTap: () => onPickImage(charKey),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12), border: Border.all(color: color, width: 1.5), boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8)]),
          clipBehavior: Clip.antiAlias,
          child: bytes != null ? Image.memory(bytes!, fit: BoxFit.cover) : Icon(Icons.person_add_rounded, color: color, size: 24),
        ),
      ),
      Positioned(bottom: 0, right: 0, child: bytes != null
          ? GestureDetector(
              onTap: () => onRemoveImage(charKey),
              child: Container(width: 20, height: 20, decoration: BoxDecoration(color: _error, shape: BoxShape.circle, border: Border.all(color: _card, width: 2)), child: const Icon(Icons.close_rounded, color: Colors.white, size: 11)),
            )
          : Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _card, width: 2)), child: const Icon(Icons.camera_alt_rounded, color: _bg, size: 11))),
    ]),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: const TextStyle(color: _textPrim, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'ใส่ชื่อตัวละคร...', hintStyle: const TextStyle(color: _textSub, fontSize: 12),
          filled: true, fillColor: _surface, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)),
        ),
      ),
    ])),
  ]);
}

class _LineCard extends StatelessWidget {
  final _LineEntry line;
  final int        index;
  final VoidCallback onRemove;
  const _LineCard({super.key, required this.line, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = _senderColor[line.sender] ?? _textSub;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _divider)),
      child: Row(children: [
        ReorderableDragStartListener(
          index: index,
          child: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.drag_indicator_rounded, color: _textSub, size: 18)),
        ),
        Container(width: 4, height: 40, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_senderLabel[line.sender] ?? '', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0)),
          const SizedBox(height: 4),
          Text(line.text, style: const TextStyle(color: _textPrim, fontSize: 13, height: 1.4)),
        ])),
        IconButton(icon: const Icon(Icons.close_rounded, color: _textSub, size: 18), onPressed: onRemove, splashRadius: 18),
      ]),
    );
  }
}

class _ChatLineInput extends StatefulWidget {
  final String selected;
  final void Function(String) onSender;
  final void Function(String) onAdd;
  const _ChatLineInput({required this.selected, required this.onSender, required this.onAdd});

  @override
  State<_ChatLineInput> createState() => _ChatLineInputState();
}

class _ChatLineInputState extends State<_ChatLineInput> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  void _submit() { widget.onAdd(_ctrl.text); _ctrl.clear(); }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _divider))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(height: 36, child: ListView(
        scrollDirection: Axis.horizontal,
        children: _senders.map((s) {
          final active = s.$1 == widget.selected;
          return GestureDetector(
            onTap: () => widget.onSender(s.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? s.$3.withOpacity(0.15) : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? s.$3 : _divider, width: active ? 1.5 : 1),
              ),
              child: Text(s.$2, style: TextStyle(color: active ? s.$3 : _textSub, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ),
          );
        }).toList(),
      )),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: _ctrl,
          style: const TextStyle(color: _textPrim, fontSize: 14),
          maxLines: null, textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'พิมพ์บทพูดหรือข้อความบรรยาย...', hintStyle: const TextStyle(color: _textSub, fontSize: 13),
            filled: true, fillColor: _card, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.add_rounded, color: _bg, size: 22),
          ),
        ),
      ]),
    ]),
  );
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  const _ReviewRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0))),
      Expanded(child: Text(value.isNotEmpty ? value : '—', style: const TextStyle(color: _textPrim, fontSize: 13, height: 1.5))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0)),
  );
}

class _FicTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int    maxLines;
  const _FicTextField({required this.ctrl, required this.hint, required this.maxLines});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: maxLines == 1 ? 1 : null,
    minLines: maxLines,
    style: const TextStyle(color: _textPrim, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _textSub, fontSize: 13),
      filled: true, fillColor: _card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
    ),
  );
}

class _NextButton extends StatelessWidget {
  final String label; final bool enabled; final VoidCallback onTap; final IconData icon;
  const _NextButton({required this.label, required this.enabled, required this.onTap, required this.icon});
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: enabled ? 1 : 0.4,
    duration: const Duration(milliseconds: 200),
    child: SizedBox(width: double.infinity, height: 52, child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: enabled ? const [Color(0xFF38BEFF), Color(0xFF1A8FD1)] : [_divider, _divider]),
        boxShadow: enabled ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 5))] : [],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        // ✅ เช็คเงื่อนไข: ถ้ากดได้ใช้สี _bg ถ้ากดไม่ได้ใช้สีขาว
        icon: Icon(icon, color: enabled ? _bg : Colors.white, size: 20),
        label: Text(label, style: TextStyle(
          color: enabled ? _bg : Colors.white, // ✅ เปลี่ยนสีฟอนต์ตรงนี้
          fontSize: 14, 
          fontWeight: FontWeight.w700, 
          letterSpacing: 0
        )),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    )),
  );
}

class _GenrePicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _GenrePicker({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
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
            border: Border.all(color: active ? _accent : _divider, width: active ? 1.5 : 1),
          ),
          child: Text(g, style: TextStyle(color: active ? _accent : _textSub, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ),
      );
    }).toList(),
  );
}

class _ColorPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _ColorPicker({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Row(
    children: _coverColors.map((hex) {
      final color  = Color(int.parse('FF$hex', radix: 16));
      final active = hex == selected;
      return GestureDetector(
        onTap: () => onSelect(hex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 10),
          width: active ? 34 : 28, height: active ? 34 : 28,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.white : Colors.transparent, width: 2.5),
            boxShadow: active ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : [],
          ),
          child: active ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
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
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bytes != null ? _accent.withOpacity(0.4) : _divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Stack(fit: StackFit.expand, children: [
              Image.memory(bytes!, fit: BoxFit.cover),
              Container(color: Colors.black26),
              const Center(child: Icon(Icons.edit_rounded, color: Colors.white, size: 28)),
            ])
          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_outlined, color: _textSub, size: 36),
              SizedBox(height: 10),
              Text('แตะเพื่อเลือกรูปปก', style: TextStyle(color: _textSub, fontSize: 13)),
            ]),
    ),
  );
}