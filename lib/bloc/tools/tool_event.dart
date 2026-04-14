part of 'tool_bloc.dart';

abstract class ToolEvent {}

class LoadAvailableToolsEvent extends ToolEvent {}

class ExecuteToolCallEvent extends ToolEvent {
  final ToolCall toolCall;
  ExecuteToolCallEvent({required this.toolCall});
}

class RequestConfirmationEvent extends ToolEvent {
  final ToolCall toolCall;
  final ToolDefinition definition;

  RequestConfirmationEvent({
    required this.toolCall,
    required this.definition,
  });
}

class ConfirmExecutionEvent extends ToolEvent {
  final ToolCall toolCall;
  ConfirmExecutionEvent({required this.toolCall});
}

class ResetToolStateEvent extends ToolEvent {}
