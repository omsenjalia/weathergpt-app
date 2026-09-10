import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingState {
  const OnboardingState({
    this.selectedLanguage = 'en',
    this.selectedPersona = 'farmer',
    this.currentStep = 0,
  });

  final String selectedLanguage;
  final String selectedPersona;
  final int currentStep;

  OnboardingState copyWith({
    String? selectedLanguage,
    String? selectedPersona,
    int? currentStep,
  }) =>
      OnboardingState(
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        selectedPersona: selectedPersona ?? this.selectedPersona,
        currentStep: currentStep ?? this.currentStep,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void selectLanguage(String code) =>
      state = state.copyWith(selectedLanguage: code, currentStep: 1);

  void selectPersona(String persona) =>
      state = state.copyWith(selectedPersona: persona, currentStep: 2);

  Future<void> completeOnboarding() async {
    final box = Hive.box('settings');
    await box.put('language', state.selectedLanguage);
    await box.put('user_persona', state.selectedPersona);
    await box.put('onboarding_complete', true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);
