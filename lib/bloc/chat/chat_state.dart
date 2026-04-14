part of 'chat_bloc.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatInitialized extends ChatState {
  final List<Message> messages;
  ChatInitialized({required this.messages});
}

class ChatMessagesUpdated extends ChatState {
  final List<Message> messages;
  final bool isTyping;
  ChatMessagesUpdated({
    required this.messages,
    this.isTyping = false,
  });
}

class ChatToolConfirmationRequired extends ChatState {
  final ToolCall toolCall;
  final ToolDefinition toolDefinition;
  final List<Message> messages;

  ChatToolConfirmationRequired({
    required this.toolCall,
    required this.toolDefinition,
    required this.messages,
  });
}

class ChatToolExecuting extends ChatState {
  final String toolName;
  ChatToolExecuting({required this.toolName});
}

class ChatToolExecuted extends ChatState {
  final ToolResult result;
  final List<Message> messages;

  ChatToolExecuted({
    required this.result,
    required this.messages,
  });
}

class ChatError extends ChatState {
  final String error;
  ChatError({required this.error});
}
