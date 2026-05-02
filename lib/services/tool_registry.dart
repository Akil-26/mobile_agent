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
        'phoneNumber': {'type': 'string', 'description': 'Phone number to call'},
      },
    ),
    ToolDefinition(
      name: 'send_sms',
      description: 'Send an SMS message',
      category: 'communication',
      requiresConfirmation: true,
      schema: {
        'phoneNumber': {'type': 'string', 'description': 'Recipient phone number'},
        'message': {'type': 'string', 'description': 'Message content'},
      },
    ),
    ToolDefinition(
      name: 'send_email',
      description: 'Send an email (opens email client)',
      category: 'communication',
      requiresConfirmation: false,
      schema: {
        'recipient': {'type': 'string', 'description': 'Email recipient'},
        'subject': {'type': 'string', 'description': 'Email subject (optional)'},
        'body': {'type': 'string', 'description': 'Email body (optional)'},
      },
    ),

    // File Operations
    ToolDefinition(
      name: 'read_file',
      description: 'Read contents of a file',
      category: 'files',
      requiresConfirmation: false,
      schema: {
        'path': {'type': 'string', 'description': 'File path to read'},
      },
    ),
    ToolDefinition(
      name: 'write_file',
      description: 'Write content to a file',
      category: 'files',
      requiresConfirmation: true,
      schema: {
        'path': {'type': 'string', 'description': 'File path to write to'},
        'content': {'type': 'string', 'description': 'Content to write'},
      },
    ),
    ToolDefinition(
      name: 'delete_file',
      description: 'Delete a file',
      category: 'files',
      requiresConfirmation: true,
      schema: {
        'path': {'type': 'string', 'description': 'File path to delete'},
      },
    ),
    ToolDefinition(
      name: 'list_files',
      description: 'List files in a directory',
      category: 'files',
      requiresConfirmation: false,
      schema: {
        'directory': {
          'type': 'string',
          'description': 'Directory path (optional, defaults to app files directory)',
        },
      },
    ),

    // Device Information
    ToolDefinition(
      name: 'get_device_info',
      description: 'Get device information',
      category: 'info',
      schema: {},
    ),
    ToolDefinition(
      name: 'get_battery_status',
      description: 'Get device battery information',
      category: 'info',
      schema: {},
    ),

    // Contacts
    ToolDefinition(
      name: 'get_contacts',
      description: 'Get all device contacts',
      category: 'contacts',
      requiresConfirmation: true,
      schema: {},
    ),
    ToolDefinition(
      name: 'search_contacts',
      description: 'Search device contacts by name',
      category: 'contacts',
      requiresConfirmation: false,
      schema: {
        'query': {'type': 'string', 'description': 'Contact name to search for'},
      },
    ),

    // System Tools
    ToolDefinition(
      name: 'set_alarm',
      description: 'Set an alarm for specific time',
      category: 'productivity',
      schema: {
        'hour': {'type': 'integer', 'description': 'Hour (0-23)'},
        'minute': {'type': 'integer', 'description': 'Minute (0-59)'},
        'message': {'type': 'string', 'description': 'Alarm label (optional)'},
      },
    ),
    ToolDefinition(
      name: 'open_app',
      description: 'Open an installed app',
      category: 'media',
      requiresConfirmation: false,
      schema: {
        'packageName': {
          'type': 'string',
          'description': 'App package name',
          'examples': ['com.whatsapp', 'com.google.android.youtube'],
        },
      },
    ),

    // Permissions
    ToolDefinition(
      name: 'request_permissions',
      description: 'Request device permissions',
      category: 'system',
      requiresConfirmation: true,
      schema: {
        'permissions': {
          'type': 'array',
          'description': 'List of Android permissions',
          'examples': ['android.permission.CALL_PHONE', 'android.permission.READ_CONTACTS'],
        },
      },
    ),
    ToolDefinition(
      name: 'check_permission',
      description: 'Check if a permission is granted',
      category: 'system',
      schema: {
        'permission': {
          'type': 'string',
          'description': 'Android permission to check',
        },
      },
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
