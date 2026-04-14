import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/tools/tool_bloc.dart';
import '../../models/tool_definitions.dart';
import '../widgets/index.dart';

class ToolsManagementScreen extends StatefulWidget {
  const ToolsManagementScreen({super.key});

  @override
  State<ToolsManagementScreen> createState() => _ToolsManagementScreenState();
}

class _ToolsManagementScreenState extends State<ToolsManagementScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ToolBloc>().loadAvailableTools();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tools'),
        backgroundColor: colorScheme.surface,
      ),
      body: BlocListener<ToolBloc, ToolState>(
        listener: (context, state) {
          if (state is ToolConfirmationRequired) {
            showDialog(
              context: context,
              builder: (_) => ToolConfirmationDialog(
                toolCall: state.toolCall,
                definition: state.definition,
                onConfirm: () {
                  Navigator.pop(context);
                  context.read<ToolBloc>().confirmAndExecute(state.toolCall);
                },
                onCancel: () {
                  Navigator.pop(context);
                  context.read<ToolBloc>().resetState();
                },
              ),
            );
          } else if (state is ToolExecuted) {
            showDialog(
              context: context,
              builder: (_) => ToolExecutionDialog(
                result: state.result,
                onClose: () {
                  Navigator.pop(context);
                  context.read<ToolBloc>().resetState();
                },
              ),
            );
          } else if (state is ToolError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Category Filter
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('all', 'All'),
                  _buildCategoryChip('communication', 'Communication'),
                  _buildCategoryChip('productivity', 'Productivity'),
                  _buildCategoryChip('media', 'Media'),
                  _buildCategoryChip('settings', 'Settings'),
                  _buildCategoryChip('info', 'Info'),
                ],
              ),
            ),
            // Tools List
            Expanded(
              child: BlocBuilder<ToolBloc, ToolState>(
                builder: (context, state) {
                  if (state is ToolsLoaded) {
                    final filteredTools = _selectedCategory == 'all'
                        ? state.tools
                        : state.tools
                        .where((t) => t.category == _selectedCategory)
                        .toList();

                    if (filteredTools.isEmpty) {
                      return Center(
                        child: Text(
                          'No tools in this category',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ToolCard(
                            tool: tool,
                            onTap: () {
                              _showToolExecutionDialog(context, tool);
                            },
                          ),
                        );
                      },
                    );
                  }

                  if (state is ToolExecuting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Executing: ${state.toolName}'),
                        ],
                      ),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedCategory == value,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
      ),
    );
  }

  void _showToolExecutionDialog(BuildContext context, ToolDefinition tool) {
    final args = _getDefaultArgs(tool.name);
    final toolCall = ToolCall(tool: tool.name, args: args);

    if (tool.requiresConfirmation) {
      context.read<ToolBloc>().requestToolConfirmation(toolCall, tool);
    } else {
      context.read<ToolBloc>().executeToolCall(toolCall);
    }
  }

  Map<String, dynamic> _getDefaultArgs(String toolName) {
    switch (toolName) {
      case 'make_call':
        return {'phone_number': '', 'direct': false};
      case 'send_sms':
        return {'phone_number': '', 'message': ''};
      case 'share_text':
        return {'text': '', 'package': null};
      case 'set_alarm':
        return {'hour': 7, 'minute': 0, 'label': 'Alarm'};
      case 'set_timer':
        return {'seconds': 300, 'label': 'Timer'};
      case 'open_app':
        return {'package': 'com.whatsapp'};
      case 'open_settings':
        return {'target': 'wifi'};
      default:
        return {};
    }
  }
}
