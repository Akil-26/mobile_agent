import 'dart:convert';
import '../models/tool_definitions.dart';
import 'native_platform_service.dart';

class ToolsService {
  /// Convert native result to ToolResult
  static ToolResult _toToolResult(
    String toolName,
    Map<String, dynamic> nativeResult,
  ) {
    return ToolResult(
      toolName: toolName,
      success: nativeResult['success'] ?? false,
      error: nativeResult['error'] ?? nativeResult['message'],
      data: nativeResult,
    );
  }

  /// Parse and execute a tool call
  static Future<ToolResult> executeTool(ToolCall toolCall) async {
    final tool = toolCall.tool;
    final args = toolCall.args;

    try {
      switch (tool) {
        // Communication
        case 'make_call':
          final result = await NativePlatformService.makeCall(
            args['phoneNumber'] ?? args['phone_number'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'send_sms':
          final result = await NativePlatformService.sendSms(
            args['phoneNumber'] ?? args['phone_number'] ?? '',
            args['message'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'send_email':
          final result = await NativePlatformService.sendEmail(
            recipient: args['recipient'] ?? '',
            subject: args['subject'],
            body: args['body'],
          );
          return _toToolResult(tool, result);

        // File Operations
        case 'read_file':
          final result = await NativePlatformService.readFile(
            args['path'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'write_file':
          final result = await NativePlatformService.writeFile(
            args['path'] ?? '',
            args['content'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'delete_file':
          final result = await NativePlatformService.deleteFile(
            args['path'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'list_files':
          final result = await NativePlatformService.listFiles(
            args['directory'],
          );
          return _toToolResult(tool, result);

        // System Tools
        case 'get_device_info':
          final result = await NativePlatformService.getDeviceInfo();
          return _toToolResult(tool, result);

        case 'set_alarm':
          final result = await NativePlatformService.setAlarm(
            hour: args['hour'] ?? 0,
            minute: args['minute'] ?? 0,
            message: args['message'] ?? args['label'],
          );
          return _toToolResult(tool, result);

        case 'open_app':
          final result = await NativePlatformService.openApp(
            args['packageName'] ?? args['package'] ?? '',
          );
          return _toToolResult(tool, result);

        case 'get_battery_status':
          final result = await NativePlatformService.getBatteryStatus();
          return _toToolResult(tool, result);

        // Contacts
        case 'get_contacts':
          final result = await NativePlatformService.getContacts();
          return _toToolResult(tool, result);

        case 'search_contacts':
          final result = await NativePlatformService.searchContacts(
            args['query'] ?? '',
          );
          return _toToolResult(tool, result);

        // Permissions
        case 'request_permissions':
          final result = await NativePlatformService.requestPermissions(
            List<String>.from(args['permissions'] ?? []),
          );
          return _toToolResult(tool, result);

        case 'check_permission':
          final result = await NativePlatformService.checkPermission(
            args['permission'] ?? '',
          );
          return _toToolResult(tool, result);

        default:
          return ToolResult(
            toolName: tool,
            success: false,
            error: 'Unknown tool: $tool',
          );
      }
    } catch (e) {
      return ToolResult(
        toolName: tool,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Try to extract tool call from LLM response
  static ToolCall? extractToolCall(String response) {
    try {
      // Look for JSON-like patterns
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) return null;

      final jsonStr = jsonMatch.group(0);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (json.containsKey('tool')) {
        return ToolCall.fromJson(json);
      }
    } catch (e) {
      // Not a valid tool call
    }
    return null;
  }

  /// Get user-friendly description of tool result
  static String describeToolResult(ToolResult result) {
    if (!result.success) {
      return '⚠️ ${result.toolName} failed: ${result.error}';
    }

    switch (result.toolName) {
      // Device Info
      case 'get_device_info':
        final info = result.data?['deviceInfo'] ?? {};
        return '📱 Device: ${info['brand']} ${info['model']} (Android ${info['androidVersion']})';

      case 'get_battery_status':
        final level = result.data?['level'] ?? 0;
        final charging = result.data?['isCharging'] ?? false;
        return '🔋 Battery: $level% ${charging ? '(Charging)' : ''}';

      // Contacts
      case 'get_contacts':
        final count = result.data?['count'] ?? 0;
        return '👥 Found $count contacts';

      case 'search_contacts':
        final count = result.data?['count'] ?? 0;
        final query = result.data?['query'] ?? '';
        return '🔍 Found $count contacts matching "$query"';

      // File Operations
      case 'read_file':
        final size = result.data?['size'] ?? 0;
        return '📄 File read (${_formatBytes(size)})';

      case 'write_file':
        final path = result.data?['path'] ?? '';
        return '✍️ File written: $path';

      case 'delete_file':
        return '🗑️ File deleted';

      case 'list_files':
        final count = result.data?['count'] ?? 0;
        return '📁 Listed $count files';

      // Communication
      case 'make_call':
      case 'send_sms':
      case 'send_email':
        return '✅ ${result.toolName} executed';

      // System
      case 'set_alarm':
      case 'open_app':
      case 'request_permissions':
      case 'check_permission':
        return '✅ ${result.data?['message'] ?? 'Operation completed'}';

      default:
        return '✅ ${result.toolName} executed successfully';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
