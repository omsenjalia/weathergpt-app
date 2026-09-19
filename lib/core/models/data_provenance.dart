/// Where a rendered weather value came from, and how fresh it is.
///
/// The app never *chooses* a provider — the backend owns
/// IMD → WeatherNext → AccuWeather → Open-Meteo selection. This model only
/// records what the backend reported so the UI can attribute a source, show a
/// run/freshness stamp and say "source not reported" instead of guessing.
///
/// Pure Dart (no Flutter imports) so parsing is unit-testable in isolation.
library;

import 'json_values.dart';

/// Known provider identifiers. Anything else is kept verbatim as [raw].
enum WeatherProvider { imd, weathernext, accuweather, openMeteo, unknown }

WeatherProvider providerFromName(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'imd':
      return WeatherProvider.imd;
    case 'weathernext':
    case 'google':
    case 'google_weathernext':
      return WeatherProvider.weathernext;
    case 'accuweather':
      return WeatherProvider.accuweather;
    case 'open-meteo':
    case 'openmeteo':
    case 'open_meteo':
      return WeatherProvider.openMeteo;
    default:
      return WeatherProvider.unknown;
  }
}

/// Source, run and freshness metadata attached to one rendered payload.
class WeatherProvenance {
  const WeatherProvenance({
    this.source,
    this.product,
    this.runId,
    this.issuedAtUtc,
    this.retrievedAtUtc,
    this.timezoneId,
    this.schemaVersion,
    this.fallback = false,
    this.missingFields = const [],
    this.horizonHours,
  });

  /// Provenance carrying no claims at all — used when the backend reported
  /// nothing, so the UI can render an honest "not reported" state.
  static const WeatherProvenance none = WeatherProvenance();

  final String? source;
  final String? product;
  final String? runId;

  /// When the data was produced (model run / analysis time), in UTC.
  final DateTime? issuedAtUtc;

  /// When the backend retrieved it, in UTC.
  final DateTime? retrievedAtUtc;

  /// IANA timezone of the location the times refer to, when reported.
  final String? timezoneId;
  final String? schemaVersion;

  /// True when the backend degraded to a lower-priority provider.
  final bool fallback;

  /// Fields the backend explicitly could not supply. Presence here means the
  /// UI must show an unavailable state rather than a plausible value.
  final List<String> missingFields;

  /// Forecast horizon actually available in this payload, when reported.
  final int? horizonHours;

  WeatherProvider get provider => providerFromName(source);
  bool get hasSource => source != null && source!.isNotEmpty;

  /// True when the backend told us this specific field is unavailable.
  bool isMissing(String field) => missingFields.contains(field);

  /// The newest stamp available, or `null` when the backend reported none.
  DateTime? get effectiveAtUtc => issuedAtUtc ?? retrievedAtUtc;

  /// Whether the payload is older than [maxAge] as of [nowUtc].
  ///
  /// Returns `false` when no timestamp was reported: an unknown age is not the
  /// same as a known-stale payload, and the UI labels those differently.
  bool isStaleAt(DateTime nowUtc, {Duration maxAge = const Duration(hours: 6)}) {
    final stamp = effectiveAtUtc;
    if (stamp == null) return false;
    return nowUtc.difference(stamp) > maxAge;
  }

  bool get ageUnknown => effectiveAtUtc == null;

  /// Builds provenance from a decoded `/weather`-style payload, tolerating both
  /// today's responses (which may report nothing) and the additive metadata
  /// described in the backend contract. Unknown additive keys are ignored.
  factory WeatherProvenance.fromJson(Map<String, dynamic> data) {
    final meta = jsonMap(data['meta']) ?? const <String, dynamic>{};

    /// Reads the first populated key from the payload, then from its `meta`.
    String? firstString(List<String> keys) {
      for (final key in keys) {
        final direct = jsonString(data[key]);
        if (direct != null) return direct;
        final nested = jsonString(meta[key]);
        if (nested != null) return nested;
      }
      return null;
    }

    bool? firstBool(List<String> keys) {
      for (final key in keys) {
        final direct = jsonBool(data[key]);
        if (direct != null) return direct;
        final nested = jsonBool(meta[key]);
        if (nested != null) return nested;
      }
      return null;
    }

    Object? firstValue(List<String> keys) {
      for (final key in keys) {
        if (data[key] != null) return data[key];
        if (meta[key] != null) return meta[key];
      }
      return null;
    }

    final source = firstString(
        const ['source', 'provider', 'data_source', 'primary_source']);
    final fallbackFlag =
        firstBool(const ['fallback', 'degraded', 'is_fallback']) ?? false;

    final missingRaw =
        jsonList(firstValue(const ['missing_fields', 'missing', 'unavailable']));
    final nullReasons =
        jsonMap(firstValue(const ['null_reasons', 'unavailable_reasons']));

    final missing = <String>{
      for (final item in missingRaw)
        if (jsonString(item) != null) jsonString(item)!,
      if (nullReasons != null) ...nullReasons.keys,
    }.toList()..sort();

    return WeatherProvenance(
      source: source,
      product: firstString(const ['product', 'dataset']),
      runId: firstString(const ['run_id', 'run', 'model_run']),
      issuedAtUtc: jsonUtc(firstString(
          const ['issued_at', 'run_time', 'analysis_time', 'valid_time'])),
      retrievedAtUtc: jsonUtc(
          firstString(const ['retrieved_at', 'fetched_at', 'updated_at'])),
      timezoneId: firstString(const ['timezone', 'timezone_id']),
      schemaVersion:
          firstString(const ['schema_version', 'contract_version']),
      fallback: fallbackFlag,
      missingFields: missing,
      horizonHours: jsonInt(firstValue(const ['horizon_hours', 'horizon'])),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherProvenance &&
      other.source == source &&
      other.product == product &&
      other.runId == runId &&
      other.issuedAtUtc == issuedAtUtc &&
      other.retrievedAtUtc == retrievedAtUtc &&
      other.timezoneId == timezoneId &&
      other.schemaVersion == schemaVersion &&
      other.fallback == fallback &&
      other.horizonHours == horizonHours &&
      _sameList(other.missingFields, missingFields);

  @override
  int get hashCode => Object.hash(source, product, runId, issuedAtUtc,
      retrievedAtUtc, timezoneId, schemaVersion, fallback, horizonHours);

  @override
  String toString() =>
      'WeatherProvenance(source: $source, product: $product, run: $runId, '
      'issued: $issuedAtUtc, fallback: $fallback, missing: $missingFields)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
