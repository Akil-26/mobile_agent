part of 'chat_bloc.dart';

abstract class ChatEvent {}

class InitializeChatEvent extends ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String message;
  SendMessageEvent({required this.message});
}

class RefreshConnectionEvent extends ChatEvent {}

class ClearMessagesEvent extends ChatEvent {}
