import 'package:flutter/material.dart';
import '../../services/native_platform_service.dart';
import '../../models/tool_definitions.dart';

class ToolsTestScreen extends StatefulWidget {
  const ToolsTestScreen({Key? key}) : super(key: key);

  @override
  State<ToolsTestScreen> createState() => _ToolsTestScreenState();
}

class _ToolsTestScreenState extends State<ToolsTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String().split('T')[1]}] $message');
      if (_logs.length > 50) _logs.removeLast(); // Keep last 50 logs
    });
  }

  Future<void> _testTool(Future<Map<String, dynamic>> Function() toolCall, String name) async {
    setState(() => _isLoading = true);
    _addLog('🔄 Testing $name...');

    try {
      final result = await toolCall();
      final success = result['success'] ?? false;
      if (success) {
        _addLog('✅ $name: ${result['message'] ?? 'Success'}');
      } else {
        _addLog('❌ $name: ${result['error'] ?? result['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _addLog('❌ $name: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Tools Test'),
      ),
      body: Column(
        children: [
          // Tool buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // System Info
                  _buildSection('📱 System Information', [
                    _buildButton(
                      'Get Device Info',
                      () => _testTool(
                        NativePlatformService.getDeviceInfo,
                        'get_device_info',
                      ),
                    ),
                    _buildButton(
                      'Get Battery Status',
                      () => _testTool(
                        NativePlatformService.getBatteryStatus,
                        'get_battery_status',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Contacts
                  _buildSection('👥 Contacts', [
                    _buildButton(
                      'Get All Contacts',
                      () => _testTool(
                        NativePlatformService.getContacts,
                        'get_contacts',
                      ),
                    ),
                    _buildButton(
                      'Search Contacts (John)',
                      () => _testTool(
                        () => NativePlatformService.searchContacts('John'),
                        'search_contacts',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // File Operations
                  _buildSection('📁 File Operations', [
                    _buildButton(
                      'List Files',
                      () => _testTool(
                        () => NativePlatformService.listFiles(),
                        'list_files',
                      ),
                    ),
                    _buildButton(
                      'Write Test File',
                      () => _testTool(
                        () => NativePlatformService.writeFile(
                          '/storage/emulated/0/Download/test.txt',
                          'Hello from Mobile Agent!',
                        ),
                        'write_file',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Communication
                  _buildSection('📞 Communication', [
                    _buildButton(
                      'Permission Check: CALL_PHONE',
                      () => _testTool(
                        () => NativePlatformService.checkPermission(
                          'android.permission.CALL_PHONE',
                        ),
                        'check_permission',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // System
                  _buildSection('⚙️ System', [
                    _buildButton(
                      'Set Alarm (9:00 AM)',
                      () => _testTool(
                        () => NativePlatformService.setAlarm(
                          hour: 9,
                          minute: 0,
                          message: 'Test Alarm',
                        ),
                        'set_alarm',
                      ),
                    ),
                    _buildButton(
                      'Request Permissions',
                      () => _testTool(
                        () => NativePlatformService.requestPermissions([
                          'android.permission.READ_CONTACTS',
                        ]),
                        'request_permissions',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Clear logs
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _logs.clear()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Clear Logs'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logs
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Logs (${_logs.length})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        _logs[i],
                        style: TextStyle(
                          color: _logs[i].startsWith('✅')
                              ? Colors.green
                              : _logs[i].startsWith('❌')
                                  ? Colors.red
                                  : _logs[i].startsWith('🔄')
                                      ? Colors.yellow
                                      : Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: Text(label),
      ),
    );
  }
}
