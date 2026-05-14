import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIAgentService {
  String get _baseUrl {
    const envUrl = String.fromEnvironment('AGENT_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return '$envUrl/agent/chat';

    if (kIsWeb) {
      return 'http://127.0.0.1:3000/agent/chat';
    }
    return 'http://10.0.2.2:3000/agent/chat';
  }
  List<Map<String, String>> _history = [];

  Future<Map<String, dynamic>> sendChatMessage(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    // Add current message to history
    _history.add({'role': 'user', 'content': text});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'text': text,
          'history': _history,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Add AI response to history
        _history.add({'role': 'ai', 'content': data['text'] ?? ''});

        // Keep only last 5 messages
        if (_history.length > 5) {
          _history = _history.sublist(_history.length - 5);
        }

        return data;
      } else {
        throw Exception('Failed to connect to AI Agent');
      }
    } catch (e) {
      // Remove the last message from history on failure
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
      throw Exception('Error: $e');
    }
  }

  void clearHistory() {
    _history.clear();
  }
}
