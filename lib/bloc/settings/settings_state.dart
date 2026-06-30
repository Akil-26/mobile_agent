part of 'settings_bloc.dart';

abstract class SettingsState {
  final String selectedModel;
  final String ollamaUrl;
  final bool darkMode;
  final bool notifications;
  final bool saveHistory;
  final bool localModelDownloaded;
  final int modelSizeBytes;

  SettingsState({
    required this.selectedModel,
    required this.ollamaUrl,
    required this.darkMode,
    required this.notifications,
    required this.saveHistory,
    required this.localModelDownloaded,
    required this.modelSizeBytes,
  });
}

class SettingsInitial extends SettingsState {
  SettingsInitial({
    required super.selectedModel,
    required super.ollamaUrl,
    required super.darkMode,
    required super.notifications,
    required super.saveHistory,
    required super.localModelDownloaded,
    required super.modelSizeBytes,
  });
}

class SettingsInitialized extends SettingsState {
  SettingsInitialized({
    required super.selectedModel,
    required super.ollamaUrl,
    required super.darkMode,
    required super.notifications,
    required super.saveHistory,
    required super.localModelDownloaded,
    required super.modelSizeBytes,
  });
}

class ModelDownloading extends SettingsState {
  final double progress;

  ModelDownloading({
    required this.progress,
    super.selectedModel = 'gemma3:1b',
    super.ollamaUrl = 'http://localhost:11434',
    super.darkMode = true,
    super.notifications = true,
    super.saveHistory = true,
    super.localModelDownloaded = false,
    super.modelSizeBytes = 0,
  });
}

class SettingsError extends SettingsState {
  final String error;

    SettingsError({
    required this.error,
    super.selectedModel = 'gemma3:1b',
    super.ollamaUrl = 'http://localhost:11434',
    super.darkMode = true,
    super.notifications = true,
    super.saveHistory = true,
    super.localModelDownloaded = false,
    super.modelSizeBytes = 0,
  });
}
