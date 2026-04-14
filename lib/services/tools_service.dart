import 'dart:convert';
import '../models/tool_definitions.dart';
import 'native_platform_service.dart';

class ToolsService {
  /// Parse and execute a tool call
  static Future<ToolResult> executeTool(ToolCall toolCall) async {
    final tool = toolCall.tool;
    final args = toolCall.args;

    switch (tool) {
      // Communication
      case 'make_call':
        return NativePlatformService.makeCall(
          args['phone_number'] ?? '',
          direct: args['direct'] ?? false,
        );

      case 'send_sms':
        return NativePlatformService.sendSms(
          args['phone_number'] ?? '',
          args['message'] ?? '',
        );

      case 'share_text':
        return NativePlatformService.shareText(
          args['text'] ?? '',
          package: args['package'],
        );

      // Productivity
      case 'set_alarm':
        return NativePlatformService.setAlarm(
          args['hour'] ?? 0,
          args['minute'] ?? 0,
          label: args['label'],
          skipUi: args['skip_ui'] ?? false,
        );

      case 'set_timer':
        return NativePlatformService.setTimer(
          args['seconds'] ?? 0,
          label: args['label'],
          skipUi: args['skip_ui'] ?? false,
        );

      // Media
      case 'open_camera':
        return NativePlatformService.openCamera();

      case 'open_app':
        return NativePlatformService.openApp(args['package'] ?? '');

      // Settings
      case 'open_settings':
        return NativePlatformService.openSettings(args['target'] ?? 'general');

      // System Info
      case 'get_battery_status':
        return NativePlatformService.getBatteryStatus();

      case 'get_storage_info':
        return NativePlatformService.getStorageInfo();

      case 'get_network_status':
        return NativePlatformService.getNetworkStatus();

      default:
        return ToolResult(
          toolName: tool,
          success: false,
          error: 'Unknown tool: $tool',
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
      case 'get_battery_status':
        final battery = result.data?['battery_percent'] ?? 0;
        final charging = result.data?['is_charging'] ?? false;
        return '🔋 Battery: $battery% ${charging ? '(Charging)' : ''}';

      case 'get_storage_info':
        final free = result.data?['free_bytes'] ?? 0;
        final total = result.data?['total_bytes'] ?? 0;
        return '💾 Storage: ${_formatBytes(free)} free / ${_formatBytes(total)} total';

      case 'get_network_status':
        final connection = result.data?['connection'] ?? 'unknown';
        return '📶 Network: $connection';

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
