import 'package:bloc/bloc.dart';
import '../../services/local_model_service.dart';
import '../../services/ollama_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Cubit<SettingsState> {
  SettingsBloc()
      : super(SettingsInitial(
          selectedModel: OllamaService.model,
          ollamaUrl: OllamaService.baseUrl,
          darkMode: true,
          notifications: true,
          saveHistory: true,
          localModelDownloaded: false,
          modelSizeBytes: 0,
        ));

  Future<void> initializeSettings() async {
    try {
      final downloaded = await LocalModelService.isModelDownloaded();
      final size = await LocalModelService.getModelSizeBytes();

      // If model is downloading, show resume option
      if (LocalModelService.isLoading) {
        emit(ModelDownloading(progress: LocalModelService.downloadProgress));
      } else {
        emit(SettingsInitialized(
          selectedModel: OllamaService.model,
          ollamaUrl: OllamaService.baseUrl,
          darkMode: true,
          notifications: true,
          saveHistory: true,
          localModelDownloaded: downloaded,
          modelSizeBytes: size,
        ));
      }
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> downloadLocalModel({Function(double)? onProgress}) async {
    try {
      // Check if download is already in progress
      if (LocalModelService.isLoading) {
        emit(SettingsError(
          error: 'Download already in progress. It will continue in the background.',
        ));
        return;
      }

      emit(ModelDownloading(progress: 0.0));

      await LocalModelService.downloadModel(onProgress: (progress) {
        onProgress?.call(progress);
        emit(ModelDownloading(progress: progress));
      });

      await LocalModelService.loadModel();
      final size = await LocalModelService.getModelSizeBytes();

      emit(SettingsInitialized(
        selectedModel: OllamaService.model,
        ollamaUrl: OllamaService.baseUrl,
        darkMode: true,
        notifications: true,
        saveHistory: true,
        localModelDownloaded: true,
        modelSizeBytes: size,
      ));
    } catch (e) {
      emit(SettingsError(error: 'Download failed: $e'));
    }
  }

  Future<void> deleteLocalModel() async {
    try {
      await LocalModelService.deleteModel();
      final size = await LocalModelService.getModelSizeBytes();

      emit(SettingsInitialized(
        selectedModel: OllamaService.model,
        ollamaUrl: OllamaService.baseUrl,
        darkMode: true,
        notifications: true,
        saveHistory: true,
        localModelDownloaded: false,
        modelSizeBytes: size,
      ));
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  Future<void> loadLocalModel() async {
    try {
      final success = await LocalModelService.loadModel();
      if (!success) {
        emit(SettingsError(error: 'Failed to load model'));
      }
    } catch (e) {
      emit(SettingsError(error: e.toString()));
    }
  }

  void updateModel(String model) {
    OllamaService.model = model;
  }

  void updateOllamaUrl(String url) {
    OllamaService.baseUrl = url;
  }

  void updateDarkMode(bool value) {
    // Theme update logic here
  }

  void updateNotifications(bool value) {
    // Notifications logic here
  }

  void updateSaveHistory(bool value) {
    // Save history logic here
  }
}
