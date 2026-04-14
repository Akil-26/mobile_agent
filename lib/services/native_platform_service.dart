import 'package:flutter/services.dart';
import '../models/tool_definitions.dart';

class NativePlatformService {
  static const methodChannel = MethodChannel('com.example.ai_assistant/tools');

  /// Communication Tools

  static Future<ToolResult> makeCall(String phoneNumber, {bool direct = false}) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'make_call',
        {
          'phone_number': phoneNumber,
          'direct': direct,
        },
      );
      return ToolResult(
        toolName: 'make_call',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'make_call',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> sendSms(String phoneNumber, String message) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'send_sms',
        {
          'phone_number': phoneNumber,
          'message': message,
        },
      );
      return ToolResult(
        toolName: 'send_sms',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'send_sms',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> shareText(String text, {String? package}) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'share_text',
        {
          'text': text,
          'package': package,
        },
      );
      return ToolResult(
        toolName: 'share_text',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'share_text',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Productivity Tools

  static Future<ToolResult> setAlarm(
    int hour,
    int minute, {
    String? label,
    bool skipUi = false,
  }) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'set_alarm',
        {
          'hour': hour,
          'minute': minute,
          'label': label,
          'skip_ui': skipUi,
        },
      );
      return ToolResult(
        toolName: 'set_alarm',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'set_alarm',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> setTimer(
    int seconds, {
    String? label,
    bool skipUi = false,
  }) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'set_timer',
        {
          'seconds': seconds,
          'label': label,
          'skip_ui': skipUi,
        },
      );
      return ToolResult(
        toolName: 'set_timer',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'set_timer',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Media Tools

  static Future<ToolResult> openCamera() async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'open_camera',
      );
      return ToolResult(
        toolName: 'open_camera',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'open_camera',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> openApp(String package) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'open_app',
        {'package': package},
      );
      return ToolResult(
        toolName: 'open_app',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'open_app',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Settings

  static Future<ToolResult> openSettings(String target) async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'open_settings',
        {'target': target},
      );
      return ToolResult(
        toolName: 'open_settings',
        success: result?['success'] ?? false,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'open_settings',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// System Info

  static Future<ToolResult> getBatteryStatus() async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'get_battery_status',
      );
      return ToolResult(
        toolName: 'get_battery_status',
        success: true,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'get_battery_status',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> getStorageInfo() async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'get_storage_info',
      );
      return ToolResult(
        toolName: 'get_storage_info',
        success: true,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'get_storage_info',
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<ToolResult> getNetworkStatus() async {
    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'get_network_status',
      );
      return ToolResult(
        toolName: 'get_network_status',
        success: true,
        data: Map<String, dynamic>.from(result ?? {}),
      );
    } catch (e) {
      return ToolResult(
        toolName: 'get_network_status',
        success: false,
        error: e.toString(),
      );
    }
  }
}
