part of 'tool_bloc.dart';

abstract class ToolState {}

class ToolInitial extends ToolState {}

class ToolsLoaded extends ToolState {
  final List<ToolDefinition> tools;
  ToolsLoaded({required this.tools});
}

class ToolExecuting extends ToolState {
  final String toolName;
  ToolExecuting({required this.toolName});
}

class ToolExecuted extends ToolState {
  final ToolResult result;
  final String description;

  ToolExecuted({
    required this.result,
    required this.description,
  });
}

class ToolConfirmationRequired extends ToolState {
  final ToolCall toolCall;
  final ToolDefinition definition;

  ToolConfirmationRequired({
    required this.toolCall,
    required this.definition,
  });
}

class ToolError extends ToolState {
  final String error;
  ToolError({required this.error});
}
