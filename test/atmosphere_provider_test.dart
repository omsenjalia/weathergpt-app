import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weathergpt_mobile/features/home/providers/atmosphere_provider.dart';
import 'package:weathergpt_mobile/features/home/theme/atmosphere_theme.dart';

void main() {
  test('midday with no weather snapshot yields the midday clear palette',
      () {
    final container = ProviderContainer(overrides: [
      clockTickerProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 9, 22, 12, 30)),
      ),
    ]);
    addTearDown(container.dispose);

    final palette = container.read(atmospherePaletteProvider);
    final expected = paletteFor(SkyPeriod.midday, SkyCondition.clear);
    expect(palette.top, expected.top);
    expect(palette.text, expected.text);
  });

  test('late evening switches to the night palette (time-of-day drive)',
      () {
    final container = ProviderContainer(overrides: [
      clockTickerProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 9, 22, 23, 5)),
      ),
    ]);
    addTearDown(container.dispose);

    final palette = container.read(atmospherePaletteProvider);
    final expected = paletteFor(SkyPeriod.night, SkyCondition.clear);
    expect(palette.top, expected.top);
  });

  test('different times of day produce different skies', () {
    Future<AtmospherePalette> at(int hour) {
      final container = ProviderContainer(overrides: [
        clockTickerProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 9, 22, hour)),
        ),
      ]);
      final palette = container.read(atmospherePaletteProvider);
      container.dispose();
      return Future.value(palette);
    }

    expect(at(12) == at(23), isFalse);
  });
}
