import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../home/providers/location_provider.dart';
import '../../settings/providers/settings_provider.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role; // user | assistant
  final String content;
}

class ChatState {
  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
  });
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());
  final Ref _ref;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    final next = [...state.messages, ChatMessage(role: 'user', content: trimmed)];
    state = state.copyWith(messages: next, sending: true, clearError: true);
    try {
      final settings = _ref.read(settingsProvider);
      final location = _ref.read(locationProvider);
      final result = await ApiClient.instance.post('/chat', data: {
        'message': trimmed,
        'messages': next
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        'location': location.name,
        'language': settings.language,
        'farmer_mode': settings.userPersona == 'farmer',
        'crop': settings.userPersona == 'farmer' ? 'Wheat' : '',
      });
      final reply = '${result['response'] ?? ''}';
      state = state.copyWith(
        sending: false,
        messages: [...next, ChatMessage(role: 'assistant', content: reply)],
      );
    } on AppApiError catch (e) {
      state = state.copyWith(sending: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          sending: false, error: 'Could not reach WeatherGPT. Try again.');
    }
  }

  void clear() => state = const ChatState();
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) => ChatNotifier(ref));
