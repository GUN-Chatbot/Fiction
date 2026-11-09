import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── ใช้ค่าสีชุดเดิมจาก WriteFicPage ────────────────────────────────────────
const _bg         = Color(0xFF080C14);
const _surface    = Color(0xFF0F1520);
const _card       = Color(0xFF141C2E);
const _accent     = Color(0xFF38BEFF);
const _accentSoft = Color(0x3338BEFF);
const _textPrim   = Color(0xFFE8F0FF);
const _textSub    = Color(0xFF6B7FA3);
const _divider    = Color(0xFF1E2A42);
const _success    = Color(0xFF34D399);
const _error      = Color(0xFFFF4D6D);

const _colorA = Color(0xFF38BEFF);
const _colorB = Color(0xFF9B8FFF);
const _colorC = Color(0xFF4ECDC4);
const _colorD = Color(0xFFFFB347);

const _senderColor = {
  'narrator'  : _textSub,
  'characterA': _colorA,
  'characterB': _colorB,
  'characterC': _colorC,
  'characterD': _colorD,
};

// ── Models (mirror จาก WriteFicPage) ────────────────────────────────────────
class LineEntry {
  final String sender, text;
  const LineEntry({required this.sender, required this.text});
}

class EpisodeDraft {
  final String          title;
  final List<LineEntry> lines;
  const EpisodeDraft({required this.title, required this.lines});
}

// =============================================================================
// NovelPreviewPage
// เรียกใช้:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => NovelPreviewPage(
//     title       : _titleCtrl.text.trim(),
//     author      : _authorCtrl.text.trim(),
//     genre       : _genre,
//     synopsis    : _synopsisCtrl.text.trim(),
//     coverColor  : _coverColor,
//     coverBytes  : _coverBytes,
//     episodes    : _episodes.map((e) => EpisodeDraft(title: e.title, lines: e.lines.map((l) => LineEntry(sender: l.sender, text: l.text)).toList())).toList(),
//     charNames   : { 'characterA': _charACtrl.text.trim(), 'characterB': _charBCtrl.text.trim(), ... },
//     charImages  : { 'characterA': _charABytes, 'characterB': _charBBytes, ... },
//   )));
// =============================================================================
class NovelPreviewPage extends StatefulWidget {
  final String              title;
  final String              author;
  final String              genre;
  final String              synopsis;
  final String              coverColor;
  final Uint8List?          coverBytes;
  final List<EpisodeDraft>  episodes;
  /// Map ของ sender key → ชื่อจริง (อาจว่างได้)
  final Map<String, String> charNames;
  /// Map ของ sender key → รูป bytes
  final Map<String, Uint8List?> charImages;

  const NovelPreviewPage({
    super.key,
    required this.title,
    required this.author,
    required this.genre,
    required this.synopsis,
    required this.coverColor,
    required this.coverBytes,
    required this.episodes,
    this.charNames  = const {},
    this.charImages = const {},
  });

  @override
  State<NovelPreviewPage> createState() => _NovelPreviewPageState();
}

class _NovelPreviewPageState extends State<NovelPreviewPage>
    with SingleTickerProviderStateMixin {
  int _currentEp = 0;

  late final PageController      _pageCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
      vsync  : this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchEpisode(int idx) {
    if (idx == _currentEp) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _currentEp = idx);
    _pageCtrl.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve   : Curves.easeOut,
    );
    HapticFeedback.selectionClick();
  }

  /// แปลง sender key → ชื่อแสดงผล
  String _displayName(String sender) {
    if (sender == 'narrator') return 'ผู้บรรยาย';
    final custom = widget.charNames[sender];
    if (custom != null && custom.isNotEmpty) return custom;
    const fallback = {
      'characterA': 'ตัวละคร A',
      'characterB': 'ตัวละคร B',
      'characterC': 'ตัวละคร C',
      'characterD': 'ตัวละคร D',
    };
    return fallback[sender] ?? sender;
  }

  Color _senderColorOf(String sender) =>
      _senderColor[sender] ?? _textSub;

  Uint8List? _avatarOf(String sender) => widget.charImages[sender];

  @override
  Widget build(BuildContext context) {
    final accentColor =
        Color(int.parse('FF${widget.coverColor}', radix: 16));
    final ep = widget.episodes.isNotEmpty
        ? widget.episodes[_currentEp]
        : const EpisodeDraft(title: '', lines: []);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        _PreviewHeader(
          title      : widget.title,
          author     : widget.author,
          genre      : widget.genre,
          coverColor : accentColor,
          coverBytes : widget.coverBytes,
          onClose    : () => Navigator.pop(context),
        ),

        // ── Episode tabs ────────────────────────────────────────────────────
        if (widget.episodes.length > 1)
          _EpisodeTabs(
            episodes  : widget.episodes,
            current   : _currentEp,
            onSelect  : _switchEpisode,
          ),

        // ── Chat lines ──────────────────────────────────────────────────────
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ep.lines.isEmpty
                ? _EmptyEpisode(epTitle: ep.title)
                : ListView.builder(
                    controller  : _pageCtrl,
                    padding     : const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount   : ep.lines.length,
                    itemBuilder : (_, i) {
                      final line = ep.lines[i];
                      final isNarrator = line.sender == 'narrator';
                      return isNarrator
                          ? _NarratorBubble(text: line.text)
                          : _CharBubble(
                              text       : line.text,
                              senderName : _displayName(line.sender),
                              color      : _senderColorOf(line.sender),
                              avatarBytes: _avatarOf(line.sender),
                            );
                    },
                  ),
          ),
        ),

        // ── Footer nav ──────────────────────────────────────────────────────
        if (widget.episodes.length > 1)
          _EpisodeNavBar(
            current : _currentEp,
            total   : widget.episodes.length,
            onPrev  : _currentEp > 0
                ? () => _switchEpisode(_currentEp - 1)
                : null,
            onNext  : _currentEp < widget.episodes.length - 1
                ? () => _switchEpisode(_currentEp + 1)
                : null,
          ),
      ]),
    );
  }
}

// =============================================================================
// _PreviewHeader
// =============================================================================
class _PreviewHeader extends StatelessWidget {
  final String     title, author, genre;
  final Color      coverColor;
  final Uint8List? coverBytes;
  final VoidCallback onClose;

  const _PreviewHeader({
    required this.title,
    required this.author,
    required this.genre,
    required this.coverColor,
    required this.coverBytes,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color : _surface,
        border: const Border(bottom: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // ── Top bar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              IconButton(
                icon     : const Icon(Icons.close_rounded, color: _textSub, size: 20),
                onPressed: onClose,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color : _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.4)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.remove_red_eye_outlined, color: _accent, size: 13),
                  SizedBox(width: 5),
                  Text('โหมดอ่านตัวอย่าง',
                      style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const Spacer(),
              const SizedBox(width: 40), // balance
            ]),
          ),

          // ── Novel info strip ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Row(children: [
              // Mini cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44, height: 60,
                  child: coverBytes != null
                      ? Image.memory(coverBytes!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin  : Alignment.topLeft,
                              end    : Alignment.bottomRight,
                              colors : [coverColor, coverColor.withOpacity(0.5)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              title.isNotEmpty ? title[0] : '?',
                              style: TextStyle(
                                color     : Colors.white.withOpacity(0.5),
                                fontSize  : 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color : coverColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: coverColor.withOpacity(0.3)),
                    ),
                    child: Text(genre,
                        style: TextStyle(
                          color     : coverColor,
                          fontSize  : 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        )),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.isNotEmpty ? title : '(ยังไม่ได้ตั้งชื่อ)',
                    maxLines : 1,
                    overflow : TextOverflow.ellipsis,
                    style: TextStyle(
                      color     : title.isNotEmpty ? _textPrim : _textSub,
                      fontSize  : 14,
                      fontWeight: FontWeight.w800,
                      fontStyle : title.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded, color: _textSub, size: 12),
                    const SizedBox(width: 3),
                    Text(author.isNotEmpty ? author : '—',
                        style: const TextStyle(color: _textSub, fontSize: 11)),
                  ]),
                ],
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// _EpisodeTabs — แถบเลือกตอนแนวนอน
// =============================================================================
class _EpisodeTabs extends StatelessWidget {
  final List<EpisodeDraft> episodes;
  final int                current;
  final void Function(int) onSelect;

  const _EpisodeTabs({
    required this.episodes,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: const BoxDecoration(
      color : _surface,
      border: Border(bottom: BorderSide(color: _divider)),
    ),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount      : episodes.length,
      itemBuilder    : (_, i) {
        final active = i == current;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin  : const EdgeInsets.only(right: 8),
            padding : const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color : active ? _accentSoft : _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? _accent : _divider,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              'ตอน ${i + 1}',
              style: TextStyle(
                color     : active ? _accent : _textSub,
                fontSize  : 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );
}

// =============================================================================
// _NarratorBubble — บรรทัดบรรยาย (กลาง, italic)
// =============================================================================
class _NarratorBubble extends StatelessWidget {
  final String text;
  const _NarratorBubble({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: Row(children: [
      Expanded(child: Container(height: 1, color: _divider)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color    : _textSub,
            fontSize : 13,
            fontStyle: FontStyle.italic,
            height   : 1.6,
          ),
        ),
      ),
      Expanded(child: Container(height: 1, color: _divider)),
    ]),
  );
}

// =============================================================================
// _CharBubble — บรรทัดตัวละคร (มี avatar + ชื่อ)
// =============================================================================
class _CharBubble extends StatelessWidget {
  final String     text;
  final String     senderName;
  final Color      color;
  final Uint8List? avatarBytes;

  const _CharBubble({
    required this.text,
    required this.senderName,
    required this.color,
    required this.avatarBytes,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Avatar
      Container(
        width : 34,
        height: 34,
        decoration: BoxDecoration(
          shape : BoxShape.circle,
          color : color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatarBytes != null
            ? Image.memory(avatarBytes!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color     : color,
                    fontSize  : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 10),

      // Bubble
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อตัวละคร
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: Text(
              senderName,
              style: TextStyle(
                color     : color,
                fontSize  : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // กล่องบทพูด
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color        : _card,
              borderRadius : const BorderRadius.only(
                topRight   : Radius.circular(14),
                bottomLeft : Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color : _textPrim,
                fontSize: 14,
                height  : 1.65,
              ),
            ),
          ),
        ],
      )),
    ]),
  );
}

// =============================================================================
// _EmptyEpisode
// =============================================================================
class _EmptyEpisode extends StatelessWidget {
  final String epTitle;
  const _EmptyEpisode({required this.epTitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.menu_book_rounded, color: _textSub, size: 52),
      const SizedBox(height: 16),
      Text(
        epTitle.isNotEmpty ? epTitle : 'ตอนนี้ยังไม่มีเนื้อหา',
        style: const TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('ยังไม่มีบรรทัดในตอนนี้',
          style: TextStyle(color: _textSub, fontSize: 13)),
    ]),
  );
}

// =============================================================================
// _EpisodeNavBar — ปุ่มตอนก่อน / ตอนถัดไป
// =============================================================================
class _EpisodeNavBar extends StatelessWidget {
  final int          current, total;
  final VoidCallback? onPrev, onNext;

  const _EpisodeNavBar({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    decoration: const BoxDecoration(
      color : _surface,
      border: Border(top: BorderSide(color: _divider)),
    ),
    child: SafeArea(
      top: false,
      child: Row(children: [
        // ปุ่มก่อนหน้า
        _NavBtn(
          icon   : Icons.arrow_back_ios_new_rounded,
          label  : 'ตอนก่อน',
          enabled: onPrev != null,
          onTap  : onPrev,
          reverse: true,
        ),

        // ตัวบอกตำแหน่ง
        Expanded(child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total > 7 ? 7 : total, (i) {
            // ถ้ามีเยอะเกิน 7 ให้แสดง dot ตรงกลาง 7 ตัวแทน
            final actualIdx = total > 7
                ? (current - 3 + i).clamp(0, total - 1)
                : i;
            final active = actualIdx == current;
            return AnimatedContainer(
              duration : const Duration(milliseconds: 250),
              margin   : const EdgeInsets.symmetric(horizontal: 3),
              width    : active ? 18 : 6,
              height   : 6,
              decoration: BoxDecoration(
                color       : active ? _accent : _divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        )),

        // ปุ่มถัดไป
        _NavBtn(
          icon   : Icons.arrow_forward_ios_rounded,
          label  : 'ตอนถัดไป',
          enabled: onNext != null,
          onTap  : onNext,
          reverse: false,
        ),
      ]),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         enabled;
  final VoidCallback? onTap;
  final bool         reverse;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity : enabled ? 1.0 : 0.3,
    duration: const Duration(milliseconds: 200),
    child   : GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color : enabled ? _accentSoft : _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: enabled ? _accent.withOpacity(0.4) : _divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (reverse) ...[
            Icon(icon, color: enabled ? _accent : _textSub, size: 13),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                color     : enabled ? _accent : _textSub,
                fontSize  : 12,
                fontWeight: FontWeight.w600,
              )),
          if (!reverse) ...[
            const SizedBox(width: 5),
            Icon(icon, color: enabled ? _accent : _textSub, size: 13),
          ],
        ]),
      ),
    ),
  );
}