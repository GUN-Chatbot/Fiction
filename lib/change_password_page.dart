import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Palette (เหมือนกับ ProfilePage) ─────────────────────────────────────────
const _bg        = Color(0xFF080C14);
const _surface   = Color(0xFF0F1520);
const _card      = Color(0xFF141C2E);
const _accent    = Color(0xFF38BEFF);
const _accentSoft= Color(0x3338BEFF);
const _textPrim  = Color(0xFFE8F0FF);
const _textSub   = Color(0xFF6B7FA3);
const _divider   = Color(0xFF1E2A42);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final supabase                = Supabase.instance.client;
  final newPasswordController   = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading      = false;
  bool _showNew       = false;
  bool _showConfirm   = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────────
  Future<void> changePassword() async {
    final newPassword     = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.length < 8) {
      _showSnack("รหัสผ่านต้องอย่างน้อย 8 ตัวอักษร", isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnack("รหัสผ่านไม่ตรงกัน", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      _showSnack("เปลี่ยนรหัสผ่านสำเร็จ");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack("เกิดข้อผิดพลาด: $e", isError: true);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : _accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: _textPrim))),
          ],
        ),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? Colors.redAccent.withOpacity(0.4) : _accentSoft),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textSub, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          "CHANGE PASSWORD",
          style: TextStyle(
            color: _textSub,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gold rule
                Center(
                  child: Container(
                    width: 40, height: 1.5,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Icon header
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _card,
                      border: Border.all(color: _divider),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: _accent, size: 34),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "ตั้งรหัสผ่านใหม่",
                    style: TextStyle(
                      color: _textPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร",
                    style: TextStyle(color: _textSub, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 40),

                // Section label
                const _SectionLabel("Security"),
                const SizedBox(height: 16),

                // New password field
                _PasswordField(
                  controller: newPasswordController,
                  label: "New Password",
                  showPassword: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                ),
                const SizedBox(height: 16),

                // Confirm password field
                _PasswordField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  showPassword: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                ),

                const SizedBox(height: 48),

                // Save button
                _SaveButton(
                  isSaving: isLoading,
                  onPressed: isLoading ? null : changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _textSub,
          fontSize: 10,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String                 label;
  final bool                   showPassword;
  final VoidCallback           onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.showPassword,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      obscureText:  !showPassword,
      style: const TextStyle(color: _textPrim, fontSize: 15),
      cursorColor:  _accent,
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _accent, fontSize: 12),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: _textSub, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _textSub,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled:     true,
        fillColor:  _card,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool        isSaving;
  final VoidCallback? onPressed;
  const _SaveButton({required this.isSaving, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSaving
              ? const LinearGradient(colors: [_card, _card])
              : const LinearGradient(
                  colors: [Color(0xFF38BEFF), Color(0xFF1A8FD1)],
                ),
          boxShadow: isSaving
              ? []
              : [
                  BoxShadow(
                    color:      _accent.withOpacity(0.35),
                    blurRadius: 20,
                    offset:     const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ),
                )
              : const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color:        _bg,
                    fontSize:     13,
                    letterSpacing: 2,
                    fontWeight:   FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}