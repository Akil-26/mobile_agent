import 'package:bloc/bloc.dart';
import '../../models/ai_mode.dart';
import '../../models/message.dart';
import '../../services/ai_service.dart';
import '../../services/ollama_service.dart';
import '../../services/tools_service.dart';
import '../../services/tool_registry.dart';
import '../../models/tool_definitions.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Cubit<ChatState> {
  ChatBloc() : super(ChatInitial());

  final List<Message> _messages = [];
  final List<ToolResult> _toolResults = [];

  Future<void> initializeChat() async {
    try {
      emit(ChatLoading());
      await AIService.initialize();

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

      final welcome = Message(content: welcomeMsg, isUser: false);
      _messages.add(welcome);
      emit(ChatInitialized(messages: List.from(_messages)));
    } catch (e) {
      emit(ChatError(error: e.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    try {
      _messages.add(Message(content: text, isUser: true));
      emit(ChatMessagesUpdated(messages: List.from(_messages), isTyping: true));

      final response = await AIService.chat(text, history: _messages);

      // Check if response contains a tool call
      final toolCall = ToolsService.extractToolCall(response);

      if (toolCall != null) {
        final toolDef = ToolRegistry.getToolByName(toolCall.tool);
        if (toolDef != null) {
          // Emit state for tool confirmation if needed
          if (toolDef.requiresConfirmation) {
            emit(ChatToolConfirmationRequired(
              toolCall: toolCall,
              toolDefinition: toolDef,
              messages: List.from(_messages),
            ));
            return;
          } else {
            // Execute immediately for non-confirmation tools
            await executeToolCall(toolCall);
            return;
          }
        }
      }

      _messages.add(Message(content: response, isUser: false));
      emit(ChatMessagesUpdated(messages: List.from(_messages), isTyping: false));
    } catch (e) {
      emit(ChatError(error: e.toString()));
    }
  }

  Future<void> executeToolCall(ToolCall toolCall) async {
    try {
      emit(ChatToolExecuting(toolName: toolCall.tool));

      final result = await ToolsService.executeTool(toolCall);
      _toolResults.add(result);

      // Add tool result to messages
      final resultMsg = ToolsService.describeToolResult(result);
      _messages.add(Message(
        content: 'Tool Result: $resultMsg',
        isUser: false,
      ));

      emit(ChatToolExecuted(
        result: result,
        messages: List.from(_messages),
      ));
    } catch (e) {
      emit(ChatError(error: e.toString()));
    }
  }

  Future<void> refreshConnection() async {
    try {
      await AIService.initialize();
      emit(ChatInitialized(messages: List.from(_messages)));
    } catch (e) {
      emit(ChatError(error: e.toString()));
    }
  }

  void clearMessages() {
    _messages.clear();
    initializeChat();
  }

  List<Message> get messages => List.unmodifiable(_messages);
}

// Import AIMode and OllamaService for welcome message
