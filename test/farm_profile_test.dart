import 'package:flutter_test/flutter_test.dart';
import 'package:weathergpt_mobile/features/farmer/models/farm_profile_model.dart';
import 'package:weathergpt_mobile/features/farmer/screens/farm_profile_screen.dart';

void main() {
  group('FarmProfile model', () {
    test('defaultProfile has expected defaults', () {
      expect(FarmProfile.defaultProfile.location, 'Anand, Gujarat');
      expect(FarmProfile.defaultProfile.crop, 'Wheat');
      expect(FarmProfile.defaultProfile.growthStage, 'Flowering');
      expect(FarmProfile.defaultProfile.farmSizeAcres, 4.0);
      expect(FarmProfile.defaultProfile.irrigationType, 'Borewell');
      expect(FarmProfile.defaultProfile.soilType, 'Loamy');
    });

    test('toMap and fromMap roundtrip faithfully', () {
      const profile = FarmProfile(
        location: 'Nagpur, Maharashtra',
        crop: 'Cotton',
        growthStage: 'Vegetative',
        farmSizeAcres: 12.5,
        irrigationType: 'Drip',
        soilType: 'Black',
      );
      final map = profile.toMap();
      final restored = FarmProfile.fromMap(map);

      expect(restored.location, 'Nagpur, Maharashtra');
      expect(restored.crop, 'Cotton');
      expect(restored.growthStage, 'Vegetative');
      expect(restored.farmSizeAcres, 12.5);
      expect(restored.irrigationType, 'Drip');
      expect(restored.soilType, 'Black');
    });

    test('fromMap gracefully handles empty/partial maps', () {
      final fallback = FarmProfile.fromMap(const {});
      expect(fallback.location, FarmProfile.defaultProfile.location);
      expect(fallback.crop, FarmProfile.defaultProfile.crop);
      expect(fallback.farmSizeAcres, FarmProfile.defaultProfile.farmSizeAcres);
    });

    test('copyWith updates specified fields only', () {
      final updated = FarmProfile.defaultProfile.copyWith(
        crop: 'Rice',
        farmSizeAcres: 7.0,
      );
      expect(updated.crop, 'Rice');
      expect(updated.farmSizeAcres, 7.0);
      expect(updated.location, FarmProfile.defaultProfile.location);
      expect(updated.growthStage, FarmProfile.defaultProfile.growthStage);
    });
  });

  group('FarmProfileEditor constants', () {
    test('supported crops contain primary agricultural staples', () {
      expect(FarmProfileEditor.crops, contains('Cotton'));
      expect(FarmProfileEditor.crops, contains('Wheat'));
      expect(FarmProfileEditor.crops, contains('Rice'));
      expect(FarmProfileEditor.crops, contains('Sugarcane'));
    });

    test('supported stages contain standard growth stages', () {
      expect(FarmProfileEditor.stages, contains('Sowing'));
      expect(FarmProfileEditor.stages, contains('Vegetative'));
      expect(FarmProfileEditor.stages, contains('Flowering'));
      expect(FarmProfileEditor.stages, contains('Harvest'));
    });
  });
}
