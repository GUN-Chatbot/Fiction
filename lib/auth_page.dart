import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'main.dart' show FictionLogoPainter, kLogoUrl;

const _bg       = Color(0xFF03050C);
const _surface  = Color(0xFF0C1428);
const _card     = Color(0xFF0F1828);
const _accent   = Color(0xFF38BEFF);
const _purple   = Color(0xFF9D6FFF);
const _textPrim = Color(0xFFEAF2FF);
const _textSub  = Color(0xFF6B7FA3);
const _divider  = Color(0xFF1E2A42);

const _quotes = [
  '"A reader lives a thousand lives."',
  '"Words are, in my opinion, the most inexhaustible source of magic."',
  '"There is no friend as loyal as a book."',
  '"A book is a dream that you hold in your hand."',
  '"One must always be careful of books."',
  '"Stories are a communal currency of humanity."',
  '"Not all those who wander are lost."',
  '"We are all stories, in the end."',
];

// ══════════════════════════════════════════════════════
//  MODELS
// ══════════════════════════════════════════════════════

class _AuthStar {
  final double x, y, size, opacity, speed, phase;
  final Color color;
  const _AuthStar(this.x, this.y, this.size, this.opacity,
      this.speed, this.phase, this.color);
}

class _AuthPage {
  double x, y, phase;
  final double angle, size, floatSpeed, floatRange, opacity;
  final Color lineColor;
  _AuthPage({
    required this.x, required this.y, required this.phase,
    required this.angle, required this.size,
    required this.floatSpeed, required this.floatRange,
    required this.opacity, required this.lineColor,
  });
}

class _AuthInk {
  double x, y, phase;
  final double rx, ry, angle, floatSpeed, floatRange, opacity;
  final Color color;
  _AuthInk({
    required this.x, required this.y, required this.phase,
    required this.rx, required this.ry, required this.angle,
    required this.floatSpeed, required this.floatRange,
    required this.opacity, required this.color,
  });
}

// ══════════════════════════════════════════════════════
//  BACKGROUND PAINTER
// ══════════════════════════════════════════════════════

class _AuthBgPainter extends CustomPainter {
  final List<_AuthStar> stars;
  final List<_AuthPage> pages;
  final List<_AuthInk>  inks;
  final double t;
  _AuthBgPainter(this.stars, this.pages, this.inks, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _paintNebula(canvas, size);
    _paintAurora(canvas, size);
    _paintPages(canvas, size);
    _paintInks(canvas, size);
    _paintStars(canvas, size);
  }

  void _paintNebula(Canvas canvas, Size size) {
    final nebulas = [
      (Offset(size.width * 0.20, size.height * 0.18),
          size.width * 0.60, const Color(0xFF0A1E40), 0.70),
      (Offset(size.width * 0.82, size.height * 0.14),
          size.width * 0.50, const Color(0xFF15094A), 0.55),
      (Offset(size.width * 0.50, size.height * 0.06),
          size.width * 0.45, const Color(0xFF38BEFF), 0.06),
    ];
    for (final n in nebulas) {
      canvas.drawCircle(n.$1, n.$2, Paint()
        ..shader = RadialGradient(
          colors: [n.$3.withOpacity(n.$4), Colors.transparent],
        ).createShader(Rect.fromCircle(center: n.$1, radius: n.$2)));
    }
  }

  void _paintAurora(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(
        center: const Alignment(0, -1.6), radius: 1.0,
        colors: [_purple.withOpacity(0.12 * t), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _paintPages(Canvas canvas, Size size) {
    final op = (t * 2).clamp(0.0, 1.0);
    for (final p in pages) {
      final fy = sin(t * pi * 2 * p.floatSpeed + p.phase) * p.floatRange;
      final fx = cos(t * pi * p.floatSpeed * 0.6 + p.phase) * p.floatRange * 0.4;
      canvas.save();
      canvas.translate(p.x * size.width + fx, p.y * size.height + fy);
      canvas.rotate(p.angle + sin(t * pi * p.floatSpeed * 0.3 + p.phase) * 0.05);
      final w = p.size; final h = p.size * 1.3;
      final pOp = p.opacity * op;
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F0FF).withOpacity(pOp),
            const Color(0xFFB8C8E8).withOpacity(pOp * 0.82),
          ],
        ).createShader(rect),
      );
      for (int i = 0; i < 4; i++) {
        final ly = -h * 0.28 + i * h * 0.17;
        canvas.drawLine(
          Offset(-w * 0.32, ly), Offset(w * 0.32, ly),
          Paint()..color = p.lineColor.withOpacity(pOp * (0.5 - i * 0.08))
            ..strokeWidth = 0.65..strokeCap = StrokeCap.round,
        );
      }
      final fs = w * 0.2;
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.5 - fs, h * 0.5)
          ..lineTo(w * 0.5, h * 0.5 - fs)
          ..lineTo(w * 0.5, h * 0.5),
        Paint()..color = p.lineColor.withOpacity(pOp * 0.35)
          ..strokeWidth = 0.5..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }
  }

  void _paintInks(Canvas canvas, Size size) {
    final op = (t * 2).clamp(0.0, 1.0);
    for (final d in inks) {
      final fy = sin(t * pi * 2 * d.floatSpeed + d.phase) * d.floatRange;
      final fx = cos(t * pi * d.floatSpeed * 0.5 + d.phase) * d.floatRange * 0.5;
      canvas.save();
      canvas.translate(d.x * size.width + fx, d.y * size.height + fy);
      canvas.rotate(d.angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: d.rx * 2, height: d.ry * 2),
        Paint()..color = d.color.withOpacity(d.opacity * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
      for (int i = 0; i < 3; i++) {
        final a = (i / 3) * 2 * pi + d.phase;
        canvas.drawCircle(
          Offset(cos(a) * d.rx * 1.8, sin(a) * d.ry * 1.8), d.rx * 0.28,
          Paint()..color = d.color.withOpacity(d.opacity * op * 0.45),
        );
      }
      canvas.restore();
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle = (sin(t * pi * 4 * s.speed + s.phase) + 1) / 2;
      final op = (s.opacity * (0.5 + 0.5 * twinkle) * t).clamp(0.0, 1.0);
      if (s.size > 1.6) {
        canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size * 2.5,
          Paint()..color = s.color.withOpacity(op * 0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 2),
        );
      }
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height), s.size,
        Paint()..color = s.color.withOpacity(op),
      );
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════
//  TYPEWRITER WIDGET
// ══════════════════════════════════════════════════════

class _Typewriter extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  const _Typewriter({
    required this.text, required this.style,
    this.speed = const Duration(milliseconds: 45),
  });
  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> {
  int _count = 0;
  late final _timer = Stream.periodic(widget.speed)
      .take(widget.text.length)
      .listen((_) { if (mounted) setState(() => _count++); });

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.text.substring(0, _count), style: widget.style),
        if (_count < widget.text.length)
          AnimatedOpacity(
            opacity: (_count % 2 == 0) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  AUTH PAGE
// ══════════════════════════════════════════════════════

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _supabase     = Supabase.instance.client;

  bool _isLogin      = true;
  bool _showPassword = false;
  bool _isLoading    = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _inCtrl;
  late final AnimationController _formCtrl;
  late final AnimationController _pageFlipCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _flipAnim;

  final _rng = Random();
  late final List<_AuthStar> _stars;
  late final List<_AuthPage> _pages;
  late final List<_AuthInk>  _inks;
  double _orbitAngle = 0;
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = _quotes[_rng.nextInt(_quotes.length)];
    _buildScene();

    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat()
     ..addListener(() => setState(() {
           _orbitAngle = _bgCtrl.value * pi * 2;
         }));

    _inCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _inCtrl, curve: Curves.easeOutCubic));

    _formCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320),
    )..forward();
    _formFade  = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.04), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _formCtrl, curve: Curves.easeOut));

    _pageFlipCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _pageFlipCtrl, curve: Curves.easeInOut));
  }

  void _buildScene() {
    final colors = [
      Colors.white, Colors.white, Colors.white,
      const Color(0xFFB8E8FF), const Color(0xFFD0C8FF),
    ];
    _stars = List.generate(80, (_) => _AuthStar(
      _rng.nextDouble(), _rng.nextDouble(),
      _rng.nextDouble() * 1.4 + 0.2,
      _rng.nextDouble() * 0.6 + 0.25,
      _rng.nextDouble() * 1.5 + 0.5,
      _rng.nextDouble() * pi * 2,
      colors[_rng.nextInt(colors.length)],
    ));

    final pageLineColors = [
      _accent, _purple, _accent, _purple, _accent, _purple,
    ];
    final pagePos = [
      (0.06, 0.12), (0.88, 0.16), (0.04, 0.55),
      (0.92, 0.50), (0.10, 0.82), (0.86, 0.78),
    ];
    _pages = List.generate(6, (i) => _AuthPage(
      x: pagePos[i].$1, y: pagePos[i].$2,
      phase:      _rng.nextDouble() * pi * 2,
      angle:      (_rng.nextDouble() - 0.5) * 0.55,
      size:       _rng.nextDouble() * 16 + 24,
      floatSpeed: _rng.nextDouble() * 0.22 + 0.10,
      floatRange: _rng.nextDouble() * 10   + 5,
      opacity:    _rng.nextDouble() * 0.09 + 0.07,
      lineColor:  pageLineColors[i],
    ));

    final inkColors = [_accent, _purple, _accent, _purple];
    final inkPos = [
      (0.08, 0.38), (0.90, 0.32), (0.06, 0.72), (0.92, 0.68),
    ];
    _inks = List.generate(4, (i) => _AuthInk(
      x: inkPos[i].$1, y: inkPos[i].$2,
      phase:      _rng.nextDouble() * pi * 2,
      rx:         _rng.nextDouble() * 2.5 + 2.5,
      ry:         _rng.nextDouble() * 3.5 + 4.0,
      angle:      (_rng.nextDouble() - 0.5) * 0.6,
      floatSpeed: _rng.nextDouble() * 0.18 + 0.08,
      floatRange: _rng.nextDouble() * 9    + 4,
      opacity:    _rng.nextDouble() * 0.16 + 0.10,
      color:      inkColors[i],
    ));
  }

  void _toggleMode(bool login) {
    if (_isLogin == login) return;
    _pageFlipCtrl.forward(from: 0);
    _formCtrl.reset();
    setState(() {
      _isLogin = login;
      _emailCtrl.clear();
      _passwordCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _formCtrl.forward();
    });
  }

  String _toThaiError(String msg) {
    if (msg.contains('already registered')) return 'อีเมลนี้ถูกใช้งานแล้ว';
    if (msg.contains('Invalid email'))      return 'รูปแบบอีเมลไม่ถูกต้อง';
    if (msg.contains('Password'))           return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    if (msg.contains('invalid login'))      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    if (msg.contains('network'))            return 'เชื่อมต่อไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
    return 'เกิดข้อผิดพลาด: $msg';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.redAccent : _accent, size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: GoogleFonts.kanit(color: _textPrim, fontSize: 13))),
      ]),
      backgroundColor: _card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError
              ? Colors.redAccent.withOpacity(0.4)
              : _accent.withOpacity(0.35),
        ),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  bool _validate() {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('กรุณากรอกอีเมล', isError: true); return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showSnack('อีเมลต้องมี @ และ .', isError: true); return false;
    }
    if (password.isEmpty) {
      _showSnack('กรุณากรอกรหัสผ่าน', isError: true); return false;
    }
    if (password.length < 8) {
      _showSnack('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        final res = await _supabase.auth.signUp(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        if (res.user == null) {
          _showSnack('ลงทะเบียนไม่สำเร็จ', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      _showSnack(_toThaiError(e.toString()), isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _inCtrl.dispose();
    _formCtrl.dispose();
    _pageFlipCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
              painter: _AuthBgPainter(
                  _stars, _pages, _inks, _bgCtrl.value)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        _buildLogo(),
                        const SizedBox(height: 16),
                        _buildTitle(),
                        const SizedBox(height: 28),
                        _buildGlassCard(),
                        const SizedBox(height: 20),
                        _buildSwitchLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    final pulse = (sin(_bgCtrl.value * pi * 2) + 1) / 2;
    return SizedBox(
      width: 110, height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(0.18),
                    blurRadius: 50, spreadRadius: 10),
                BoxShadow(color: _purple.withOpacity(0.14),
                    blurRadius: 60, spreadRadius: 14),
              ],
            ),
          ),
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: _accent.withOpacity(0.20 + 0.08 * pulse),
                  width: 0.7),
            ),
          ),
          Container(
            width: 82, height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: _accent.withOpacity(0.30 + 0.12 * pulse),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.12 + 0.06 * pulse),
                    blurRadius: 14, spreadRadius: 1),
              ],
            ),
            child: ClipOval(
              child: Image.network(
  kLogoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return CustomPaint(
                    painter: FictionLogoPainter(
                        pulse: pulse, orbitAngle: _orbitAngle),
                  );
                },
                errorBuilder: (_, __, ___) => CustomPaint(
                  painter: FictionLogoPainter(
                      pulse: pulse, orbitAngle: _orbitAngle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [
            Color(0xFFEAF2FF), Color(0xFF38BEFF), Color(0xFF9D6FFF),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(b),
        child: const Text('FICTION',
          style: TextStyle(
            color: Colors.white, fontSize: 36,
            fontWeight: FontWeight.w700, letterSpacing: 10,
            fontFamily: 'Georgia',
          ),
        ),
      ),
      const SizedBox(height: 8),
      _Typewriter(
        text: _isLogin ? 'begin your story...' : 'a new chapter awaits...',
        style: const TextStyle(
          color: Color(0xFF6B7FA3), fontSize: 13,
          fontStyle: FontStyle.italic, fontFamily: 'Georgia',
          letterSpacing: 1.0,
        ),
        speed: const Duration(milliseconds: 55),
      ),
    ]);
  }

  

  // ── Glass card ─────────────────────────────────────────────────────────────
  Widget _buildGlassCard() {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (_, child) {
        final flip = _flipAnim.value;
        final scaleX = flip < 0.5
            ? 1.0 - flip * 2 * 0.08
            : 0.84 + (flip - 0.5) * 2 * 0.16;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(scaleX, 1.0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF0C1525).withOpacity(0.92),
          border: Border.all(
              color: _accent.withOpacity(0.16), width: 0.8),
          boxShadow: [
            BoxShadow(color: _accent.withOpacity(0.06), blurRadius: 30),
            BoxShadow(color: Colors.black.withOpacity(0.5),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(children: [
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _accent.withOpacity(0.4),
                  Colors.transparent,
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Column(children: [
                _buildTabToggle(),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _formFade,
                  child: SlideTransition(
                    position: _formSlide,
                    child: Column(children: [
                      _buildTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Tab toggle ─────────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF060C18),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _divider, width: 0.7),
      ),
      child: Row(children: [
        _buildTab('เข้าสู่ระบบ',
            isActive: _isLogin, onTap: () => _toggleMode(true)),
        _buildTab('สมัครสมาชิก',
            isActive: !_isLogin, onTap: () => _toggleMode(false)),
      ]),
    );
  }

  Widget _buildTab(String label,
      {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [
                    Color(0xFF38BEFF), Color(0xFF1A8FD1),
                  ])
                : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [BoxShadow(color: _accent.withOpacity(0.3),
                    blurRadius: 12, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: GoogleFonts.kanit(
              color: isActive ? _bg : _textSub,
              fontSize: 13, fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.kanit(color: _textPrim, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.kanit(color: _textSub, fontSize: 13),
        floatingLabelStyle:
            GoogleFonts.kanit(color: _accent, fontSize: 11),
        prefixIcon: Icon(icon, color: _textSub, size: 20),
        filled: true, fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  // ── Password field ─────────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: !_showPassword,
      style: GoogleFonts.kanit(color: _textPrim, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.kanit(color: _textSub, fontSize: 13),
        floatingLabelStyle:
            GoogleFonts.kanit(color: _accent, fontSize: 11),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: _textSub, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _textSub, size: 20,
          ),
          onPressed: () =>
              setState(() => _showPassword = !_showPassword),
        ),
        filled: true, fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  // ── Submit button ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isLoading
              ? LinearGradient(colors: [_surface, _surface])
              : const LinearGradient(colors: [
                  Color(0xFF38BEFF), Color(0xFF1A8FD1),
                ]),
          boxShadow: _isLoading ? [] : [
            BoxShadow(color: _accent.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ))
              : Text(_isLogin ? 'SIGN IN' : 'REGISTER',
                  style: GoogleFonts.kanit(
                    color: _bg, fontSize: 13,
                    letterSpacing: 3, fontWeight: FontWeight.w700,
                  )),
        ),
      ),
    );
  }

  // ── Switch link ────────────────────────────────────────────────────────────
  Widget _buildSwitchLink() {
    return GestureDetector(
      onTap: () => _toggleMode(!_isLogin),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.kanit(fontSize: 13, color: _textSub),
          children: [
            TextSpan(
                text: _isLogin ? 'ยังไม่มีบัญชี?  ' : 'มีบัญชีแล้ว?  '),
            TextSpan(
              text: _isLogin ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
              style: GoogleFonts.kanit(
                  color: _accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}