/// Represents a system tool that the AI can call
class ToolDefinition {
  final String name;
  final String description;
  final String category; // communication, productivity, media, settings, info
  final Map<String, dynamic> schema; // JSON schema for arguments
  final bool requiresConfirmation;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.category,
    required this.schema,
    this.requiresConfirmation = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'schema': schema,
    'requires_confirmation': requiresConfirmation,
  };
}

/// Tool execution result
class ToolResult {
  final String toolName;
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  ToolResult({
    required this.toolName,
    required this.success,
    this.error,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'tool': toolName,
    'success': success,
    'error': error,
    'data': data,
  };
}

/// Tool call request from LLM
class ToolCall {
  final String tool;
  final Map<String, dynamic> args;

  ToolCall({
    required this.tool,
    required this.args,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
    tool: json['tool'] as String,
    args: (json['args'] as Map<String, dynamic>?) ?? {},
  );
}
