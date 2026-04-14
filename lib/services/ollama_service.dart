import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class OllamaService {
  static String baseUrl = 'http://localhost:11434';
  static String model = 'gemma3:1b';

  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/tags'),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        return models.map((m) => m['name'].toString()).toList();
      }
    } catch (e) {
      // Connection error
    }
    return [];
  }

  static Future<String> chat(String prompt, {List<Message>? history}) async {
    try {
      final messages = <Map<String, String>>[];

      messages.add({
        'role': 'system',
        'content': 'You are a helpful AI assistant. Be concise and helpful.',
      });

      if (history != null) {
        final recentHistory =
            history.length > 10 ? history.sublist(history.length - 10) : history;
        for (final msg in recentHistory) {
          messages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }

      messages.add({'role': 'user', 'content': prompt});

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
