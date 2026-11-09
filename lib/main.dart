import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _bg = Color(0xFF03050C);
const _accent = Color(0xFF38BEFF);
const _purple = Color(0xFF9D6FFF);
const _rose = Color(0xFFFF6B9D);
const _gold = Color(0xFFFFD166);
const _textPrim = Color(0xFFEAF2FF);

String get kLogoUrl => dotenv.env['SUPABASE_LOGO_URL'] ?? '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fiction',
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.dark(
          primary: _accent,
          secondary: _accent,
          surface: const Color(0xFF0E1624),
          background: _bg,
          onPrimary: _bg,
          onSurface: _textPrim,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF6B7FA3)),
          titleTextStyle: TextStyle(
            color: Color(0xFF6B7FA3),
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _bg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0E1624),
          labelStyle: const TextStyle(color: Color(0xFF6B7FA3), fontSize: 13),
          floatingLabelStyle: const TextStyle(color: _accent, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E2A42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF0E1624),
          contentTextStyle: const TextStyle(color: _textPrim),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0E1624),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2A42),
          thickness: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _accent,
        ),
      ),
      home: const SplashPage(),
    );
  }
}

// ══════════════════════════════════════════════════════
//  MODELS
// ══════════════════════════════════════════════════════

class _Star {
  final double x, y, baseSize, twinkleOffset, twinkleSpeed, depth, revealRadius;
  final Color color;
  _Star({
    required this.x,
    required this.y,
    required this.baseSize,
    required this.twinkleOffset,
    required this.twinkleSpeed,
    required this.depth,
    required this.revealRadius,
    required this.color,
  });
}

class _Comet {
  double x, y, progress;
  final double angle, speed, tailLength, headSize, opacity;
  final Color headColor;
  bool active;
  _Comet({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.tailLength,
    required this.headSize,
    required this.opacity,
    required this.headColor,
    this.active = false,
    this.progress = 0,
  });
}

class _DustParticle {
  double x, y, phase;
  final double size, floatSpeed, floatRange, baseOpacity;
  final Color color;
  _DustParticle({
    required this.x,
    required this.y,
    required this.phase,
    required this.size,
    required this.floatSpeed,
    required this.floatRange,
    required this.baseOpacity,
    required this.color,
  });
}

class _FloatingPage {
  double x, y, phase;
  final double angle, size, floatSpeed, floatRange, opacity;
  final Color lineColor;
  _FloatingPage({
    required this.x,
    required this.y,
    required this.phase,
    required this.angle,
    required this.size,
    required this.floatSpeed,
    required this.floatRange,
    required this.opacity,
    required this.lineColor,
  });
}

class _InkDrop {
  double x, y, phase;
  final double rx, ry, angle, floatSpeed, floatRange, opacity;
  final Color color;
  _InkDrop({
    required this.x,
    required this.y,
    required this.phase,
    required this.rx,
    required this.ry,
    required this.angle,
    required this.floatSpeed,
    required this.floatRange,
    required this.opacity,
    required this.color,
  });
}

// ══════════════════════════════════════════════════════
//  FICTION LOGO PAINTER  (fallback — open book + galaxy)
// ══════════════════════════════════════════════════════

class FictionLogoPainter extends CustomPainter {
  final double pulse;
  final double orbitAngle;

  FictionLogoPainter({required this.pulse, required this.orbitAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.5;
    _drawBackground(canvas, size, cx, cy, r);
    _drawOrbitRings(canvas, cx, cy, r);
    _drawOrbitParticle(canvas, cx, cy, r);
    _drawGalaxySpiral(canvas, cx, cy, r);
    _drawOpenBook(canvas, cx, cy, r);
    _drawMicroStars(canvas, cx, cy, r);
  }

  void _drawBackground(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(r * 0.44),
      ),
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF1A2D55), Color(0xFF08111F)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    _glow(canvas, cx, cy, r * 0.85, _purple.withOpacity(0.18 + 0.06 * pulse));
    _glow(canvas, cx, cy, r * 0.65, _accent.withOpacity(0.12 + 0.06 * pulse));
  }

  void _drawOrbitRings(Canvas canvas, double cx, double cy, double r) {
    _orbitEllipse(
      canvas,
      cx,
      cy,
      rx: r * 0.72,
      ry: r * 0.20,
      tilt: -0.32,
      color: _accent,
      opacity: 0.35 + 0.10 * pulse,
      width: 0.9,
      dashed: false,
    );
    _orbitEllipse(
      canvas,
      cx,
      cy,
      rx: r * 0.82,
      ry: r * 0.18,
      tilt: 0.28,
      color: _purple,
      opacity: 0.25 + 0.08 * pulse,
      width: 0.6,
      dashed: true,
    );
  }

  void _drawOrbitParticle(Canvas canvas, double cx, double cy, double r) {
    final px = cx + cos(orbitAngle) * r * 0.72;
    final py = cy + sin(orbitAngle) * r * 0.20;
    _glow(canvas, px, py, 5.5, _accent.withOpacity(0.50 + 0.28 * pulse));
    canvas.drawCircle(
      Offset(px, py),
      2.2,
      Paint()..color = Colors.white.withOpacity(0.95),
    );
  }

  void _drawGalaxySpiral(Canvas canvas, double cx, double cy, double r) {
    final s = r / 54.0;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(cx + 30 * s, cy - 28 * s, cx + 52 * s, cy - 42 * s)
        ..quadraticBezierTo(cx + 70 * s, cy - 50 * s, cx + 80 * s, cy - 44 * s),
      Paint()
        ..color = _accent.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(cx + 22 * s, cy + 20 * s, cx + 34 * s, cy + 38 * s)
        ..quadraticBezierTo(cx + 42 * s, cy + 52 * s, cx + 36 * s, cy + 62 * s),
      Paint()
        ..color = _purple.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawOpenBook(Canvas canvas, double cx, double cy, double r) {
    final s = r / 56.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 32 * s),
        width: 80 * s,
        height: 10 * s,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final leftPage = Path()
      ..moveTo(cx, cy - 28 * s)
      ..quadraticBezierTo(cx - 4 * s, cy - 30 * s, cx - 28 * s, cy - 26 * s)
      ..lineTo(cx - 32 * s, cy + 28 * s)
      ..quadraticBezierTo(cx - 8 * s, cy + 32 * s, cx, cy + 28 * s)
      ..close();
    canvas.drawPath(
      leftPage,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F0FF).withOpacity(0.88),
            const Color(0xFFB8C8E8).withOpacity(0.80),
          ],
        ).createShader(Rect.fromLTWH(cx - 34 * s, cy - 32 * s, 36 * s, 62 * s)),
    );

    final leftLineColors = [
      _accent.withOpacity(0.55),
      _accent.withOpacity(0.40),
      _accent.withOpacity(0.38),
      _accent.withOpacity(0.32),
      _accent.withOpacity(0.28),
      _accent.withOpacity(0.22),
    ];
    for (int i = 0; i < leftLineColors.length; i++) {
      final ly = cy - 14 * s + i * 9 * s;
      canvas.drawLine(
        Offset(cx - 24 * s + i * 0.5 * s, ly),
        Offset(cx - 3 * s, ly),
        Paint()
          ..color = leftLineColors[i]
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round,
      );
    }

    final rightPage = Path()
      ..moveTo(cx, cy - 28 * s)
      ..quadraticBezierTo(cx + 4 * s, cy - 30 * s, cx + 28 * s, cy - 26 * s)
      ..lineTo(cx + 32 * s, cy + 28 * s)
      ..quadraticBezierTo(cx + 8 * s, cy + 32 * s, cx, cy + 28 * s)
      ..close();
    canvas.drawPath(
      rightPage,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFE0ECFF).withOpacity(0.84),
            const Color(0xFFB0C0E0).withOpacity(0.76),
          ],
        ).createShader(Rect.fromLTWH(cx, cy - 32 * s, 36 * s, 62 * s)),
    );

    final rightLineColors = [
      _purple.withOpacity(0.55),
      _purple.withOpacity(0.40),
      _purple.withOpacity(0.38),
      _purple.withOpacity(0.32),
      _purple.withOpacity(0.28),
      _purple.withOpacity(0.22),
    ];
    for (int i = 0; i < rightLineColors.length; i++) {
      final ly = cy - 14 * s + i * 9 * s;
      canvas.drawLine(
        Offset(cx + 3 * s, ly),
        Offset(cx + 24 * s - i * 0.5 * s, ly),
        Paint()
          ..color = rightLineColors[i]
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawLine(
      Offset(cx, cy - 28 * s),
      Offset(cx, cy + 28 * s),
      Paint()
        ..color = _accent.withOpacity(0.55 + 0.25 * pulse)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx, cy - 28 * s),
      Offset(cx, cy + 28 * s),
      Paint()
        ..color = Colors.white.withOpacity(0.45 + 0.20 * pulse)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 14 * s, cy + 8 * s),
        width: 6 * s,
        height: 8 * s,
      ),
      Paint()..color = _accent.withOpacity(0.38),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 14 * s, cy + 2 * s),
        width: 5 * s,
        height: 7 * s,
      ),
      Paint()..color = _purple.withOpacity(0.38),
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx - 32 * s, cy + 28 * s)
        ..quadraticBezierTo(cx, cy + 38 * s, cx + 32 * s, cy + 28 * s),
      Paint()
        ..color = _accent.withOpacity(0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawMicroStars(Canvas canvas, double cx, double cy, double r) {
    const dots = [
      (0.62, -0.55, 0xFF38BEFF, 1.1),
      (-0.55, 0.45, 0xFF9D6FFF, 0.9),
      (0.48, 0.58, 0xFFFFFFFF, 0.8),
      (-0.50, -0.48, 0xFF38BEFF, 0.8),
      (0.70, 0.30, 0xFFC8A0FF, 0.7),
      (-0.65, 0.22, 0xFFFFFFFF, 0.7),
      (0.25, -0.70, 0xFF38BEFF, 0.8),
      (-0.42, 0.68, 0xFF9D6FFF, 0.9),
    ];
    for (final d in dots) {
      canvas.drawCircle(
        Offset(cx + d.$1 * r, cy + d.$2 * r),
        d.$4,
        Paint()..color = Color(d.$3).withOpacity(0.72),
      );
    }
  }

  void _glow(Canvas canvas, double cx, double cy, double radius, Color color) {
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
    );
  }

  void _orbitEllipse(
    Canvas canvas,
    double cx,
    double cy, {
    required double rx,
    required double ry,
    required double tilt,
    required Color color,
    required double opacity,
    required double width,
    required bool dashed,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tilt);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      const segments = 48;
      for (int i = 0; i < segments; i++) {
        if (i % 3 == 2) continue;
        final a1 = (i / segments) * 2 * pi;
        final a2 = ((i + 0.75) / segments) * 2 * pi;
        canvas.drawLine(
          Offset(cos(a1) * rx, sin(a1) * ry),
          Offset(cos(a2) * rx, sin(a2) * ry),
          paint,
        );
      }
    } else {
      final path = Path();
      const steps = 80;
      for (int i = 0; i <= steps; i++) {
        final a = (i / steps) * 2 * pi;
        final pt = Offset(cos(a) * rx, sin(a) * ry);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FictionLogoPainter old) =>
      old.pulse != pulse || old.orbitAngle != orbitAngle;
}

// ══════════════════════════════════════════════════════
//  LOGO WIDGET  (Network image + fallback painter)
// ══════════════════════════════════════════════════════

class _LogoImage extends StatelessWidget {
  final double size;
  final double pulse;
  final double orbitAngle;

  const _LogoImage({
    required this.size,
    required this.pulse,
    required this.orbitAngle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        kLogoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: FictionLogoPainter(pulse: pulse, orbitAngle: orbitAngle),
            ),
          );
        },
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: FictionLogoPainter(pulse: pulse, orbitAngle: orbitAngle),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SPACE BACKGROUND PAINTER
// ══════════════════════════════════════════════════════

class _SpacePainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Comet> comets;
  final List<_DustParticle> dust;
  final List<_FloatingPage> pages;
  final List<_InkDrop> inkDrops;
  final double t;
  final double orbitAngle;

  _SpacePainter(
    this.stars,
    this.comets,
    this.dust,
    this.pages,
    this.inkDrops,
    this.t,
    this.orbitAngle,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.43;
    _paintDeepSpace(canvas, size, cx, cy);
    _paintHexGrid(canvas, size);
    _paintFloatingPages(canvas, size);
    _paintInkDrops(canvas, size);
    _paintDust(canvas, size);
    _paintStars(canvas, size, cx, cy);
    _paintOrbitRings(canvas, size, cx, cy);
    _paintComets(canvas, size);
  }

  void _paintDeepSpace(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (cx / size.width) * 2 - 1,
            (cy / size.height) * 2 - 1,
          ),
          colors: const [
            Color(0xFF060D1C),
            Color(0xFF030610),
            Color(0xFF03050C),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    _nebula(
      canvas,
      size,
      Offset(size.width * 0.18, size.height * 0.22),
      size.width * 0.65,
      const Color(0xFF0A1E40),
      0.8,
    );
    _nebula(
      canvas,
      size,
      Offset(size.width * 0.82, size.height * 0.15),
      size.width * 0.5,
      const Color(0xFF1A0A30),
      0.7,
    );
    _nebula(
      canvas,
      size,
      Offset(size.width * 0.5, size.height * 0.75),
      size.width * 0.55,
      const Color(0xFF071820),
      0.65,
    );
    _nebula(
      canvas,
      size,
      Offset(cx, cy),
      size.width * 0.45,
      const Color(0xFF112240),
      0.55 * t,
    );

    final auroraT = (sin(t * pi * 1.5) + 1) / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -1.5),
          radius: 1.2,
          colors: [
            _purple.withOpacity((0.18 + 0.08 * auroraT) * t),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-1.2, -0.8),
          radius: 0.9,
          colors: [_rose.withOpacity(0.06 * t), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _nebula(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintHexGrid(Canvas canvas, Size size) {
    if (t < 0.1) return;
    final opacity = (t * 0.5).clamp(0.0, 0.05);
    final paint = Paint()
      ..color = _accent.withOpacity(opacity)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    const hexR = 32.0;
    final hexH = hexR * sqrt(3);
    final cols = (size.width / (hexR * 1.5)).ceil() + 2;
    final rows = (size.height / hexH).ceil() + 2;
    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final ox = col * hexR * 3 + (row.isOdd ? hexR * 1.5 : 0);
        final oy = row * hexH;
        _drawHex(canvas, Offset(ox, oy), hexR, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = pi / 180 * (60 * i - 30);
      final pt = Offset(center.dx + r * cos(a), center.dy + r * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintFloatingPages(Canvas canvas, Size size) {
    if (t < 0.05) return;
    final pageOpacity = (t * 2).clamp(0.0, 1.0);
    for (final p in pages) {
      final fy = sin(t * pi * 2 * p.floatSpeed + p.phase) * p.floatRange;
      final fx =
          cos(t * pi * p.floatSpeed * 0.6 + p.phase) * p.floatRange * 0.4;
      canvas.save();
      canvas.translate(p.x * size.width + fx, p.y * size.height + fy);
      canvas.rotate(
        p.angle + sin(t * pi * p.floatSpeed * 0.3 + p.phase) * 0.06,
      );
      final w = p.size;
      final h = p.size * 1.3;
      final op = p.opacity * pageOpacity;
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE8F0FF).withOpacity(op),
              const Color(0xFFB8C8E8).withOpacity(op * 0.85),
            ],
          ).createShader(rect),
      );
      for (int i = 0; i < 4; i++) {
        final ly = -h * 0.3 + i * (h * 0.18);
        canvas.drawLine(
          Offset(-w * 0.35, ly),
          Offset(w * 0.35, ly),
          Paint()
            ..color = p.lineColor.withOpacity(op * (0.55 - i * 0.08))
            ..strokeWidth = 0.7
            ..strokeCap = StrokeCap.round,
        );
      }
      final fs = w * 0.22;
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.5 - fs, h * 0.5)
          ..lineTo(w * 0.5, h * 0.5 - fs)
          ..lineTo(w * 0.5, h * 0.5),
        Paint()
          ..color = p.lineColor.withOpacity(op * 0.4)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }
  }

  void _paintInkDrops(Canvas canvas, Size size) {
    if (t < 0.08) return;
    final dropOpacity = (t * 2).clamp(0.0, 1.0);
    for (final d in inkDrops) {
      final fy = sin(t * pi * 2 * d.floatSpeed + d.phase) * d.floatRange;
      final fx =
          cos(t * pi * d.floatSpeed * 0.5 + d.phase) * d.floatRange * 0.5;
      canvas.save();
      canvas.translate(d.x * size.width + fx, d.y * size.height + fy);
      canvas.rotate(d.angle);
      final op = d.opacity * dropOpacity;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: d.rx * 2, height: d.ry * 2),
        Paint()
          ..color = d.color.withOpacity(op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
      for (int i = 0; i < 3; i++) {
        final a = (i / 3) * 2 * pi + d.phase;
        canvas.drawCircle(
          Offset(cos(a) * d.rx * 1.8, sin(a) * d.ry * 1.8),
          d.rx * 0.25,
          Paint()..color = d.color.withOpacity(op * 0.5),
        );
      }
      canvas.restore();
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    for (final d in dust) {
      final fy = sin(t * pi * 2 * d.floatSpeed + d.phase) * d.floatRange;
      final fx =
          cos(t * pi * d.floatSpeed * 0.7 + d.phase) * d.floatRange * 0.5;
      final op =
          d.baseOpacity * ((sin(t * pi * 3 * d.floatSpeed + d.phase) + 1) / 2);
      canvas.drawCircle(
        Offset(d.x * size.width + fx, d.y * size.height + fy),
        d.size,
        Paint()
          ..color = d.color.withOpacity(op * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.size * 1.5),
      );
    }
  }

  void _paintStars(Canvas canvas, Size size, double cx, double cy) {
    for (final s in stars) {
      final revealT = ((t - s.revealRadius * 0.3) / 0.4).clamp(0.0, 1.0);
      if (revealT <= 0) continue;
      final twinkle =
          (sin(t * pi * 4 * s.twinkleSpeed + s.twinkleOffset) + 1) / 2;
      final opacity = ((0.2 + 0.65 * s.depth + 0.3 * twinkle) * revealT).clamp(
        0.0,
        1.0,
      );
      final sz = s.baseSize * (0.88 + 0.12 * twinkle);
      final pos = Offset(s.x * size.width, s.y * size.height);
      if (s.baseSize > 1.8) {
        canvas.drawCircle(
          pos,
          sz * 3.0,
          Paint()
            ..color = s.color.withOpacity(opacity * 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 3.0),
        );
        canvas.drawCircle(
          pos,
          sz * 1.5,
          Paint()
            ..color = s.color.withOpacity(opacity * 0.5)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz),
        );
      }
      canvas.drawCircle(pos, sz, Paint()..color = s.color.withOpacity(opacity));
      if (s.baseSize > 2.2 && opacity > 0.5) {
        final sp = Paint()
          ..color = s.color.withOpacity(opacity * 0.35)
          ..strokeWidth = 0.6
          ..strokeCap = StrokeCap.round;
        final sl = sz * 6;
        canvas.drawLine(
          Offset(pos.dx - sl, pos.dy),
          Offset(pos.dx + sl, pos.dy),
          sp,
        );
        canvas.drawLine(
          Offset(pos.dx, pos.dy - sl),
          Offset(pos.dx, pos.dy + sl),
          sp,
        );
      }
    }
  }

  void _paintOrbitRings(Canvas canvas, Size size, double cx, double cy) {
    if (t < 0.15) return;
    final ringT = ((t - 0.15) / 0.3).clamp(0.0, 1.0);
    _bgOrbitEllipse(
      canvas,
      cx,
      cy,
      rx: 72 * ringT,
      ry: 22 * ringT,
      tilt: -0.3,
      angle: orbitAngle,
      color: _accent,
      opacity: 0.35 * ringT,
      width: 0.8,
      dashed: false,
    );
    _bgOrbitEllipse(
      canvas,
      cx,
      cy,
      rx: 95 * ringT,
      ry: 28 * ringT,
      tilt: 0.5,
      angle: -orbitAngle * 0.7,
      color: _purple,
      opacity: 0.25 * ringT,
      width: 0.6,
      dashed: true,
    );
    if (ringT > 0.6) {
      final pAngle = orbitAngle * 2;
      final px = cx + cos(pAngle) * 72 * ringT;
      final py = cy + sin(pAngle) * 22 * ringT;
      final po = ((ringT - 0.6) / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(px, py),
        2.5,
        Paint()
          ..color = _accent.withOpacity(po)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(px, py),
        1.2,
        Paint()..color = Colors.white.withOpacity(po),
      );
    }
  }

  void _bgOrbitEllipse(
    Canvas canvas,
    double cx,
    double cy, {
    required double rx,
    required double ry,
    required double tilt,
    required double angle,
    required Color color,
    required double opacity,
    required double width,
    required bool dashed,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tilt);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      const seg = 60;
      for (int i = 0; i < seg; i++) {
        if (i % 3 == 2) continue;
        final a1 = (i / seg) * 2 * pi + angle;
        final a2 = ((i + 0.8) / seg) * 2 * pi + angle;
        canvas.drawLine(
          Offset(cos(a1) * rx, sin(a1) * ry),
          Offset(cos(a2) * rx, sin(a2) * ry),
          paint,
        );
      }
    } else {
      final path = Path();
      const steps = 120;
      for (int i = 0; i <= steps; i++) {
        final a = (i / steps) * 2 * pi + angle;
        final pt = Offset(cos(a) * rx, sin(a) * ry);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  void _paintComets(Canvas canvas, Size size) {
    for (final c in comets) {
      if (!c.active) continue;
      final head = Offset(c.x * size.width, c.y * size.height);
      final tail = Offset(
        head.dx - cos(c.angle) * c.tailLength * c.progress,
        head.dy - sin(c.angle) * c.tailLength * c.progress,
      );
      canvas.drawLine(
        head,
        tail,
        Paint()
          ..shader = LinearGradient(
            colors: [
              c.headColor.withOpacity(c.opacity * c.progress),
              Colors.transparent,
            ],
          ).createShader(Rect.fromPoints(head, tail))
          ..strokeWidth = c.headSize * 0.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        head,
        tail,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(c.opacity * c.progress * 0.6),
              Colors.transparent,
            ],
          ).createShader(Rect.fromPoints(head, tail))
          ..strokeWidth = c.headSize * 0.25
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        head,
        c.headSize * 2.5,
        Paint()
          ..color = c.headColor.withOpacity(c.opacity * 0.3 * c.progress)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.headSize * 2),
      );
      canvas.drawCircle(
        head,
        c.headSize,
        Paint()..color = Colors.white.withOpacity(c.opacity * 0.9 * c.progress),
      );
    }
  }

  @override
  bool shouldRepaint(_SpacePainter old) => true;
}

// ══════════════════════════════════════════════════════
//  SPLASH PAGE
// ══════════════════════════════════════════════════════

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _ringPulse;
  late Animation<double> _textReveal;
  late Animation<double> _taglineReveal;
  late Animation<double> _progressFill;
  late Animation<double> _exitFade;

  final _rng = Random();
  final _stars = <_Star>[];
  final _comets = <_Comet>[];
  final _dust = <_DustParticle>[];
  final _pages = <_FloatingPage>[];
  final _inks = <_InkDrop>[];

  double _orbitAngle = 0;
  double _lastComet = 0;
  int _cometIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildScene();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    _bgFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    );
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.07, 0.3, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.06, 0.42, curve: Curves.elasticOut),
      ),
    );
    _ringPulse = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.7, curve: Curves.elasticOut),
      ),
    );
    _textReveal = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.58, curve: Curves.easeOut),
    );
    _taglineReveal = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 0.68, curve: Curves.easeOut),
    );
    _progressFill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 0.88, curve: Curves.easeInOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.addListener(_tick);
    _ctrl.forward().then((_) => _navigate());
  }

  void _buildScene() {
    final starConfigs = [
      (90, 0.10, 0.55, 0.7, 0.3, 0.2, 0.2, 0xFFFFFFFF),
      (45, 0.45, 0.85, 1.4, 0.6, 0.4, 0.3, 0xFF38BEFF),
      (18, 1.60, 1.40, 2.2, 1.0, 0.7, 0.3, 0xFF38BEFF),
      (10, 1.20, 1.00, 1.6, 0.8, 0.5, 0.5, 0xFF9D6FFF),
      (5, 2.40, 0.70, 3.0, 1.5, 0.8, 0.3, 0xFFFFD166),
    ];
    for (final c in starConfigs) {
      for (int i = 0; i < c.$1; i++) {
        _stars.add(
          _Star(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            baseSize: _rng.nextDouble() * c.$3 + c.$2,
            twinkleOffset: _rng.nextDouble() * pi * 2,
            twinkleSpeed: _rng.nextDouble() * c.$5 + c.$4,
            depth: c.$6 + _rng.nextDouble() * c.$7,
            revealRadius: _rng.nextDouble(),
            color: Color(c.$8).withOpacity(1),
          ),
        );
      }
    }

    final cometColors = [_accent, Colors.white, _purple, _rose, _gold, _accent];
    for (int i = 0; i < 6; i++) {
      _comets.add(
        _Comet(
          x: _rng.nextDouble() * 0.6 + 0.15,
          y: _rng.nextDouble() * 0.3 + 0.02,
          angle: pi / 4 + (_rng.nextDouble() - 0.5) * 0.5,
          speed: _rng.nextDouble() * 0.005 + 0.003,
          tailLength: _rng.nextDouble() * 110 + 80,
          headSize: _rng.nextDouble() * 1.2 + 1.0,
          opacity: _rng.nextDouble() * 0.45 + 0.5,
          headColor: cometColors[i],
        ),
      );
    }

    final dustColors = [_accent, _purple, _rose, Colors.white];
    for (int i = 0; i < 30; i++) {
      _dust.add(
        _DustParticle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble() * 0.7 + 0.15,
          phase: _rng.nextDouble() * pi * 2,
          size: _rng.nextDouble() * 1.5 + 0.5,
          floatSpeed: _rng.nextDouble() * 0.4 + 0.15,
          floatRange: _rng.nextDouble() * 8 + 3,
          baseOpacity: _rng.nextDouble() * 0.12 + 0.04,
          color: dustColors[_rng.nextInt(dustColors.length)],
        ),
      );
    }

    final pageLineColors = [
      _accent,
      _purple,
      _accent,
      _purple,
      _accent,
      _purple,
    ];
    final pagePositions = [
      (0.12, 0.28),
      (0.85, 0.20),
      (0.08, 0.62),
      (0.90, 0.55),
      (0.18, 0.78),
      (0.82, 0.72),
    ];
    for (int i = 0; i < 6; i++) {
      _pages.add(
        _FloatingPage(
          x: pagePositions[i].$1,
          y: pagePositions[i].$2,
          phase: _rng.nextDouble() * pi * 2,
          angle: (_rng.nextDouble() - 0.5) * 0.5,
          size: _rng.nextDouble() * 18 + 28,
          floatSpeed: _rng.nextDouble() * 0.25 + 0.1,
          floatRange: _rng.nextDouble() * 12 + 6,
          opacity: _rng.nextDouble() * 0.10 + 0.08,
          lineColor: pageLineColors[i],
        ),
      );
    }

    final inkColors = [_accent, _purple, _accent, _purple];
    final inkPositions = [
      (0.18, 0.45),
      (0.78, 0.38),
      (0.10, 0.70),
      (0.88, 0.65),
    ];
    for (int i = 0; i < 4; i++) {
      _inks.add(
        _InkDrop(
          x: inkPositions[i].$1,
          y: inkPositions[i].$2,
          phase: _rng.nextDouble() * pi * 2,
          rx: _rng.nextDouble() * 3 + 3,
          ry: _rng.nextDouble() * 4 + 4.5,
          angle: (_rng.nextDouble() - 0.5) * 0.6,
          floatSpeed: _rng.nextDouble() * 0.2 + 0.1,
          floatRange: _rng.nextDouble() * 10 + 5,
          opacity: _rng.nextDouble() * 0.18 + 0.12,
          color: inkColors[i],
        ),
      );
    }
  }

  void _tick() {
    final v = _ctrl.value;
    _orbitAngle = v * pi * 3;
    if (v > 0.1 && v - _lastComet > 0.14 && _cometIndex < _comets.length) {
      _comets[_cometIndex]
        ..active = true
        ..progress = 0
        ..x = _rng.nextDouble() * 0.55 + 0.15
        ..y = _rng.nextDouble() * 0.28 + 0.02;
      _lastComet = v;
      _cometIndex++;
    }
    for (final c in _comets) {
      if (!c.active) continue;
      c.x += cos(c.angle) * c.speed;
      c.y += sin(c.angle) * c.speed;
      c.progress = (c.progress + 0.05).clamp(0.0, 1.0);
      if (c.x > 1.2 || c.y > 1.1) c.active = false;
    }
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthPage(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_tick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final exit = _ctrl.value >= 0.90 ? _exitFade.value : 1.0;
          return Opacity(
            opacity: exit,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: _bgFade.value,
                  child: CustomPaint(
                    painter: _SpacePainter(
                      _stars,
                      _comets,
                      _dust,
                      _pages,
                      _inks,
                      _ctrl.value,
                      _orbitAngle,
                    ),
                  ),
                ),
                Center(child: _buildContent()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(),
        const SizedBox(height: 40),
        _buildAppName(),
        const SizedBox(height: 10),
        _buildDivider(),
        const SizedBox(height: 10),
        _buildTagline(),
        const SizedBox(height: 14),
        _buildChapterDots(),
        const SizedBox(height: 50),
        _buildProgress(),
      ],
    );
  }

  Widget _buildLogo() {
    final pulse = (sin(_ctrl.value * pi * 5) + 1) / 2;
    return Transform.scale(
      scale: _logoScale.value,
      child: Opacity(
        opacity: _logoFade.value,
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.20 + 0.08 * pulse),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: _accent.withOpacity(0.25 + 0.10 * pulse),
                      blurRadius: 50 + 15 * pulse,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: _ringPulse.value,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accent.withOpacity(0.22 + 0.08 * pulse),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _purple.withOpacity(0.18),
                    width: 0.5,
                  ),
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withOpacity(0.35 + 0.15 * pulse),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.15 + 0.08 * pulse),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _LogoImage(
                  size: 108,
                  pulse: pulse,
                  orbitAngle: _orbitAngle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return Opacity(
      opacity: _textReveal.value,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - _textReveal.value)),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFEAF2FF),
              Color(0xFF9CD8FF),
              Color(0xFF38BEFF),
              Color(0xFF9D6FFF),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'FICTION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              fontFamily: 'Georgia',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Opacity(
      opacity: _taglineReveal.value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 60, height: 0.5, color: _accent.withOpacity(0.3)),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 6,
              height: 6,
              color: _accent.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 60, height: 0.5, color: _accent.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Opacity(
      opacity: _taglineReveal.value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - _taglineReveal.value)),
        child: const Text(
          '"where stories meet the stars"',
          style: TextStyle(
            color: Color(0xFF9D6FFF),
            fontSize: 13,
            fontStyle: FontStyle.italic,
            fontFamily: 'Georgia',
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterDots() {
    return Opacity(
      opacity: _taglineReveal.value * 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final isActive = i == 2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 6 : 4,
            height: isActive ? 6 : 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? _accent.withOpacity(0.9)
                  : const Color(0xFF1E2A42),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgress() {
    return Opacity(
      opacity: _taglineReveal.value,
      child: Column(
        children: [
          SizedBox(
            width: 140,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2540),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progressFill.value,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x5538BEFF), _accent, _purple],
                        stops: [0.0, 0.65, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (_progressFill.value * 140 - 3).clamp(0.0, 137.0),
                  top: -3,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.9),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: (_progressFill.value * 1.5).clamp(0.0, 1.0),
            child: Text(
              '${(_progressFill.value * 100).round()}%',
              style: GoogleFonts.kanit(
                color: _accent.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
