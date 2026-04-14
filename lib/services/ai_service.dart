import 'package:flutter/material.dart';
import '../models/ai_mode.dart';
import '../models/message.dart';
import 'local_model_service.dart';
import 'ollama_service.dart';

class AIService {
  static AIMode currentMode = AIMode.offline;
  static bool ollamaAvailable = false;
  static bool localModelAvailable = false;

  static Future<void> initialize() async {
    ollamaAvailable = await OllamaService.checkConnection();
    localModelAvailable = await LocalModelService.isModelDownloaded();

    if (localModelAvailable) {
      currentMode = AIMode.local;
      await LocalModelService.loadModel();
    } else if (ollamaAvailable) {
      currentMode = AIMode.ollama;
    } else {
      currentMode = AIMode.offline;
    }
  }

  static Future<String> chat(String prompt, {List<Message>? history}) async {
    switch (currentMode) {
      case AIMode.local:
        if (LocalModelService.isLoaded) {
          return LocalModelService.chat(prompt, history: history);
        }
        if (ollamaAvailable) {
          return OllamaService.chat(prompt, history: history);
        }
        return 'Model not loaded. Please wait or download the model.';

      case AIMode.ollama:
        return OllamaService.chat(prompt, history: history);

      case AIMode.offline:
        return 'AI is offline. Download a local model or connect to Ollama.';
    }
  }

  static String get statusText {
    switch (currentMode) {
      case AIMode.local:
        return 'Local AI';
      case AIMode.ollama:
        return 'Ollama';
      case AIMode.offline:
        return 'Offline';
    }
  }

  static Color get statusColor {
    switch (currentMode) {
      case AIMode.local:
        return Colors.green;
      case AIMode.ollama:
        return Colors.blue;
      case AIMode.offline:
        return Colors.orange;
    }
  }
}
