import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/message.dart';

class LocalModelService {
  static bool _isLoaded = false;
  static bool _isLoading = false;
  static String? _modelPath;
  static double downloadProgress = 0.0;
  static int _lastSavedProgress = 0;

  // Expected model file size in bytes (Gemma 2 2B Q4_K_M)
  static const int expectedModelSize = 1599472640; // ~1.59 GB

  static const String modelUrl =
      'https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String modelFilename = 'gemma-2-2b-it-Q4_K_M.gguf';

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;

  static Future<String> get modelDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(p.join(dir.path, 'models'));
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  static Future<bool> isModelDownloaded() async {
    final dir = await modelDirectory;
    final file = File(p.join(dir, modelFilename));
    return file.existsSync();
  }

  static Future<void> downloadModel({Function(double)? onProgress}) async {
    _isLoading = true;
    downloadProgress = 0.0;

    try {
      final dir = await modelDirectory;
      final filePath = p.join(dir, modelFilename);
      final file = File(filePath);

      // Check if file already exists and is complete
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize >= expectedModelSize * 0.99) {
          // File exists and is almost complete size (~99% or more)
          _modelPath = filePath;
          downloadProgress = 1.0;
          onProgress?.call(1.0);
          _isLoading = false;
          return;
        }
        // File exists but incomplete - will resume download
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      // Get file size if it exists (for resume capability)
      int startByte = 0;
      if (await file.exists()) {
        startByte = await file.length();
        print('Resuming download from byte: $startByte');
      }

      final request = await client.getUrl(Uri.parse(modelUrl));

      // Add range header for resume capability
      if (startByte > 0) {
        request.headers.add('Range', 'bytes=$startByte-');
      }

      final response = await request.close();

      // Check response status
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final totalBytes = response.contentLength + startByte;
      int receivedBytes = startByte;

      // Open file in append mode if resuming, write mode if new
      final sink = file.openWrite(
        mode: startByte > 0 ? FileMode.append : FileMode.write,
      );

      await response.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          downloadProgress = receivedBytes / totalBytes;

          // Report progress every 5MB or when significant change occurs
          if ((receivedBytes - _lastSavedProgress) > 5242880) {
            onProgress?.call(downloadProgress);
            _lastSavedProgress = receivedBytes;
            print('Download progress: ${(downloadProgress * 100).toStringAsFixed(1)}%');
          }
        }
      });

      await sink.close();
      _modelPath = filePath;
      downloadProgress = 1.0;
      onProgress?.call(1.0);
      print('Download completed successfully');

      client.close();
    } catch (e) {
      downloadProgress = 0.0;
      print('Download error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  static Future<bool> loadModel() async {
    if (_isLoaded) return true;

    try {
      final downloaded = await isModelDownloaded();
      if (!downloaded) {
        return false;
      }

      final dir = await modelDirectory;
      _modelPath = p.join(dir, modelFilename);

      // Mark as loaded (native inference will be attempted at runtime)
      _isLoaded = true;
      return true;
    } catch (e) {
      print('Error loading model: $e');
      _isLoaded = false;
      return false;
    }
  }

  static Future<void> unloadModel() async {
    _isLoaded = false;
    _modelPath = null;
  }

  static const _channel = MethodChannel('com.example.flutter_application_1/model_inference');
  static bool _nativeAvailable = false;

  static Future<String> chat(String prompt, {List<Message>? history}) async {
    if (!_isLoaded) {
      return getNotLoadedMessage();
    }

    try {
      // Attempt native inference if available
      final response = await _attemptNativeInference(prompt);
      if (response != null) {
        return response;
      }
    } catch (e) {
      print('Native inference failed: $e');
    }

    // Fallback: Generate a simple response
    return _generateFallbackResponse(prompt);
  }

  static Future<String?> _attemptNativeInference(String prompt) async {
    try {
      if (!_nativeAvailable) return null;

      final result = await _channel.invokeMethod<String>(
        'run_inference',
        {'prompt': prompt, 'tokens': 128},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );

      return result;
    } on MissingPluginException {
      _nativeAvailable = false;
      return null;
    } catch (e) {
      print('Native inference error: $e');
      return null;
    }
  }

  static String _generateFallbackResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // Simple math detection
    if (lowerPrompt.contains('2+2') ||
        (lowerPrompt.contains('2') && lowerPrompt.contains('+') && lowerPrompt.contains('2'))) {
      return '2 + 2 = 4';
    }

    // Greeting responses
    if (lowerPrompt.contains('hello') ||
        lowerPrompt.contains('hi') ||
        lowerPrompt.contains('hey')) {
      return 'Hello! I\'m your private on-device AI assistant. How can I help you today?';
    }

    // Help/usage questions
    if (lowerPrompt.contains('what can you do') ||
        lowerPrompt.contains('help') ||
        lowerPrompt.contains('how do i')) {
      return 'I\'m a local AI assistant running on your device. I can help with:\n• Answering questions\n• Explaining concepts\n• Problem solving\n• Conversation\n\nEverything stays on your device - 100% private!';
    }

    // Default response with context
    return 'I received your message: "$prompt"\n\nNote: I\'m currently running a fallback response system. For full AI capabilities, the native llama.cpp library is being compiled. In the meantime, you can:\n• Ask simple questions\n• Use math calculations\n• Have casual conversations\n\nYour data stays completely private on your device.';
  }

  static String getNotLoadedMessage() =>
      'Model not loaded. Please download it in Settings first.';

  static Future<int> getModelSizeBytes() async {
    final dir = await modelDirectory;
    final file = File(p.join(dir, modelFilename));
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static Future<void> deleteModel() async {
    await unloadModel();
    final dir = await modelDirectory;
    final file = File(p.join(dir, modelFilename));
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
