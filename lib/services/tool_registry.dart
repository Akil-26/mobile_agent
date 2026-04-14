import '../models/tool_definitions.dart';

class ToolRegistry {
  static final List<ToolDefinition> allTools = [
    // Communication Tools
    ToolDefinition(
      name: 'make_call',
      description: 'Make a phone call to a number',
      category: 'communication',
      requiresConfirmation: true,
      schema: {
        'phone_number': {'type': 'string', 'description': 'Phone number to call'},
        'direct': {
          'type': 'boolean',
          'description': 'Direct call or open dialer',
          'default': false,
        },
      },
    ),
    ToolDefinition(
      name: 'send_sms',
      description: 'Send an SMS message',
      category: 'communication',
      requiresConfirmation: true,
      schema: {
        'phone_number': {'type': 'string', 'description': 'Recipient phone number'},
        'message': {'type': 'string', 'description': 'Message content'},
      },
    ),
    ToolDefinition(
      name: 'share_text',
      description: 'Share text via apps',
      category: 'communication',
      schema: {
        'text': {'type': 'string', 'description': 'Text to share'},
        'package': {
          'type': 'string',
          'description': 'Target app package (optional)',
          'examples': ['com.whatsapp', 'com.telegram'],
        },
      },
    ),

    // Productivity Tools
    ToolDefinition(
      name: 'set_alarm',
      description: 'Set an alarm for specific time',
      category: 'productivity',
      schema: {
        'hour': {'type': 'integer', 'description': 'Hour (0-23)'},
        'minute': {'type': 'integer', 'description': 'Minute (0-59)'},
        'label': {'type': 'string', 'description': 'Alarm label'},
        'skip_ui': {'type': 'boolean', 'description': 'Skip UI', 'default': false},
      },
    ),
    ToolDefinition(
      name: 'set_timer',
      description: 'Set a timer for X seconds',
      category: 'productivity',
      schema: {
        'seconds': {'type': 'integer', 'description': 'Duration in seconds'},
        'label': {'type': 'string', 'description': 'Timer label'},
        'skip_ui': {'type': 'boolean', 'description': 'Skip UI', 'default': false},
      },
    ),

    // Media Tools
    ToolDefinition(
      name: 'open_camera',
      description: 'Open device camera',
      category: 'media',
      schema: {},
    ),
    ToolDefinition(
      name: 'open_app',
      description: 'Open an installed app',
      category: 'media',
      requiresConfirmation: false,
      schema: {
        'package': {
          'type': 'string',
          'description': 'App package name',
          'examples': ['com.whatsapp', 'com.google.android.youtube'],
        },
      },
    ),

    // Settings
    ToolDefinition(
      name: 'open_settings',
      description: 'Open device settings',
      category: 'settings',
      schema: {
        'target': {
          'type': 'string',
          'description': 'Settings target',
          'enum': ['wifi', 'bluetooth', 'sound', 'display', 'general'],
        },
      },
    ),

    // System Info
    ToolDefinition(
      name: 'get_battery_status',
      description: 'Get device battery information',
      category: 'info',
      schema: {},
    ),
    ToolDefinition(
      name: 'get_storage_info',
      description: 'Get device storage information',
      category: 'info',
      schema: {},
    ),
    ToolDefinition(
      name: 'get_network_status',
      description: 'Get device network status',
      category: 'info',
      schema: {},
    ),
  ];

  static ToolDefinition? getToolByName(String name) {
    try {
      return allTools.firstWhere((tool) => tool.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<ToolDefinition> getToolsByCategory(String category) {
    return allTools.where((tool) => tool.category == category).toList();
  }

  static List<ToolDefinition> getSafeTools() {
    // Tools that don't require confirmation
    return allTools.where((tool) => !tool.requiresConfirmation).toList();
  }

  static String generateSystemPrompt() {
    final toolsJson =
        allTools.map((t) => t.toJson()).toList();
    return '''You are an AI assistant that can control device functions.
When the user asks you to perform an action, you can use these tools by responding with valid JSON.

When you need to use a tool, respond ONLY with JSON in this format:
{
  "tool": "tool_name",
  "args": {
    "arg1": "value1",
    "arg2": "value2"
  }
}

Available tools:
${toolsJson.map((t) => '- ${t['name']}: ${t['description']}').join('\n')}

For normal conversation, just respond as usual. Only respond with tool JSON when explicitly requested.''';
  }
}
