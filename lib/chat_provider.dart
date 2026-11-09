import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatProvider extends ChangeNotifier {
  final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  
  StreamSubscription? _subscription;
  final FlutterTts _flutterTts = FlutterTts();

  final senseipromt = Content.system(
    "1. Role: คุณคือ '愛 Sensei' ผู้เชี่ยวชาญภาษาและวัฒนธรรมญี่ปุ่นสมัยใหม่\n"
    "2. Language: สื่อสารด้วยภาษาไทยวัยรุ่น สั้น กระชับ แม่นยำ 99% ห้ามใช้ Emoji เด็ดขาด\n"
    "3. Default Response: ตอบตรงประเด็นที่สุด ยกตัวอย่างแค่ 1 ประโยค (ห้ามอธิบายยาว ห้ามใช้เครื่องหมาย * ในการเน้นคำ)\n"
    "4. Pronunciation Rule: ห้ามเขียนคำอ่านด้วยอักษรภาษาอังกฤษ (Romaji) เด็ดขาด! ให้เขียนคำอ่านแบบภาษาไทยเสมอ\n"
    "5. Conditional Content: ถ้าผู้ใช้ถามถึงคันจิหรือวัฒนธรรม ค่อยอธิบายเพิ่ม\n"
    "6. Feedback Loop: ถ้าผู้ใช้พิมพ์ภาษาญี่ปุ่นมาผิด ให้แก้ให้ถูกต้อง"
  );

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _initializeAI();
    _initTTS();
  }

  void _initializeAI() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 1200, temperature: 0.7),
      systemInstruction: senseipromt,
    );
    _chat = _model.startChat();
  }

// เก็บโปรไฟล์เสียงผู้ชายที่หาเจอในเครื่อง
  Map<String, Map<String, String>> _maleVoices = {};

  Future<void> _initMaleVoices() async {
    // โหลดเสียงทั้งหมดที่มีในเครื่อง
    List<dynamic> voices = await _flutterTts.getVoices;
    
    Map<String, String>? findMale(String langCode) {
      try {
        final matched = voices.where((v) => v['locale'].toString().toLowerCase().startsWith(langCode)).toList();
        for (var v in matched) {
          final name = v['name'].toString().toLowerCase();
          final gender = v['gender']?.toString().toLowerCase() ?? '';
          
          // ดักจับ Key เสียงผู้ชายของทั้ง iOS (ชื่อคน) และ Android (มีคำว่า male)
          if (name.contains('male') || gender == 'male' || 
              name.contains('pattara') || // ชายไทย (iOS)
              name.contains('otoya') ||   // ชายญี่ปุ่น (iOS)
              name.contains('daniel') ||  // ชายอังกฤษ (iOS)
              name.contains('aaron')) {
            return {"name": v["name"].toString(), "locale": v["locale"].toString()};
          }
        }
        // ถ้าหาเสียงผู้ชายไม่เจอจริงๆ ให้ใช้เสียงแรกของภาษานั้นแทน
        if (matched.isNotEmpty) {
          return {"name": matched.first["name"].toString(), "locale": matched.first["locale"].toString()};
        }
      } catch (e) {
        debugPrint('หาเสียงไม่เจอ: $e');
      }
      return null;
    }

    // ค้นหาและเก็บใส่ Map ไว้ จะได้ไม่ต้องหาใหม่ทุกครั้งที่อ่าน (ช่วยลดดีเลย์ได้ส่วนนึง)
    final th = findMale("th"); if (th != null) _maleVoices["th"] = th;
    final en = findMale("en"); if (en != null) _maleVoices["en"] = en;
    final ja = findMale("ja"); if (ja != null) _maleVoices["ja"] = ja;
  }
  Future<void> _initTTS() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("th-TH");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  // 🗣️ ระบบอ่านออกเสียงสลับภาษา (อัปเกรด 3 ภาษา: ไทย, ญี่ปุ่น, อังกฤษ)
 // 🗣️ ระบบอ่านออกเสียงสลับภาษา (อัปเกรดตัดวงเล็บ อีโมจิ สัญลักษณ์พิเศษ)
  Future<void> speakSmart(String rawText) async {
    String cleanText = rawText
        .replaceAll(RegExp(r'\([^)]*\)|（[^）]*）'), '')
        .replaceAll(RegExp(r'[\u{1F000}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1FA00}-\u{1FAFF}\u{2B50}]', unicode: true), '')
        .replaceAll(RegExp(r'[~@#$%^&*_+=\[\]{}|<>/\\`"“”‘’]+'), '')
        .replaceAll('\n', '  ')
        .trim();

    if (cleanText.isEmpty) return;

    final RegExp langRegex = RegExp(r'([\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]+)|([a-zA-Z]+(?:[\s][a-zA-Z]+)*)');
    Iterable<RegExpMatch> matches = langRegex.allMatches(cleanText);
    int lastIndex = 0;
    
    for (final match in matches) {
      String thaiPart = cleanText.substring(lastIndex, match.start).trim();
      if (thaiPart.isNotEmpty) {
        await _speakWithMaleVoice(thaiPart, "th");
      }
      
      if (match.group(1) != null) {
        await _speakWithMaleVoice(match.group(1)!, "ja");
      } else if (match.group(2) != null) {
        await _speakWithMaleVoice(match.group(2)!, "en");
      }
      
      lastIndex = match.end;
    }
    
    String finalThaiPart = cleanText.substring(lastIndex).trim();
    if (finalThaiPart.isNotEmpty) {
      await _speakWithMaleVoice(finalThaiPart, "th");
    }
  }

  // ฟังก์ชันย่อยสำหรับเซ็ตเสียงผู้ชายแล้วค่อยพูด
  Future<void> _speakWithMaleVoice(String text, String langKey) async {
    if (_maleVoices.containsKey(langKey)) {
      await _flutterTts.setVoice(_maleVoices[langKey]!);
    } else {
      // Fallback เผื่อกรณีหาไม่เจอจริงๆ
      await _flutterTts.setLanguage(langKey == "th" ? "th-TH" : langKey == "ja" ? "ja-JP" : "en-US");
    }
    await _flutterTts.speak(text);
  }
  // 💬 คุยเล่นปกติ
  Future<void> sendMessage(String text, {required Function(String) onErrorAlert}) async {
    if (text.trim().isEmpty) return;
    _startMessageProcess(text);

    try {
      final stream = _chat.sendMessageStream(Content.text(text));
      _listenToStream(stream, onErrorAlert);
    } catch (e) {
      _handleError(e, onErrorAlert);
    }
  }

  // 📚 ดึงข้อมูล Supabase มาแนะนำฟิค (ดึงคอมเมนต์มาด้วย)
  Future<void> recommendFiction(String userQuery, {required Function(String) onErrorAlert}) async {
    if (userQuery.trim().isEmpty) return;
    _startMessageProcess(userQuery);

    try {
      final response = await Supabase.instance.client
          .from('novels')
          .select('title, synopsis, comments(username, text)') 
          .limit(10);
      
      String fictionContext = "รายชื่อฟิคและเสียงตอบรับจากผู้อ่านที่มีในระบบตอนนี้:\n";
      
      for (var fic in response) {
        fictionContext += "- ชื่อเรื่อง: ${fic['title']}\n  เรื่องย่อ: ${fic['synopsis']}\n";
        final comments = fic['comments'] as List<dynamic>? ?? [];
        if (comments.isNotEmpty) {
          fictionContext += "  💬 คอมเมนต์จากผู้อ่าน:\n";
          final sampleComments = comments.take(3); 
          for (var c in sampleComments) {
            final username = c['username'] ?? 'ไม่ระบุตัวตน';
            final text = c['text'] ?? '';
            fictionContext += "    - $username: $text\n";
          }
        } else {
          fictionContext += "  💬 คอมเมนต์จากผู้อ่าน: (ยังไม่มีคอมเมนต์)\n";
        }
        fictionContext += "\n";
      }

      // 👇 จุดที่ต้องแก้คือตรงนี้ครับ บังคับ AI ให้แยกแยะบริบท
      String finalPrompt = """
ข้อมูลฟิคอ้างอิง:
$fictionContext

คำถามจากผู้ใช้: $userQuery

คำสั่งพิเศษ: 
1. ให้ประเมินคำถามของผู้ใช้ก่อนว่าเป็นเรื่องอะไร:
   - กรณีที่ 1 (ถามหานิยาย): ถ้าผู้ใช้ให้แนะนำฟิค นิยาย หรือเนื้อเรื่อง ให้หาจาก 'ข้อมูลฟิคอ้างอิง' ด้านบนเท่านั้น ห้ามแต่งชื่อเรื่องเอง ถ้าไม่มีให้บอกตรงๆ (ยกคอมเมนต์มาป้ายยาได้)
   - กรณีที่ 2 (ถามภาษาญี่ปุ่น/ชวนคุยทั่วไป): ถ้าผู้ใช้ถามเรื่องภาษาญี่ปุ่น แปลภาษา หรือคุยเล่นทั่วไป ให้ตอบตามปกติในบทบาท '愛 Sensei' ทันที **โดยห้ามอ้างอิงถึงข้อมูลฟิค และห้ามพูดประโยคทำนองว่า "ในข้อมูลที่ให้มาไม่มี" เด็ดขาด**
""";

      final stream = _chat.sendMessageStream(Content.text(finalPrompt));
      _listenToStream(stream, onErrorAlert);
    } catch (e) {
      _handleError(e, onErrorAlert);
    }
  }

  void _startMessageProcess(String text) {
    _messages.add({'isUser': true, 'text': text});
    _messages.add({'isUser': false, 'text': ''});
    _isLoading = true;
    notifyListeners();
  }

  void _listenToStream(Stream<GenerateContentResponse> stream, Function(String) onErrorAlert) {
    _subscription = stream.listen(
      (response) {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex]['text'] += response.text ?? '';
        notifyListeners();
      }, 
      onDone: () {
        _isLoading = false;
        notifyListeners();
        final lastIndex = _messages.length - 1;
        speakSmart(_messages[lastIndex]['text']); 
      }, 
      onError: (e) => _handleError(e, onErrorAlert)
    );
  }

  void _handleError(Object e, Function(String) onErrorAlert) {
    final lastIndex = _messages.length - 1;
    if (!_messages[lastIndex]['isUser'] && _messages[lastIndex]['text'].toString().trim().isEmpty) {
      _messages.removeAt(lastIndex);
    }
    _isLoading = false;
    notifyListeners();

    String errorStr = e.toString().toLowerCase();
    if (errorStr.contains('429') || errorStr.contains('quota')) {
      onErrorAlert('โควต้า AI หมดชั่วคราวแล้ว! รอแป๊บนึงน้า');
    } else {
      onErrorAlert('เกิดข้อผิดพลาด: $e');
    }
  }

  void stopGenerating() {
    _subscription?.cancel();
    _flutterTts.stop();
    _isLoading = false;
    notifyListeners();
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
