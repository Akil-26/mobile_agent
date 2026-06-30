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
    String selectedModel = 'gemma3:1b',
    String ollamaUrl = 'http://localhost:11434',
    bool darkMode = true,
    bool notifications = true,
    bool saveHistory = true,
    bool localModelDownloaded = false,
    int modelSizeBytes = 0,
  }) : super(
    selectedModel: selectedModel,
    ollamaUrl: ollamaUrl,
    darkMode: darkMode,
    notifications: notifications,
    saveHistory: saveHistory,
    localModelDownloaded: localModelDownloaded,
    modelSizeBytes: modelSizeBytes,
  );
}

class SettingsError extends SettingsState {
  final String error;

    SettingsError({
    required this.error,
    String selectedModel = 'gemma3:1b',
    String ollamaUrl = 'http://localhost:11434',
    bool darkMode = true,
    bool notifications = true,
    bool saveHistory = true,
    bool localModelDownloaded = false,
    int modelSizeBytes = 0,
  }) : super(
    selectedModel: selectedModel,
    ollamaUrl: ollamaUrl,
    darkMode: darkMode,
    notifications: notifications,
    saveHistory: saveHistory,
    localModelDownloaded: localModelDownloaded,
    modelSizeBytes: modelSizeBytes,
  );
}
