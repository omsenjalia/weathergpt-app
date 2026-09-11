import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

sealed class AppApiError implements Exception {
  const AppApiError(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkError extends AppApiError {
  const NetworkError(super.message);
}

class ServerError extends AppApiError {
  const ServerError(super.message);
}

class ValidationError extends AppApiError {
  const ValidationError(super.message);
}

/// The sole HTTP entry point. Keep API keys on the server, never in this app.
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: (dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8888')
          .replaceFirst(RegExp(r'/+$'), ''),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.headers['Accept-Language'] = _language;
      handler.next(options);
    }));
  }
  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  String _language = 'en';
  void setLanguage(String value) => _language = value;

  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return response.data ?? const {};
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? const {};
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  AppApiError _map(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkError(
        'Could not reach WeatherGPT at $baseUrl. '
        'Check BACKEND_URL and that the API is running.',
      );
    }
    final status = error.response?.statusCode ?? 0;
    if (status == 400 || status == 422) {
      return ValidationError(
          _detail(error) ?? 'Please check the requested weather data.');
    }
    return ServerError(
      _detail(error) ??
          'WeatherGPT is temporarily unavailable (HTTP $status). Please try again.',
    );
  }

  String? _detail(DioException error) {
    final data = error.response?.data;
    return data is Map && data['detail'] != null ? '${data['detail']}' : null;
  }
}
