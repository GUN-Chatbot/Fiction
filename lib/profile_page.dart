import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF080C14);
const _surface   = Color(0xFF0F1520);
const _card      = Color(0xFF141C2E);
const _accent    = Color(0xFF38BEFF);
const _accentSoft= Color(0x3338BEFF);
const _textPrim  = Color(0xFFE8F0FF);
const _textSub   = Color(0xFF6B7FA3);
const _divider   = Color(0xFF1E2A42);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase        = Supabase.instance.client;
  final nameController  = TextEditingController();
  final phoneController = TextEditingController();

  File?      _imageFile;
  Uint8List? _webImageBytes;
  String?    avatarUrl;
  bool       isLoading = true;
  bool       isSaving  = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    loadProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data != null) {
      nameController.text  = data['full_name'] ?? '';
      phoneController.text = data['phone']     ?? '';
      avatarUrl            = data['avatar_url'];
    }
    setState(() => isLoading = false);
    _animCtrl.forward();
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => _webImageBytes = bytes);
    } else {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> uploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      if (avatarUrl != null) {
        final oldPath = avatarUrl!.split('/avatars/')[1].split('?')[0];
        await supabase.storage.from('avatars').remove([oldPath]);
      }
      final fileName = "avatar_${DateTime.now().millisecondsSinceEpoch}.png";
      final path     = "${user.id}/$fileName";
      if (kIsWeb && _webImageBytes != null) {
        await supabase.storage.from('avatars').uploadBinary(
          path, _webImageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      }
      if (!kIsWeb && _imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        await supabase.storage.from('avatars').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(upsert: true),
        );
      }
      return supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // ✅ เช็คเบอร์โทร
    final phone = phoneController.text.trim();
    if (phone.isNotEmpty) {
      if (phone.length != 10 || !phone.startsWith('0')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
              SizedBox(width: 10),
              Text("เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 10 หลัก",
                  style: TextStyle(color: _textPrim)),
            ]),
            backgroundColor: _card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.redAccent),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() => isSaving = true);

    String? imageUrl;
    if (_imageFile != null || _webImageBytes != null) {
      imageUrl = await uploadImage();
    } else {
      imageUrl = avatarUrl;
    }

    await supabase.from('profiles').upsert({
      'id'        : user.id,
      'full_name' : nameController.text.trim(),
      'phone'     : phone,
      'avatar_url': imageUrl,
    });

    setState(() {
      avatarUrl      = imageUrl;
      _imageFile     = null;
      _webImageBytes = null;
      isSaving       = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: _accent, size: 18),
            SizedBox(width: 10),
            Text("บันทึกสำเร็จ", style: TextStyle(color: _textPrim)),
          ],
        ),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _accentSoft),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_accent),
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    ImageProvider? imageProvider;
    if (_imageFile != null)          imageProvider = FileImage(_imageFile!);
    else if (_webImageBytes != null) imageProvider = MemoryImage(_webImageBytes!);
    else if (avatarUrl != null)      imageProvider = NetworkImage(avatarUrl!);

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: _bg,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: _textSub, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        "PROFILE",
                        style: TextStyle(
                          color      : _textSub,
                          fontSize   : 11,
                          letterSpacing: 3,
                          fontWeight : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _AvatarHero(
                    imageProvider: imageProvider,
                    onTap: () => _showPickerSheet(),
                  ),
                ),
              ),

              // ── Form body ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      _SectionLabel("Personal details"),
                      const SizedBox(height: 16),

                      // Name field
                      _GoldTextField(
                        controller: nameController,
                        label: "Full Name",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Phone field ✅ เพิ่ม maxLength + inputFormatters
                      _GoldTextField(
                        controller    : phoneController,
                        label         : "Phone",
                        icon          : Icons.phone_outlined,
                        keyboardType  : TextInputType.phone,
                        maxLength     : 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      const SizedBox(height: 48),

                      _SaveButton(
                        isSaving : isSaving,
                        onPressed: isSaving ? null : saveProfile,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: Text(
                  "Change Photo",
                  style: TextStyle(
                    color: _textPrim, fontSize: 16,
                    fontWeight: FontWeight.w600, letterSpacing: 0.4,
                  ),
                ),
              ),
              const Divider(color: _divider, height: 1),
              if (!kIsWeb)
                _SheetTile(
                  icon : Icons.camera_alt_outlined,
                  label: "ถ่ายรูปด้วยกล้อง",
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.camera);
                  },
                ),
              _SheetTile(
                icon : Icons.photo_library_outlined,
                label: "เลือกจากแกลเลอรี่",
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AvatarHero extends StatelessWidget {
  final ImageProvider? imageProvider;
  final VoidCallback   onTap;
  const _AvatarHero({required this.imageProvider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [const Color(0xFF0C1628), _bg],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_accentSoft, Colors.transparent],
                radius: 0.7,
              ),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132, height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color      : _accent.withOpacity(0.25),
                        blurRadius : 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius         : 60,
                  backgroundColor: _surface,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.person_outline_rounded,
                          size: 44, color: _textSub)
                      : null,
                ),
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color     : _accent.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 13, color: _bg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color        : _textSub,
          fontSize     : 10,
          letterSpacing: 2.5,
          fontWeight   : FontWeight.w700,
        ),
      );
}

class _GoldTextField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final TextInputType?             keyboardType;
  final int?                       maxLength;
  final List<TextInputFormatter>?  inputFormatters;

  const _GoldTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller     : controller,
      keyboardType   : keyboardType,
      maxLength      : maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: _textPrim, fontSize: 15),
      cursorColor: _accent,
      // ซ่อน counter "0/10" ที่ขึ้นใต้ field
      buildCounter: maxLength != null
          ? (_, {required currentLength, required isFocused, maxLength}) => null
          : null,
      decoration: InputDecoration(
        labelText         : label,
        labelStyle        : const TextStyle(color: _textSub, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _accent, fontSize: 12),
        prefixIcon        : Icon(icon, color: _textSub, size: 20),
        filled            : true,
        fillColor         : _card,
        contentPadding    : const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide  : const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide  : const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool         isSaving;
  final VoidCallback? onPressed;
  const _SaveButton({required this.isSaving, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width : double.infinity,
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
                    color     : _accent.withOpacity(0.35),
                    blurRadius: 20,
                    offset    : const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor    : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor : AlwaysStoppedAnimation(_accent),
                  ),
                )
              : const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color        : _bg,
                    fontSize     : 13,
                    letterSpacing: 2,
                    fontWeight   : FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _SheetTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _accent, size: 22),
      title  : Text(label, style: const TextStyle(color: _textPrim, fontSize: 15)),
      onTap  : onTap,
    );
  }
}