import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../home/providers/location_provider.dart';
import '../../settings/providers/settings_provider.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.meta});
  final String role; // user | assistant
  final String content;

  /// Additive response metadata from the backend (`meta` in /chat responses).
  /// Present on the assistant message when the server sent it; used to surface
  /// routing diagnostics such as the System One intent engine.
  final Map<String, dynamic>? meta;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
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
      final result =
          await ApiClient.instance.post('/chat', data: _buildPayload(next, trimmed));
      final reply = '${result['response'] ?? ''}';
      final meta = result['meta'] is Map
          ? (result['meta'] as Map).cast<String, dynamic>()
          : null;
      state = state.copyWith(
        sending: false,
        messages: [
          ...next,
          ChatMessage(role: 'assistant', content: reply, meta: meta),
        ],
      );
    } on AppApiError catch (e) {
      state = state.copyWith(sending: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          sending: false, error: 'Could not reach WeatherGPT. Try again.');
    }
  }

  /// Assembles the /chat request body from the current settings and location.
  Map<String, dynamic> _buildPayload(
      List<ChatMessage> messages, String message) {
    final settings = _ref.read(settingsProvider);
    final location = _ref.read(locationProvider);
    return {
      'message': message,
      'messages': messages.map((m) => m.toJson()).toList(),
      'location': location.name,
      'lat': location.lat,
      'lon': location.lon,
      'language': settings.language,
      'farmer_mode': settings.userPersona == 'farmer',
      'crop': settings.userPersona == 'farmer' ? 'Wheat' : '',
    };
  }

  void clear() => state = const ChatState();
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) => ChatNotifier(ref));
