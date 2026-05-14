import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../services/ai_agent_service.dart';
import '../services/auth_service.dart';
import '../screens/subscription_screen.dart';

class VoiceAgentButton extends StatefulWidget {
  final Function(String action, Map<String, dynamic>? payload) onActionReceived;
  final AuthSession session;

  const VoiceAgentButton({
    Key? key,
    required this.onActionReceived,
    required this.session,
  }) : super(key: key);

  @override
  _VoiceAgentButtonState createState() => _VoiceAgentButtonState();
}

class _VoiceAgentButtonState extends State<VoiceAgentButton> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = '';
  final AIAgentService _aiAgentService = AIAgentService();
  bool _isLoading = false;
  int _freeMessageCount = 0;
  static const int _freeMessageLimit = 2;
  static const String _countKey = 'ai_chat_free_count';
  static const String _resetTimeKey = 'ai_chat_reset_time';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("vi-VN");
    _loadMessageCount();
  }

  Future<void> _loadMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final resetTime = prefs.getInt(_resetTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Reset counter if 24 hours have passed
    if (now - resetTime >= 24 * 60 * 60 * 1000) {
      await prefs.setInt(_countKey, 0);
      await prefs.setInt(_resetTimeKey, now);
      setState(() => _freeMessageCount = 0);
    } else {
      setState(() => _freeMessageCount = prefs.getInt(_countKey) ?? 0);
    }
  }

  Future<void> _incrementMessageCount() async {
    _freeMessageCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, _freeMessageCount);

    // Set reset time on first message of this cycle
    final resetTime = prefs.getInt(_resetTimeKey) ?? 0;
    if (resetTime == 0) {
      await prefs.setInt(_resetTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  void _listen() async {
    // Check free message limit before starting
    if (!widget.session.user.isVip) {
      await _loadMessageCount(); // Refresh in case 24h passed
      if (_freeMessageCount >= _freeMessageLimit) {
        _showVipRequiredDialog();
        return;
      }
    }

    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
          localeId: 'vi_VN',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_text.isNotEmpty) {
        _processCommand(_text);
      }
    }
  }

  Future<void> _processCommand(String text) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _aiAgentService.sendChatMessage(text);
      
      // Increment counter for free users
      if (!widget.session.user.isVip) {
        await _incrementMessageCount();
      }

      final replyText = response['text'] as String?;
      final action = response['action'] as String?;
      final rawPayload = response['payload'];
      final Map<String, dynamic>? payload = rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : null;

      debugPrint('[VoiceAgent] action=$action, payload=$payload');

      if (replyText != null && replyText.isNotEmpty) {
        // Don't await TTS - let it speak in the background while we navigate
        _flutterTts.speak(replyText);

        final remaining = widget.session.user.isVip
            ? ''
            : ' (Còn ${_freeMessageLimit - _freeMessageCount}/$_freeMessageLimit lượt miễn phí)';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$replyText$remaining'),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (action != null && action != 'none') {
        widget.onActionReceived(action, payload);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _text = '';
      });
    }
  }

  void _showVipRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hết lượt miễn phí'),
          ],
        ),
        content: const Text(
          'Bạn đã sử dụng hết 5 lượt trò chuyện miễn phí với AI. '
          'Nâng cấp VIP để trò chuyện không giới hạn!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionScreen(
                    session: widget.session,
                    authService: AuthService(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: const Text('Nâng cấp VIP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _isLoading ? null : _listen,
      backgroundColor: _isListening ? Colors.red : Colors.blue,
      child: _isLoading 
        ? const CircularProgressIndicator(color: Colors.white)
        : Icon(_isListening ? Icons.mic : Icons.mic_none),
    );
  }
}
