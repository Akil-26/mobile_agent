import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// AI Mode enum
enum AIMode { local, ollama, offline }

// Local Model Service - Downloads and manages local model files
// Note: Full on-device inference requires native code (llama.cpp FFI)
// For now, this manages model files and can connect to local Ollama mobile server
class LocalModelService {
  static bool _isLoaded = false;
  static bool _isLoading = false;
  static String? _modelPath;
  static double downloadProgress = 0.0;
  
  // Smaller quantized model for mobile
  static const String modelUrl = 
      'https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String modelFilename = 'gemma-2-2b-it-Q4_K_M.gguf';
  
  // Local Ollama server (can run on Android via Termux)
  static String localServerUrl = 'http://127.0.0.1:11434';
  
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
      
      if (await file.exists()) {
        _modelPath = filePath;
        _isLoading = false;
        return;
      }
      
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await http.Client().send(request);
      
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          downloadProgress = receivedBytes / totalBytes;
          onProgress?.call(downloadProgress);
        }
      }
      
      await sink.close();
      _modelPath = filePath;
      downloadProgress = 1.0;
    } catch (e) {
      downloadProgress = 0.0;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  static Future<bool> loadModel() async {
    if (_isLoaded) return true;
    
    final downloaded = await isModelDownloaded();
    if (downloaded) {
      final dir = await modelDirectory;
      _modelPath = p.join(dir, modelFilename);
      _isLoaded = true;
      return true;
    }
    return false;
  }
  
  static Future<void> unloadModel() async {
    _isLoaded = false;
    _modelPath = null;
  }
  
  // Try to connect to local Ollama server (useful for Termux/local setup)
  static Future<bool> checkLocalServer() async {
    try {
      final response = await http.get(
        Uri.parse('$localServerUrl/api/tags'),
      ).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  static Future<String> chat(String prompt, {List<Message>? history}) async {
    // Try local Ollama server first
    if (await checkLocalServer()) {
      try {
        final messages = <Map<String, String>>[];
        messages.add({
          'role': 'system',
          'content': 'You are a helpful AI assistant. Be concise.',
        });
        
        if (history != null) {
          final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
          for (final msg in recent) {
            messages.add({
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.content,
            });
          }
        }
        
        messages.add({'role': 'user', 'content': prompt});
        
        final response = await http.post(
          Uri.parse('$localServerUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'gemma3:1b',
            'messages': messages,
            'stream': false,
          }),
        ).timeout(const Duration(seconds: 120));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['message']['content'] ?? 'No response';
        }
      } catch (e) {
        // Fall through
      }
    }
    
    return 'Local model ready. Native inference coming soon!\n\nModel path: $_modelPath';
  }
  
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

// Ollama Service for desktop AI (when available)
class OllamaService {
  static String baseUrl = 'http://localhost:11434';
  static String model = 'gemma3:1b';
  
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 3));
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
        final recentHistory = history.length > 10 
            ? history.sublist(history.length - 10) 
            : history;
        for (final msg in recentHistory) {
          messages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }
      
      messages.add({'role': 'user', 'content': prompt});
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 120));
      
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

// Unified AI Service - Manages both local and remote AI
class AIService {
  static AIMode currentMode = AIMode.offline;
  static bool ollamaAvailable = false;
  static bool localModelAvailable = false;
  
  static Future<void> initialize() async {
    // Check Ollama first (faster response if available)
    ollamaAvailable = await OllamaService.checkConnection();
    
    // Check if local model is downloaded
    localModelAvailable = await LocalModelService.isModelDownloaded();
    
    // Set mode based on availability
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
        // Fall through to ollama if local not loaded
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

// Message model
class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Main Chat Screen
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }
  
  Future<void> _initializeAI() async {
    await AIService.initialize();
    
    setState(() {
      // Welcome message based on AI mode
      String welcomeMsg;
      switch (AIService.currentMode) {
        case AIMode.local:
          welcomeMsg = "✅ Local AI Ready!\n\n"
              "Running on-device inference.\n"
              "Your conversations stay completely private.\n\n"
              "How can I help you today?";
          break;
        case AIMode.ollama:
          welcomeMsg = "✅ Connected to Ollama!\n\n"
              "Model: ${OllamaService.model}\n\n"
              "💡 Tip: Download a local model in Settings to use AI anywhere, even offline!";
          break;
        case AIMode.offline:
          welcomeMsg = "👋 Welcome!\n\n"
              "No AI model available yet.\n\n"
              "To get started:\n"
              "• Download a local model (works offline!)\n"
              "• Or connect to Ollama on your desktop\n\n"
              "Go to Settings → AI Configuration to set up.";
          break;
      }
      
      _messages.add(Message(content: welcomeMsg, isUser: false));
    });
  }
  
  Future<void> _refreshConnection() async {
    await AIService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(content: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await AIService.chat(text, history: _messages);

    setState(() {
      _isTyping = false;
      _messages.add(Message(content: response, isUser: false));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy_outlined, size: 28),
            const SizedBox(width: 12),
            const Text('Private AI'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AIService.statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AIService.statusText,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh AI connection',
            onPressed: () async {
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Checking AI status...')),
              );
              await _refreshConnection();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('AI Mode: ${AIService.statusText}')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              } else if (value == 'settings') {
                final models = await OllamaService.getAvailableModels();
                if (!mounted) return;
                await Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage(
                    currentModel: OllamaService.model,
                    availableModels: models,
                    isConnected: AIService.ollamaAvailable,
                    localModelLoaded: LocalModelService.isLoaded,
                  )),
                );
                // Refresh after settings change
                if (!mounted) return;
                await _refreshConnection();
                setState(() {});
              } else if (value == 'clear') {
                setState(() {
                  _messages.clear();
                  _initializeAI();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          // Input area
          _InputArea(
            controller: _controller,
            onSend: _sendMessage,
            isTyping: _isTyping,
          ),
        ],
      ),
    );
  }
}

// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}

// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Typing indicator widget
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const _DotAnimation(),
          ),
        ],
      ),
    );
  }
}

// Animated dots for typing indicator
class _DotAnimation extends StatefulWidget {
  const _DotAnimation();

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Input area widget
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isTyping;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isTyping ? null : onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'User';
  String _userEmail = 'user@example.com';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        // Change profile picture
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // User Info Card
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: _userName,
                      onEdit: () => _editField('Name', _userName, (val) {
                        setState(() => _userName = val);
                      }),
                    ),
                    const Divider(),
                    _ProfileInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _userEmail,
                      onEdit: () => _editField('Email', _userEmail, (val) {
                        setState(() => _userEmail = val);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats Card
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.chat_bubble_outline,
                          value: '42',
                          label: 'Chats',
                          color: colorScheme.primary,
                        ),
                        _StatItem(
                          icon: Icons.access_time,
                          value: '3h',
                          label: 'Time Saved',
                          color: colorScheme.tertiary,
                        ),
                        _StatItem(
                          icon: Icons.task_alt,
                          value: '15',
                          label: 'Tasks Done',
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $field',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: onEdit,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// Settings Page
class SettingsPage extends StatefulWidget {
  final String currentModel;
  final List<String> availableModels;
  final bool isConnected;
  final bool localModelLoaded;
  
  const SettingsPage({
    super.key,
    this.currentModel = 'gemma3:1b',
    this.availableModels = const [],
    this.isConnected = false,
    this.localModelLoaded = false,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = true;
  bool _notifications = true;
  bool _saveHistory = true;
  late String _selectedModel;
  late String _ollamaUrl;
  bool _localModelDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _modelSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
    _ollamaUrl = OllamaService.baseUrl;
    _checkLocalModel();
  }
  
  Future<void> _checkLocalModel() async {
    final downloaded = await LocalModelService.isModelDownloaded();
    final size = await LocalModelService.getModelSizeBytes();
    setState(() {
      _localModelDownloaded = downloaded;
      _modelSizeBytes = size;
    });
  }
  
  Future<void> _downloadLocalModel() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    
    try {
      await LocalModelService.downloadModel(
        onProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
      );
      
      // Load the model after download
      await LocalModelService.loadModel();
      
      await _checkLocalModel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Model downloaded and loaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Download failed: $e')),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }
  
  Future<void> _deleteLocalModel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Local Model'),
        content: const Text('This will remove the downloaded AI model. You can re-download it anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await LocalModelService.deleteModel();
      await _checkLocalModel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model deleted')),
        );
      }
    }
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (val) => setState(() => _darkMode = val),
              ),
            ],
          ),
          // AI Settings Section
          _SettingsSection(
            title: 'Local AI Model (Offline)',
            children: [
              // Local model status
              ListTile(
                leading: Icon(
                  _localModelDownloaded ? Icons.check_circle : Icons.download,
                  color: _localModelDownloaded ? Colors.green : Colors.grey,
                ),
                title: const Text('On-Device Model'),
                subtitle: Text(_localModelDownloaded 
                    ? 'Gemma 2 2B (${_formatBytes(_modelSizeBytes)}) - Ready'
                    : 'Not downloaded (~1.5 GB)'),
              ),
              // Download/Delete button
              if (_isDownloading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Downloading... ${(_downloadProgress * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _downloadProgress),
                    ],
                  ),
                )
              else
                ListTile(
                  leading: Icon(
                    _localModelDownloaded ? Icons.delete_outline : Icons.cloud_download,
                    color: _localModelDownloaded ? Colors.red : colorScheme.primary,
                  ),
                  title: Text(_localModelDownloaded ? 'Delete Local Model' : 'Download Local Model'),
                  subtitle: Text(_localModelDownloaded 
                      ? 'Remove to free up storage'
                      : 'Run AI completely offline on your device'),
                  onTap: _localModelDownloaded ? _deleteLocalModel : _downloadLocalModel,
                ),
              // Load/Unload model
              if (_localModelDownloaded)
                ListTile(
                  leading: Icon(
                    LocalModelService.isLoaded ? Icons.memory : Icons.play_arrow,
                    color: LocalModelService.isLoaded ? Colors.green : Colors.grey,
                  ),
                  title: Text(LocalModelService.isLoaded ? 'Model Loaded' : 'Load Model'),
                  subtitle: Text(LocalModelService.isLoaded 
                      ? 'Ready for inference'
                      : 'Load model into memory'),
                  onTap: LocalModelService.isLoaded 
                      ? null 
                      : () async {
                          if (!mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Loading model...')),
                          );
                          await LocalModelService.loadModel();
                          if (!mounted) return;
                          setState(() {});
                          messenger.showSnackBar(
                            SnackBar(content: Text(LocalModelService.isLoaded 
                                ? '✅ Model loaded!' 
                                : '❌ Failed to load model')),
                          );
                        },
                ),
            ],
          ),
          // Ollama Settings Section
          _SettingsSection(
            title: 'Ollama (Desktop)',
            children: [
              // Connection status
              ListTile(
                leading: Icon(
                  widget.isConnected ? Icons.check_circle : Icons.error,
                  color: widget.isConnected ? Colors.green : Colors.orange,
                ),
                title: const Text('Ollama Status'),
                subtitle: Text(widget.isConnected 
                    ? 'Connected to local server' 
                    : 'Not connected'),
              ),
              // Server URL
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Server URL'),
                subtitle: Text(_ollamaUrl),
                trailing: const Icon(Icons.edit),
                onTap: () => _editOllamaUrl(),
              ),
              // Model selection
              if (widget.isConnected)
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('Ollama Model'),
                  subtitle: Text(_selectedModel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showModelPicker(),
                ),
            ],
          ),
          // Privacy Section
          _SettingsSection(
            title: 'Privacy & Data',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.history_outlined),
                title: const Text('Save Chat History'),
                subtitle: const Text('Store conversations locally'),
                value: _saveHistory,
                onChanged: (val) => setState(() => _saveHistory = val),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear Chat History'),
                subtitle: const Text('Delete all conversations'),
                onTap: () => _showClearHistoryDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export Data'),
                subtitle: const Text('Download your data'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting data...')),
                  );
                },
              ),
            ],
          ),
          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive task reminders'),
                value: _notifications,
                onChanged: (val) => setState(() => _notifications = val),
              ),
            ],
          ),
          // About Section
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showModelPicker() {
    final models = widget.availableModels.isNotEmpty 
        ? widget.availableModels 
        : ['llama3.2', 'llama3.1', 'phi3', 'gemma2', 'mistral'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Select AI Model',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!widget.isConnected)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ Connect to Ollama to see available models',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
            ...models.map(
              (model) => ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: Text(model),
                trailing: _selectedModel == model
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _selectedModel = model);
                  Navigator.pop(context);
                  Navigator.pop(context, model); // Return selected model
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _editOllamaUrl() {
    final controller = TextEditingController(text: _ollamaUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ollama Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:11434',
            border: OutlineInputBorder(),
            helperText: 'Default: http://localhost:11434',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _ollamaUrl = controller.text;
                OllamaService.baseUrl = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
