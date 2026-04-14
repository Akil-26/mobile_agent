part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class InitializeSettingsEvent extends SettingsEvent {}

class DownloadModelEvent extends SettingsEvent {}

class DeleteModelEvent extends SettingsEvent {}

class LoadModelEvent extends SettingsEvent {}

class UpdateModelEvent extends SettingsEvent {
  final String model;
  UpdateModelEvent({required this.model});
}

class UpdateOllamaUrlEvent extends SettingsEvent {
  final String url;
  UpdateOllamaUrlEvent({required this.url});
}
