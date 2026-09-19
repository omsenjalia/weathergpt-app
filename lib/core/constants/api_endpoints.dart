/// Every backend path the app calls. Legacy paths stay version-less for
/// backward compatibility; the proposed `/v2/...` WeatherNext contracts must
/// not be added here until the backend has implemented and versioned them.
abstract final class ApiEndpoints {
  static const chat = '/chat';
  static const weather = '/weather';
  static const health = '/health';
  static const diagnostics = '/dev';
  static const sandbox = '/dev/sandbox';
  static const advisory = '/advisory';
  static const historical = '/historical';
  static const comparison = '/comparison';
}
