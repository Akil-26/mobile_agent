import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/tools/tool_bloc.dart';
import '../widgets/index.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'tools_management_screen.dart';
import 'tools_test_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatBloc _chatBloc;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.initializeChat();
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatBloc.sendMessage(text);
    _controller.clear();
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
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh AI connection',
            onPressed: () {
              _chatBloc.refreshConnection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking AI status...')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'tools') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => ToolBloc()..loadAvailableTools(),
                      child: const ToolsManagementScreen(),
                    ),
                  ),
                );
              } else if (value == 'test_tools') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToolsTestScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => SettingsBloc()..initializeSettings(),
                      child: const SettingsScreen(),
                    ),
                  ),
                );
              } else if (value == 'clear') {
                _chatBloc.clearMessages();
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
                value: 'tools',
                child: Row(
                  children: [
                    Icon(Icons.build_outlined),
                    SizedBox(width: 12),
                    Text('Tools'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_tools',
                child: Row(
                  children: [
                    Icon(Icons.bug_report_outlined),
                    SizedBox(width: 12),
                    Text('Test Tools'),
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
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatToolConfirmationRequired) {
            showDialog(
              context: context,
              builder: (_) => ToolConfirmationDialog(
                toolCall: state.toolCall,
                definition: state.toolDefinition,
                onConfirm: () {
                  Navigator.pop(context);
                  _chatBloc.executeToolCall(state.toolCall);
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
            );
          } else if (state is ChatToolExecuted) {
            showDialog(
              context: context,
              builder: (_) => ToolExecutionDialog(
                result: state.result,
                onClose: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            bool isTyping = false;
            List messages = [];

            if (state is ChatInitialized) {
              messages = state.messages;
            } else if (state is ChatMessagesUpdated) {
              messages = state.messages;
              isTyping = state.isTyping;
            } else if (state is ChatToolExecuting) {
              isTyping = true;
            } else if (state is ChatToolExecuted) {
              messages = state.messages;
            }

            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const EmptyState()
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isTyping) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: messages[index]);
                    },
                  ),
                ),
                InputArea(
                  controller: _controller,
                  onSend: _sendMessage,
                  isTyping: isTyping,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
