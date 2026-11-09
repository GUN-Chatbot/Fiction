import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart';

const _bg     = Color(0xFF080C14);
const _accent = Color(0xFF38BEFF);
const _textPrim = Color(0xFFE8F0FF);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Fade in 0→1 ช่วงแรก
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Fade out 1→0 ช่วงหลัง
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward().then((_) => _navigate());
  }

  void _navigate() {
    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            session == null ? const AuthPage() : const HomePage(),
        transitionDuration: Duration.zero, // fade ทำเองแล้วข้างบน
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // ช่วง fade-in ใช้ _fadeIn, ช่วง fade-out ใช้ _fadeOut
            final opacity = _ctrl.value < 0.65 ? _fadeIn.value : _fadeOut.value;
            return Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ───────────────────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141C2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _accent.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded, // ← เปลี่ยนเป็น logo จริงได้
                      color: _accent,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── App name ───────────────────────────────────────────
                  const Text(
                    'MY APP',          // ← เปลี่ยนชื่อแอปตรงนี้
                    style: TextStyle(
                      color: _textPrim,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TAGLINE HERE',    // ← หรือจะลบทิ้งก็ได้
                    style: TextStyle(
                      color: _accent.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}