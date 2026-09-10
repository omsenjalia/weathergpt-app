import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/farm_profile_model.dart';

class FarmProfileNotifier extends StateNotifier<FarmProfile> {
  FarmProfileNotifier() : super(_load());

  static FarmProfile _load() {
    if (!Hive.isBoxOpen('farm_profile')) return FarmProfile.defaultProfile;
    final stored = Hive.box('farm_profile').get('profile');
    return stored is Map
        ? FarmProfile.fromMap(stored)
        : FarmProfile.defaultProfile;
  }

  Future<void> save(FarmProfile profile) async {
    final box = Hive.isBoxOpen('farm_profile')
        ? Hive.box('farm_profile')
        : await Hive.openBox('farm_profile');
    await box.put('profile', profile.toMap());
    state = profile;
  }
}

final farmProfileProvider =
    StateNotifierProvider<FarmProfileNotifier, FarmProfile>(
  (ref) => FarmProfileNotifier(),
);
