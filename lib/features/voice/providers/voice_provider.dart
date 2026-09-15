import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/markdown_utils.dart';
import '../../home/providers/location_provider.dart';
import '../../settings/providers/settings_provider.dart';

enum VoiceStatus { idle, listening, processing, speaking, done, error }

enum ResultType { irrigation, rainForecast, general, cropStatus, researchQuery }

class ResultStat {
  const ResultStat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

class ForecastDay {
  const ForecastDay(this.day, this.icon, this.temperature, this.rainfall);
  final String day;
  final IconData icon;
  final String temperature;
  final String rainfall;
}

class VoiceResponse {
  const VoiceResponse(
      {required this.transcript,
      required this.type,
      required this.accent,
      required this.label,
      required this.verdict,
      required this.explanation,
      required this.stats,
      required this.forecast,
      required this.ctaLabel});
  final String transcript;
  final ResultType type;
  final Color accent;
  final String label;
  final String verdict;
  final String explanation;
  final List<ResultStat> stats;
  final List<ForecastDay> forecast;
  final String ctaLabel;
}

class VoiceState {
  const VoiceState(
      {this.status = VoiceStatus.idle,
      this.transcript = '',
      this.response,
      this.errorMessage});
  final VoiceStatus status;
  final String transcript;
  final VoiceResponse? response;
  final String? errorMessage;
  VoiceState copyWith(
          {VoiceStatus? status,
          String? transcript,
          VoiceResponse? response,
          String? errorMessage}) =>
      VoiceState(
          status: status ?? this.status,
          transcript: transcript ?? this.transcript,
          response: response ?? this.response,
          errorMessage: errorMessage ?? this.errorMessage);
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier(this._ref) : super(const VoiceState());
  final Ref _ref;
  final _speech = stt.SpeechToText();

  /// Map app language code → speech_to_text locale id.
  String _sttLocale() {
    final lang = _ref.read(settingsProvider).language.toLowerCase();
    const map = {
      'en': 'en_US',
      'hi': 'hi_IN',
      'gu': 'gu_IN',
      'mr': 'mr_IN',
      'ta': 'ta_IN',
      'te': 'te_IN',
      'kn': 'kn_IN',
      'ml': 'ml_IN',
      'bn': 'bn_IN',
      'pa': 'pa_IN',
    };
    return map[lang] ?? 'en_US';
  }

  Timer? _silenceTimer;

  Future<void> startListening() async {
    state = const VoiceState(status: VoiceStatus.processing);
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        state = const VoiceState(
            status: VoiceStatus.error,
            errorMessage:
                'Microphone access is needed to listen. You can still use a suggested question.');
        return;
      }

      // Prefer speech-to-text only. Dual record+STT is a common crash source
      // on Android when the temp path is invalid or the plugin races.
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && state.status == VoiceStatus.listening) {
            stopListening();
          }
        },
        onError: (_) {
          if (state.status == VoiceStatus.listening) stopListening();
        },
      );
      if (!available) {
        state = const VoiceState(
            status: VoiceStatus.error,
            errorMessage:
                'Speech recognition is not available on this device.');
        return;
      }

      state = const VoiceState(status: VoiceStatus.listening);
      final localeId = _sttLocale();
      await _speech.listen(
        localeId: localeId,
        onResult: (result) {
          state = state.copyWith(transcript: result.recognizedWords);
          _restartSilenceTimer();
          if (result.finalResult) {
            stopListening();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        ),
      );
      _restartSilenceTimer();
    } catch (e) {
      state = const VoiceState(
          status: VoiceStatus.error,
          errorMessage:
              'Could not start listening. Please try again.');
    }
  }

  void _restartSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 2500), stopListening);
  }

  Future<void> stopListening() async {
    if (state.status != VoiceStatus.listening) return;
    _silenceTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    state = state.copyWith(status: VoiceStatus.processing);
    await submitToBackend();
  }

  Future<void> submitQuery(String text) async {
    _silenceTimer?.cancel();
    state = VoiceState(status: VoiceStatus.processing, transcript: text);
    await submitToBackend();
  }

  Future<void> submitToBackend({String? audioPath}) async {
    try {
      final settings = _ref.read(settingsProvider);
      final location = _ref.read(locationProvider);
      final transcript = state.transcript.trim();
      if (transcript.isEmpty) {
        state = const VoiceState(
            status: VoiceStatus.error,
            errorMessage: 'No speech detected. Try again or pick a suggestion.');
        return;
      }

      // Always use /chat — /voice multipart is optional and often unavailable.
      final result = await ApiClient.instance.post('/chat', data: {
        'message': transcript,
        'location': location.name,
        'language': settings.language,
        'farmer_mode': settings.userPersona == 'farmer',
        'crop': settings.userPersona == 'farmer' ? 'Wheat' : '',
      });
      final responseText = '${result['response'] ?? ''}';
      state = state.copyWith(
        status: VoiceStatus.done,
        response: _responseFromBackend(transcript, responseText),
      );
    } on AppApiError catch (error) {
      state = state.copyWith(
          status: VoiceStatus.error, errorMessage: error.message);
    } catch (e) {
      state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'WeatherGPT took too long to answer. Please try again.');
    }
  }

  /// Explicit backend-to-UI mapping. The text response does not coerce enum values.
  VoiceResponse _responseFromBackend(String query, String response) {
    final normalized = query.toLowerCase();
    final type = normalized.contains('irrigat')
        ? ResultType.irrigation
        : normalized.contains('rain') || normalized.contains('forecast')
            ? ResultType.rainForecast
            : normalized.contains('crop') || normalized.contains('wheat')
                ? ResultType.cropStatus
                : ResultType.general;
    final base = _responseFor(query);
    final body = response.trim().isEmpty ? base.explanation : response.trim();
    // First meaningful line as short verdict; full body kept for markdown UI
    final plain = MarkdownUtils.forSpeech(body);
    final firstLine = plain.split(RegExp(r'[.!?\n]')).map((s) => s.trim()).firstWhere(
          (s) => s.isNotEmpty,
          orElse: () => base.verdict,
        );
    final verdict = firstLine.length > 90 ? '${firstLine.substring(0, 90)}…' : firstLine;
    return VoiceResponse(
      transcript: query,
      type: type,
      accent: base.accent,
      label: base.label,
      verdict: verdict.isEmpty ? base.verdict : verdict,
      explanation: body,
      stats: base.stats,
      forecast: base.forecast,
      ctaLabel: base.ctaLabel,
    );
  }

  VoiceResponse _responseFor(String query) {
    final normalized = query.toLowerCase();
    const days = [
      ForecastDay('Tue', Icons.wb_sunny_outlined, '24°', '0 mm'),
      ForecastDay('Wed', Icons.thunderstorm_outlined, '26°', '12 mm'),
      ForecastDay('Thu', Icons.water_drop_outlined, '25°', '4 mm')
    ];
    if (normalized.contains('rain') || normalized.contains('forecast')) {
      return VoiceResponse(
          transcript: query.isEmpty ? 'Will it rain tomorrow?' : query,
          type: ResultType.rainForecast,
          accent: AppColors.researcherBlue,
          label: 'Rain Forecast',
          verdict: 'Rain expected tomorrow',
          explanation:
              'A moderate spell is likely from late morning, bringing around 12 mm of rainfall.',
          stats: const [
            ResultStat('Chance of rain', '78%'),
            ResultStat('Expected rain', '12 mm',
                color: AppColors.researcherBlue),
            ResultStat('Wind', '14 km/h')
          ],
          forecast: days,
          ctaLabel: 'View Detailed Forecast');
    }
    if (normalized.contains('irrigat')) {
      return VoiceResponse(
          transcript:
              query.isEmpty ? 'Should I irrigate my wheat field today?' : query,
          type: ResultType.irrigation,
          accent: AppColors.statusAmber,
          label: 'Irrigation Recommendation',
          verdict: 'Not recommended today',
          explanation:
              'Rain is likely tomorrow (12 mm), which should provide enough moisture for your wheat field.',
          stats: const [
            ResultStat('Rain (tomorrow)', '12 mm'),
            ResultStat('Soil Moisture', 'Adequate',
                color: AppColors.statusGreenText),
            ResultStat('Field Condition', 'Good',
                color: AppColors.statusGreenText)
          ],
          forecast: days,
          ctaLabel: 'View Detailed Forecast');
    }
    if (normalized.contains('crop') || normalized.contains('wheat')) {
      return VoiceResponse(
          transcript: query.isEmpty ? 'How is my wheat crop doing?' : query,
          type: ResultType.cropStatus,
          accent: AppColors.farmerGreen,
          label: 'Crop Status',
          verdict: 'Crop conditions look healthy',
          explanation:
              'Your wheat is in a favourable moisture range. Watch for rain tomorrow before scheduling field work.',
          stats: const [
            ResultStat('Soil Moisture', 'Adequate',
                color: AppColors.statusGreenText),
            ResultStat('Growth stage', 'Flowering'),
            ResultStat('Disease risk', 'Low', color: AppColors.statusGreenText)
          ],
          forecast: days,
          ctaLabel: 'View Farm Action Windows');
    }
    return VoiceResponse(
        transcript:
            query.isEmpty ? 'Should I irrigate my wheat field today?' : query,
        type: ResultType.irrigation,
        accent: AppColors.statusAmber,
        label: 'Irrigation Recommendation',
        verdict: 'Not recommended today',
        explanation:
            'Rain is likely tomorrow (12 mm), which should provide enough moisture for your wheat field.',
        stats: const [
          ResultStat('Rain (tomorrow)', '12 mm'),
          ResultStat('Soil Moisture', 'Adequate',
              color: AppColors.statusGreenText),
          ResultStat('Field Condition', 'Good',
              color: AppColors.statusGreenText)
        ],
        forecast: days,
        ctaLabel: 'View Detailed Forecast');
  }

  Future<void> speak(String text) async {
    state = state.copyWith(status: VoiceStatus.speaking);
    try {
      final voice = _ref.read(settingsProvider);
      final tts = FlutterTts();
      await tts.setLanguage(voice.ttsVoiceLocale);
      // FlutterTts: ~0.5 is natural on Android; UI stores 0.3–1.0.
      final rate = (voice.ttsSpeed * 0.55).clamp(0.25, 0.75);
      await tts.setSpeechRate(rate);
      final clean = MarkdownUtils.forSpeech(text);
      if (clean.isNotEmpty) {
        await tts.speak(clean);
      }
    } catch (_) {}
    state = state.copyWith(status: VoiceStatus.done);
  }

  void cancel() {
    _silenceTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    state = const VoiceState();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>(
    (ref) => VoiceNotifier(ref));
