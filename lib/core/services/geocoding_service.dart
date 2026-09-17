import 'package:dio/dio.dart';

import '../../models/location.dart';

/// Geocodes free-text place names via Open-Meteo (no API key).
class GeocodingService {
  GeocodingService._();

  /// Returns the best-matching [AppLocation] for [query], or null when the
  /// query is too short, has no match, or the request fails.
  static Future<AppLocation?> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return null;
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final res = await dio.get<Map<String, dynamic>>(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {'name': q, 'count': 5, 'language': 'en'},
      );
      final results = res.data?['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is! Map) return null;
      final name = first['name'] as String? ?? q;
      final admin = first['admin1'] as String?;
      final country = first['country'] as String?;
      final label = [
        name,
        if (admin != null && admin.isNotEmpty) admin,
        if (country != null && country.isNotEmpty && country != admin) country,
      ].join(', ');
      return AppLocation(
        name: label,
        lat: (first['latitude'] as num).toDouble(),
        lon: (first['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
