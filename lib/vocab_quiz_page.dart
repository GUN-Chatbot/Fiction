import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── ใช้สีชุดเดิมจาก VocabPage ───────────────────────────────────────────────
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
const _errorSoft  = Color(0x22FF4D6D);
// adadad
// =============================================================================
// VocabQuizPage
// เรียกใช้:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => VocabQuizPage(cards: _cards), // ส่ง List<VocabCard> มา
//   ));
// =============================================================================
class VocabQuizPage extends StatefulWidget {
  /// รับ List<VocabCard> จาก VocabPage โดยตรง
  final List<dynamic> cards; // dynamic เพื่อรองรับ VocabCard จากไฟล์เดิม

  const VocabQuizPage({super.key, required this.cards});

  @override
  State<VocabQuizPage> createState() => _VocabQuizPageState();
}

class _VocabQuizPageState extends State<VocabQuizPage>
    with TickerProviderStateMixin {
  final _rng = Random();

  // ── Quiz state ────────────────────────────────────────────────────────────
  late dynamic        _question;       // VocabCard คำที่ถาม
  late List<dynamic>  _choices;        // ตัวเลือก 4 อัน
  late _QuizMode      _mode;           // ถามภาษาไทย หรือ ถามญี่ปุ่น
  int?                _selected;       // index ที่เลือก (null = ยังไม่เลือก)
  bool                _answered = false;

  // ── Score ─────────────────────────────────────────────────────────────────
  int _correct  = 0;
  int _wrong    = 0;
  int _streak   = 0;
  int _bestStreak = 0;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _questionAnim;
  late Animation<double>   _questionFade;
  late AnimationController _choiceAnim;

  @override
  void initState() {
    super.initState();
    _questionAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350),
    );
    _questionFade = CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut);
    _choiceAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _nextQuestion();
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _choiceAnim.dispose();
    super.dispose();
  }

  // ── สร้างคำถามใหม่ ─────────────────────────────────────────────────────────
  void _nextQuestion() {
    if (widget.cards.length < 4) return;

    // สุ่ม mode: ถามไทย→ญี่ปุ่น หรือ ถามญี่ปุ่น→ไทย
    _mode = _rng.nextBool() ? _QuizMode.thaiToJp : _QuizMode.jpToThai;

    // สุ่มคำถาม
    _question = widget.cards[_rng.nextInt(widget.cards.length)];

    // สร้างตัวเลือก 4 อัน (1 ถูก + 3 ผิด)
    final others = widget.cards
        .where((c) => c.id != _question.id)
        .toList()
      ..shuffle(_rng);
    final wrong = others.take(3).toList();
    _choices   = [...wrong, _question]..shuffle(_rng);

    _selected  = null;
    _answered  = false;

    _questionAnim.forward(from: 0);
    _choiceAnim.forward(from: 0);
  }

  // ── ตอบคำถาม ───────────────────────────────────────────────────────────────
  void _answer(int idx) {
    if (_answered) return;
    final isCorrect = _choices[idx].id == _question.id;

    HapticFeedback.mediumImpact();

    setState(() {
      _selected = idx;
      _answered = true;
      if (isCorrect) {
        _correct++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _wrong++;
        _streak = 0;
        HapticFeedback.heavyImpact();
      }
    });
  }

  // ── Next ────────────────────────────────────────────────────────────────────
  void _onNext() {
    HapticFeedback.selectionClick();
    setState(() => _nextQuestion());
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  String get _questionText => _mode == _QuizMode.thaiToJp
      ? _question.thai
      : _question.japanese;

  String get _questionSub => _mode == _QuizMode.thaiToJp
      ? 'คำนี้ภาษาญี่ปุ่นคืออะไร?'
      : 'คำนี้แปลว่าอะไร?';

  String _choiceText(dynamic card) => _mode == _QuizMode.thaiToJp
      ? card.japanese
      : card.thai;

  String _choiceReading(dynamic card) =>
      _mode == _QuizMode.thaiToJp ? card.reading : '';

  bool _isCorrectChoice(int idx) => _choices[idx].id == _question.id;

  Color _choiceColor(int idx) {
    if (!_answered) return _card;
    if (_isCorrectChoice(idx)) return _successSoft;
    if (_selected == idx) return _errorSoft;
    return _card;
  }

  Color _choiceBorder(int idx) {
    if (!_answered) return _selected == idx ? _accent : _divider;
    if (_isCorrectChoice(idx)) return _success;
    if (_selected == idx) return _error;
    return _divider;
  }

  Color _choiceTextColor(int idx) {
    if (!_answered) return _selected == idx ? _accent : _textPrim;
    if (_isCorrectChoice(idx)) return _success;
    if (_selected == idx) return _error;
    return _textSub;
  }

  @override
  Widget build(BuildContext context) {
    final total = _correct + _wrong;
    final pct   = total == 0 ? 0.0 : _correct / total;

   return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor    : _surface,
        surfaceTintColor   : Colors.transparent,
        elevation          : 0,
        leading: IconButton(
          icon     : const Icon(Icons.close_rounded, color: _textSub, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Quiz mode',
            style: TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          // streak badge
          if (_streak >= 2)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _StreakBadge(key: ValueKey(_streak), streak: _streak),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: Column(children: [
        // ── Score bar ──────────────────────────────────────────────────────
        _ScoreBar(correct: _correct, wrong: _wrong, pct: pct),

        // ── Question + choices ─────────────────────────────────────────────
        Expanded(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // Question card
              FadeTransition(
                opacity: _questionFade,
                child: _QuestionCard(
                  text   : _questionText,
                  subText: _questionSub,
        
                ),
              ),

              const SizedBox(height: 28),

              // Choices
              ...List.generate(4, (i) {
                final delay = i * 0.08;
                return AnimatedBuilder(
                  animation: _choiceAnim,
                  builder: (_, child) {
                    final t = Curves.easeOut.transform(
                      (((_choiceAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0)),
                    );
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChoiceTile(
                      text      : _choiceText(_choices[i]),
                      reading   : _choiceReading(_choices[i]),
                      color     : _choiceColor(i),
                      border    : _choiceBorder(i),
                      textColor : _choiceTextColor(i),
                      answered  : _answered,
                      isCorrect : _answered && _isCorrectChoice(i),
                      isWrong   : _answered && _selected == i && !_isCorrectChoice(i),
                      onTap     : () => _answer(i),
                    ),
                  ),
                );
              }),

              // ── Result + Next ──────────────────────────────────────────────
              if (_answered) ...[
                const SizedBox(height: 8),
                _ResultRow(
                  // ✅ แก้บัคแอปเด้ง: ดักไว้เผื่อกรณีที่ _selected เป็น null (เช่น หมดเวลา)
                  isCorrect  : _selected != null ? _isCorrectChoice(_selected!) : false,
                  correctText: _choiceText(_question),
                  reading    : _choiceReading(_question),
                  onNext     : _onNext,
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// _QuizMode
// =============================================================================
enum _QuizMode { thaiToJp, jpToThai }

// =============================================================================
// _ScoreBar
// =============================================================================
class _ScoreBar extends StatelessWidget {
  final int correct, wrong;
  final double pct;
  
  const _ScoreBar({required this.correct, required this.wrong, required this.pct});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
    color: _surface,
    child: Column(children: [
      Row(children: [
        _ScorePill(label: '✓', value: correct, color: _success),
        const SizedBox(width: 10),
        _ScorePill(label: '✗', value: wrong,   color: _error),
        const Spacer(),
        Text(
          correct + wrong == 0
              ? '—'
              : '${(pct * 100).round()}%',
          style: TextStyle(
            color: pct >= 0.7 ? _success : pct >= 0.4 ? _accent : _error,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value           : pct,
          backgroundColor : _divider,
          valueColor      : AlwaysStoppedAnimation(
            pct >= 0.7 ? _success : pct >= 0.4 ? _accent : _error,
          ),
          minHeight: 4,
        ),
      ),
    ]),
  );
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  const _ScorePill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color : color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(width: 5),
      Text('$value', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
  );
}

// =============================================================================
// _StreakBadge
// =============================================================================
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color : const Color(0xFFFFB347).withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.5)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔥', style: TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text('$streak',
          style: const TextStyle(
            color: Color(0xFFFFB347), fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
  );
}

// =============================================================================
// _QuestionCard
// =============================================================================
class _QuestionCard extends StatelessWidget {
  final String  text, subText;


  const _QuestionCard({
    required this.text,
    required this.subText,
    
  });

  @override
  Widget build(BuildContext context) => Container(
    width     : double.infinity,
    decoration: BoxDecoration(
      color : _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
    ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(children: [
          // category badge
          
          const SizedBox(height: 16),

          // คำถาม
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color     : _textPrim,
              fontSize  : 40,
              fontWeight: FontWeight.w900,
              height    : 1.2,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // subtext
          Text(subText,
              style: const TextStyle(color: _textSub, fontSize: 13)),
        ]),
  );
    
  
}

// =============================================================================
// _ChoiceTile
// =============================================================================
class _ChoiceTile extends StatelessWidget {
  final String     text, reading;
  final Color      color, border, textColor;
  final bool       answered, isCorrect, isWrong;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.text,
    required this.reading,
    required this.color,
    required this.border,
    required this.textColor,
    required this.answered,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: answered ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding : const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color : color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: isCorrect || isWrong ? 1.5 : 1),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: TextStyle(
                  color     : textColor,
                  fontSize  : 16,
                  fontWeight: FontWeight.w700,
                  height    : 1.3,
                )),
            if (reading.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(reading,
                  style: TextStyle(
                    color   : textColor.withOpacity(0.6),
                    fontSize: 11,
                  )),
            ],
          ],
        )),
        if (isCorrect)
          const Icon(Icons.check_circle_rounded, color: _success, size: 22)
        else if (isWrong)
          const Icon(Icons.cancel_rounded, color: _error, size: 22),
      ]),
    ),
  );
}

// =============================================================================
// _ResultRow — แสดงผล + ปุ่มข้อต่อไป
// =============================================================================
class _ResultRow extends StatelessWidget {
  final bool         isCorrect;
  final String       correctText, reading;
  final VoidCallback onNext;

  const _ResultRow({
    required this.isCorrect,
    required this.correctText,
    required this.reading,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding : const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color : isCorrect ? _successSoft : _errorSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isCorrect ? _success.withOpacity(0.5) : _error.withOpacity(0.5)),
    ),
    child: Row(children: [
      Icon(
        isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        color: isCorrect ? _success : _error,
        size : 22,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'ถูกต้อง!' : 'คำตอบที่ถูกคือ',
            style: TextStyle(
              color     : isCorrect ? _success : _error,
              fontSize  : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 2),
            Text(correctText,
                style: const TextStyle(color: _textPrim, fontSize: 15, fontWeight: FontWeight.w800)),
            if (reading.isNotEmpty)
              Text(reading, style: const TextStyle(color: _textSub, fontSize: 11)),
          ],
        ],
      )),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: onNext,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color : _accent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('ต่อไป', style: TextStyle(color: _bg, fontSize: 13, fontWeight: FontWeight.w800)),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, color: _bg, size: 16),
          ]),
        ),
      ),
    ]),
  );
}