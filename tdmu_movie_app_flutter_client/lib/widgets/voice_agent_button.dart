import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_agent_service.dart';

class VoiceAgentButton extends StatefulWidget {
  final Function(String action, Map<String, dynamic>? payload) onActionReceived;

  const VoiceAgentButton({Key? key, required this.onActionReceived}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("vi-VN");
  }

  void _listen() async {
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
      
      final replyText = response['text'];
      final action = response['action'];
      final payload = response['payload'];

      if (replyText != null && replyText.isNotEmpty) {
        await _flutterTts.speak(replyText);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(replyText), duration: const Duration(seconds: 4)),
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
