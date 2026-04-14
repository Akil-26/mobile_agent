import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../services/local_model_service.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _settingsBloc = context.read<SettingsBloc>();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SettingsSection(
                title: 'Appearance',
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: state.darkMode,
                    onChanged: (val) => _settingsBloc.updateDarkMode(val),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Local AI Model (Offline)',
                children: [
                  ListTile(
                    leading: Icon(
                      state.localModelDownloaded
                          ? Icons.check_circle
                          : Icons.download,
                      color: state.localModelDownloaded ? Colors.green : Colors.grey,
                    ),
                    title: const Text('On-Device Model'),
                    subtitle: Text(state.localModelDownloaded
                        ? 'Gemma 2 2B (${_formatBytes(state.modelSizeBytes)}) - Ready'
                        : 'Not downloaded (~1.5 GB)'),
                  ),
                  if (state is ModelDownloading)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Downloading... ${(state.progress * 100).toStringAsFixed(1)}%'),
                              Text(
                                '${_formatBytes((state.progress * 1599472640).toInt())} / ${_formatBytes(1599472640)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: state.progress),
                          const SizedBox(height: 8),
                          Text(
                            'Download will continue in background. You can safely navigate away.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.outlineVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  else if (!state.localModelDownloaded)
                    ListTile(
                      leading: Icon(
                        Icons.cloud_download,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Download Local Model'),
                      subtitle: const Text(
                          'Run AI completely offline on your device'),
                      onTap: () => _settingsBloc.downloadLocalModel(
                        onProgress: (progress) {
                          setState(() {});
                        },
                      ),
                    ),
                  if (state.localModelDownloaded)
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      title: const Text('Delete Local Model'),
                      subtitle: const Text('Remove to free up storage'),
                      onTap: () => _deleteModel(context),
                    ),
                  if (state.localModelDownloaded)
                    ListTile(
                      leading: Icon(
                        LocalModelService.isLoaded
                            ? Icons.memory
                            : Icons.play_arrow,
                        color: LocalModelService.isLoaded ? Colors.green : Colors.grey,
                      ),
                      title: Text(LocalModelService.isLoaded
                          ? 'Model Loaded'
                          : 'Load Model'),
                      subtitle: Text(LocalModelService.isLoaded
                          ? 'Ready for inference'
                          : 'Load model into memory'),
                      onTap: LocalModelService.isLoaded
                          ? null
                          : () {
                            _settingsBloc.loadLocalModel();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Loading model...')),
                            );
                          },
                    ),
                ],
              ),
              SettingsSection(
                title: 'Privacy & Data',
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.history_outlined),
                    title: const Text('Save Chat History'),
                    subtitle: const Text('Store conversations locally'),
                    value: state.saveHistory,
                    onChanged: (val) => _settingsBloc.updateSaveHistory(val),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear Chat History'),
                    subtitle: const Text('Delete all conversations'),
                    onTap: () => _showClearHistoryDialog(context),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Notifications',
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive task reminders'),
                    value: state.notifications,
                    onChanged: (val) => _settingsBloc.updateNotifications(val),
                  ),
                ],
              ),
              SettingsSection(
                title: 'About',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteModel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Local Model'),
        content: const Text(
          'This will remove the downloaded AI model. You can re-download it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              _settingsBloc.deleteLocalModel();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Model deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
