import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     'https://mfrebebywfirzevxsqhg.supabase.co',
    anonKey: 'sb_publishable_sXkpTYMd1MT_nQ2XYdrqRQ_YqfYZ9lG',
  );
// kuy gun
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: const MaterialApp(
        home: SenseiChatScreen(), 
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class SenseiChatScreen extends StatefulWidget {
  const SenseiChatScreen({super.key});

  @override
  State<SenseiChatScreen> createState() => _SenseiChatScreenState();
}

class _SenseiChatScreenState extends State<SenseiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 🎨 กำหนดชุดสีให้ตรงกับธีมแอปของคุณ
  final Color _bgColor = const Color(0xFF0B101A);
  final Color _cardColor = const Color(0xFF1A2235);
  final Color _userBubbleColor = const Color(0xFF1E50B5);
  final Color _accentColor = const Color(0xFF3B82F6); 

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 💬 1. กดปุ่มส่งปกติ (คุยเล่นทั่วไป ไม่ดึง Database)
  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    
    context.read<ChatProvider>().sendMessage(
      text,
      onErrorAlert: (msg) => _showErrorPopup(msg),
    );
    
    _textController.clear();
  }

  // ✨ 2. กดปุ่มดาว (แนะนำฟิค ดึง Database)
  void _askForFiction() {
    String text = _textController.text.trim();
    // ถ้าผู้ใช้ไม่ได้พิมพ์อะไรมา แต่อยากให้แนะนำเลย ให้ใช้ข้อความ Default
    if (text.isEmpty) {
      text = "แนะนำฟิคน่าอ่านให้หน่อยครับ";
    }

    context.read<ChatProvider>().recommendFiction(
      text,
      onErrorAlert: (msg) => _showErrorPopup(msg),
    );
    
    _textController.clear();
  }

  // 💡 3. ฟังก์ชันสำหรับปุ่มเกร็ดความรู้
  void _askForTrivia() {
    _sendChatMessage("ขอเกร็ดความรู้ญี่ปุ่นสนุกๆ หรือวัฒนธรรมแปลกๆ 1 เรื่องครับ 🎌");
  }

  // 🇯🇵 4. ฟังก์ชันสำหรับปุ่มแปลชื่อ (พิมพ์รอไว้ให้ผู้ใช้เติมชื่อ)
  void _askForNameTranslation() {
    setState(() {
      _textController.text = "ช่วยแปลชื่อของฉันเป็นคาตากานะพร้อมคำอ่านให้หน่อย ฉันชื่อ: ";
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'พิมพ์ชื่อของคุณต่อท้ายได้เลย!', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // 👈 จัดให้อยู่ตรงกลางจะได้สวยๆ
        ),
        backgroundColor: Colors.pinkAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        
        // 👇 ทริคดัน SnackBar ขึ้นไปข้างบน (เอาความสูงจอตั้ง ลบด้วยระยะขอบบน)
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150, 
          left: 24,
          right: 24,
        ),
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showErrorPopup(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('แจ้งเตือน!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(errorMessage, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('รับทราบ', style: TextStyle(fontSize: 16, color: _accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    _scrollToBottom();

    return Scaffold(
      backgroundColor: _bgColor, 
      appBar: AppBar(
        title: const Text('愛 Sensei🎌', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _bgColor, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                final isUser = message['isUser'] as bool;
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? _userBubbleColor : _cardColor, 
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isUser ? const Radius.circular(0) : null,
                            bottomLeft: !isUser ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          message['text'] as String,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (!isUser && message['text'].toString().isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            chatProvider.copyToClipboard(message['text'] as String);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('คัดลอกข้อความแล้ว!', style: TextStyle(color: Colors.white)),
                                backgroundColor: _accentColor,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 12),
                            child: Icon(Icons.copy, size: 16, color: Colors.white54),
                          ),
                        ),
                      if (isUser) const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
          if (chatProvider.isLoading) 
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => context.read<ChatProvider>().stopGenerating(),
                icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                label: const Text('หยุดเซนเซย์!', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15), 
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final isLoading = context.watch<ChatProvider>().isLoading;
    
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      color: _bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 แถบปุ่มลัด 3 ปุ่ม (เลื่อนซ้ายขวาได้)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // ปุ่ม 1: แนะนำฟิค (สีเหลือง/ทอง)
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                  label: const Text(
                    'แนะนำฟิค', 
                    style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                  backgroundColor: _cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.amber.withOpacity(0.4), width: 1.2),
                  ),
                  onPressed: isLoading ? null : _askForFiction,
                ),
                const SizedBox(width: 8),
                
                // ปุ่ม 2: เกร็ดความรู้ญี่ปุ่น (สีเขียว/มิ้นต์)
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.tealAccent),
                  label: const Text(
                    'เกร็ดความรู้', 
                    style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                  backgroundColor: _cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.tealAccent.withOpacity(0.4), width: 1.2),
                  ),
                  onPressed: isLoading ? null : _askForTrivia,
                ),
                const SizedBox(width: 8),

                // ปุ่ม 3: แปลชื่อเป็นญี่ปุ่น (สีชมพู)
                ActionChip(
                  avatar: const Icon(Icons.translate_rounded, size: 16, color: Colors.pinkAccent),
                  label: const Text(
                    'แปลชื่อเป็นญี่ปุ่น', 
                    style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                  backgroundColor: _cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.pinkAccent.withOpacity(0.4), width: 1.2),
                  ),
                  onPressed: isLoading ? null : _askForNameTranslation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // 💬 แถบพิมพ์ข้อความปกติ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !isLoading, 
                    style: const TextStyle(color: Colors.white), 
                    decoration: InputDecoration(
                      hintText: isLoading ? 'เซนเซย์กำลังคิด...' : 'ถามเซนเซย์...',
                      hintStyle: const TextStyle(color: Colors.white54), 
                      filled: true,
                      fillColor: _cardColor, 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, 
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (text) {
                      if (!isLoading) _sendChatMessage(text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.transparent : _accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: isLoading ? Colors.white30 : _accentColor),
                    tooltip: 'ส่งข้อความ',
                    onPressed: isLoading ? null : () => _sendChatMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}