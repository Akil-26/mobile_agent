import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:llama_cpp_dart/llama_cpp_dart.dart' hide Message;
import '../models/message.dart';

/// Handles downloading the GGUF model file and running real on-device
/// inference via llama_cpp_dart (llama.cpp bindings).
///
/// NOTE: this requires a compiled libllama.so (Android arm64-v8a) /
/// libllama.dylib (macOS) / libllama.so (Linux) to be present at
/// [nativeLibraryPath]. Run `build-llama-android.sh` (or the equivalent for
/// your platform) before this will produce real responses instead of
/// throwing a clear "library not found" error.
class LocalModelService {
  static bool _isLoaded = false;
  static bool _isLoading = false;
  static String? _modelPath;
  static double downloadProgress = 0.0;
  static int _lastSavedProgress = 0;
  static LlamaParent? _llama;

  // Qwen2.5-1.5B-Instruct, Q4_K_M quantization — small enough to run
  // smoothly on a mid-range phone (~1GB) while still being a genuinely
  // useful instruction-following model.
  static const int expectedModelSize = 1117320397; // 1.12 GB, verified against HF repo listing

  static const String modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf';
  static const String modelFilename = 'qwen2.5-1.5b-instruct-q4_k_m.gguf';

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;

  /// Path to the native llama.cpp shared library. Override this if you
  /// place the compiled library somewhere else. On Android, llama_cpp_dart
  /// loads native libs from the standard jniLibs location automatically
  /// once bundled in android/app/src/main/jniLibs/[abi]/libllama.so, so on
  /// Android you usually don't need to set this manually — it's here for
  /// desktop testing (macOS/Linux) where you load from an explicit path.
  static String? nativeLibraryPath;

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

      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize >= expectedModelSize * 0.99) {
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

      int startByte = 0;
      if (await file.exists()) {
        startByte = await file.length();
      }

      final request = await client.getUrl(Uri.parse(modelUrl));
      if (startByte > 0) {
        request.headers.add('Range', 'bytes=$startByte-');
      }

      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final totalBytes = response.contentLength + startByte;
      int receivedBytes = startByte;

      final sink = file.openWrite(
        mode: startByte > 0 ? FileMode.append : FileMode.write,
      );

      await response.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          downloadProgress = receivedBytes / totalBytes;
          if ((receivedBytes - _lastSavedProgress) > 5242880) {
            onProgress?.call(downloadProgress);
            _lastSavedProgress = receivedBytes;
          }
        }
      });

      await sink.close();
      _modelPath = filePath;
      downloadProgress = 1.0;
      onProgress?.call(1.0);

      client.close();
    } catch (e) {
      downloadProgress = 0.0;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Loads the model into a managed isolate via llama_cpp_dart. Returns
  /// false (and leaves isLoaded == false) if the model file isn't
  /// downloaded yet, or if the native library can't be found/loaded — in
  /// the latter case the thrown error is logged so the cause is visible
  /// instead of silently falling back to fake responses.
  static Future<bool> loadModel() async {
    if (_isLoaded) return true;

    try {
      final downloaded = await isModelDownloaded();
      if (!downloaded) {
        return false;
      }

      final dir = await modelDirectory;
      _modelPath = p.join(dir, modelFilename);

      if (nativeLibraryPath != null) {
        Llama.libraryPath = nativeLibraryPath!;
      }

      final loadCommand = LlamaLoad(
        path: _modelPath!,
        modelParams: ModelParams(),
        contextParams: ContextParams(),
        samplingParams: SamplerParams()
          ..temp = 0.7
          ..topP = 0.9,
      );

      // Qwen2.5 models use the ChatML prompt format; pass formatter to LlamaParent.
      _llama = LlamaParent(loadCommand, ChatMLFormat());
      await _llama!.init();

      _isLoaded = true;
      return true;
    } catch (e) {
      // Surface the real error (e.g. missing libllama.so) instead of
      // silently pretending the model loaded.
      // ignore: avoid_print
      print('LocalModelService: failed to load model — $e');
      _isLoaded = false;
      _llama = null;
      return false;
    }
  }

  static Future<void> unloadModel() async {
    await _llama?.dispose();
    _llama = null;
    _isLoaded = false;
    _modelPath = null;
  }

  /// Runs real inference and returns the full response. For a streaming
  /// UI, prefer [chatStream] instead so the user sees tokens as they're
  /// generated rather than waiting for the whole reply.
  static Future<String> chat(String prompt, {List<Message>? history}) async {
    if (!_isLoaded || _llama == null) {
      return getNotLoadedMessage();
    }

    final buffer = StringBuffer();
    final completer = Completer<String>();
    late final StreamSubscription<String> sub;

    sub = _llama!.stream.listen(
      (token) => buffer.write(token),
      onDone: () {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(buffer.toString());
      },
      onError: (e) {
        sub.cancel();
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    await _llama!.sendPrompt(_buildPrompt(prompt, history));

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        sub.cancel();
        return buffer.isNotEmpty
            ? buffer.toString()
            : 'The model took too long to respond. Try a shorter message.';
      },
    );
  }

  /// Streaming variant — emits tokens as they're generated. Use this from
  /// the chat UI for a responsive, ChatGPT-style typing effect.
  static Stream<String> chatStream(String prompt, {List<Message>? history}) {
    if (!_isLoaded || _llama == null) {
      return Stream.value(getNotLoadedMessage());
    }
    _llama!.sendPrompt(_buildPrompt(prompt, history));
    return _llama!.stream;
  }

  static String _buildPrompt(String prompt, List<Message>? history) {
    // ChatMLFormat handles the special tokens; we just need to hand it
    // plain text. Keep the last few turns for short-term context without
    // blowing past the context window on a 1.5B model.
    if (history == null || history.isEmpty) return prompt;
    final recent = history.length > 6
        ? history.sublist(history.length - 6)
        : history;
    final context = recent
        .map((m) => '${m.isUser ? "User" : "Assistant"}: ${m.content}')
        .join('\n');
    return '$context\nUser: $prompt';
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
}
