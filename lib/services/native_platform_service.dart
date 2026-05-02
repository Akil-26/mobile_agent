import 'package:flutter/services.dart';
import 'dart:io';

/// Service for calling native Android/iOS platform code
/// Handles all system-level operations (calls, SMS, files, etc.)
class NativePlatformService {
  static const platform = MethodChannel('com.mobile_agent/native_tools');

  // ═══════════════════════════════════════════════════════════
  // COMMUNICATION TOOLS
  // ═══════════════════════════════════════════════════════════

  /// Make a phone call
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> makeCall(String phoneNumber) async {
    try {
      final result = await platform.invokeMethod('make_call', {
        'phoneNumber': phoneNumber,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to make call',
      };
    }
  }

  /// Send SMS
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> sendSms(
    String phoneNumber,
    String message,
  ) async {
    try {
      final result = await platform.invokeMethod('send_sms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to send SMS',
      };
    }
  }

  /// Send email (opens email client)
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> sendEmail({
    required String recipient,
    String? subject,
    String? body,
  }) async {
    try {
      final result = await platform.invokeMethod('send_email', {
        'recipient': recipient,
        'subject': subject,
        'body': body,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to send email',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Read file contents
  /// Returns: {success: bool, content: String, size: int}
  static Future<Map<String, dynamic>> readFile(String path) async {
    try {
      final result = await platform.invokeMethod('read_file', {
        'path': path,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to read file',
      };
    }
  }

  /// Write content to file
  /// Returns: {success: bool, path: String, message: String}
  static Future<Map<String, dynamic>> writeFile(
    String path,
    String content,
  ) async {
    try {
      final result = await platform.invokeMethod('write_file', {
        'path': path,
        'content': content,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to write file',
      };
    }
  }

  /// Delete file
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> deleteFile(String path) async {
    try {
      final result = await platform.invokeMethod('delete_file', {
        'path': path,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to delete file',
      };
    }
  }

  /// List files in directory
  /// Returns: {success: bool, files: List, count: int}
  static Future<Map<String, dynamic>> listFiles([String? directory]) async {
    try {
      final result = await platform.invokeMethod('list_files', {
        'directory': directory,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to list files',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SYSTEM TOOLS
  // ═══════════════════════════════════════════════════════════

  /// Get device information
  /// Returns: {success: bool, deviceInfo: Map}
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await platform.invokeMethod('get_device_info');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to get device info',
      };
    }
  }

  /// Set alarm
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> setAlarm({
    required int hour,
    required int minute,
    String? message,
  }) async {
    try {
      final result = await platform.invokeMethod('set_alarm', {
        'hour': hour,
        'minute': minute,
        'message': message ?? 'Alarm',
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to set alarm',
      };
    }
  }

  /// Open app by package name
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> openApp(String packageName) async {
    try {
      final result = await platform.invokeMethod('open_app', {
        'packageName': packageName,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to open app',
      };
    }
  }

  /// Get battery status
  /// Returns: {success: bool, level: int, isCharging: bool}
  static Future<Map<String, dynamic>> getBatteryStatus() async {
    try {
      final result = await platform.invokeMethod('get_battery_status');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to get battery status',
      };
    }
  }

  /// Get all contacts
  /// Returns: {success: bool, contacts: List, count: int}
  static Future<Map<String, dynamic>> getContacts() async {
    try {
      final result = await platform.invokeMethod('get_contacts');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to get contacts',
      };
    }
  }

  /// Search contacts by name
  /// Returns: {success: bool, contacts: List, count: int, query: String}
  static Future<Map<String, dynamic>> searchContacts(String query) async {
    try {
      final result = await platform.invokeMethod('search_contacts', {
        'query': query,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to search contacts',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PERMISSION HANDLING
  // ═══════════════════════════════════════════════════════════

  /// Request multiple permissions
  /// Returns: {success: bool, message: String}
  static Future<Map<String, dynamic>> requestPermissions(
    List<String> permissions,
  ) async {
    try {
      final result = await platform.invokeMethod('request_permissions', {
        'permissions': permissions,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to request permissions',
      };
    }
  }

  /// Check if a permission is granted
  /// Returns: {granted: bool, permission: String}
  static Future<Map<String, dynamic>> checkPermission(String permission) async {
    try {
      final result = await platform.invokeMethod('check_permission', {
        'permission': permission,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Failed to check permission',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Get platform-specific permissions list for common operations
  static List<String> getRequiredPermissions({
    bool needCalls = false,
    bool needSms = false,
    bool needContacts = false,
    bool needStorage = false,
    bool needLocation = false,
  }) {
    final permissions = <String>[];

    if (isAndroid) {
      if (needCalls) {
        permissions.add('android.permission.CALL_PHONE');
      }
      if (needSms) {
        permissions.addAll([
          'android.permission.SEND_SMS',
          'android.permission.READ_SMS',
        ]);
      }
      if (needContacts) {
        permissions.add('android.permission.READ_CONTACTS');
      }
      if (needStorage) {
        permissions.addAll([
          'android.permission.READ_EXTERNAL_STORAGE',
          'android.permission.WRITE_EXTERNAL_STORAGE',
        ]);
      }
      if (needLocation) {
        permissions.addAll([
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.ACCESS_COARSE_LOCATION',
        ]);
      }
    }

    return permissions;
  }
}

