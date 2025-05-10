import 'dart:async';
import 'package:dio/dio.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/config/env_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:retry/retry.dart';

class ApiClient {
  final Dio _dio;
  final AppLogger _logger;
  final ExchangePlatform platform;
  final ExchangeConfig _config;

  static const _connectTimeout = Duration(seconds: 5);
  static const _receiveTimeout = Duration(seconds: 10);
  static const _sendTimeout = Duration(seconds: 5);

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  ApiClient({
    required this.platform,
    required AppLogger logger,
    Dio? dio,
  })  : _logger = logger,
        _config = ExchangeConfig.getConfig(platform),
        _dio = dio ?? Dio() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options
      ..baseUrl = _config.baseUrl
      ..connectTimeout = _connectTimeout
      ..receiveTimeout = _receiveTimeout
      ..sendTimeout = _sendTimeout
      ..headers = const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.logInfo('API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.logInfo('API Response: ${response.statusCode} [${response.requestOptions.path}]');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.logError('API Error: ${error.response?.statusCode} [${error.requestOptions.path}]', error: error);
          handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await retry(
        () => _dio.get(path, queryParameters: queryParameters).timeout(_receiveTimeout),
        retryIf: _shouldRetry,
        maxAttempts: _maxRetries,
        delayFactor: _retryDelay,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw _handleGenericError(e);
    }
  }

  Future<List<String>> fetchAllSymbols() async {
    try {
      final data = await get(_config.symbolsEndpoint);
      List<dynamic> raw;

      switch (platform) {
        case ExchangePlatform.upbit:
          raw = data;
          break;
        case ExchangePlatform.binance:
          raw = data['symbols'];
          break;
        case ExchangePlatform.bybit:
          raw = data['result']['list'];
          break;
        case ExchangePlatform.bithumb:
          raw = (data['data'] as Map<String, dynamic>)
              .entries
              .where((e) => e.key != 'date')
              .map((e) => {'market': e.key})
              .toList();
          break;
      }

      return raw
          .map((item) => item[_config.symbolKey])
          .where((s) => s != null && s.toString().contains(_config.marketPrefix))
          .map((s) => s.toString())
          .toList();
    } catch (e) {
      _logger.logError('Failed to fetch market symbols', error: e);
      throw ApiException(message: 'Failed to fetch market symbols: $e');
    }
  }

  bool _shouldRetry(Exception e) {
    return e is TimeoutException || (e is DioException && (
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.response?.statusCode == null ||
      (e.response?.statusCode ?? 500) >= 500
    ));
  }

  Exception _handleDioError(DioException e) {
    final msg = e.response?.data?.toString() ?? e.message ?? 'Unknown error';
    final code = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException('Request timed out');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'Connection error: $msg');
      case DioExceptionType.badResponse:
        if (code == 401 || code == 403) return AuthException(message: 'Unauthorized: $msg');
        if (code == 404) return NotFoundException(message: 'Not Found: $msg');
        if (code != null && code >= 500) return ServerException(message: 'Server Error: $msg');
        return ApiException(message: 'API Error: $msg');
      default:
        return ApiException(message: 'Unhandled Dio error: $msg');
    }
  }

  Exception _handleGenericError(dynamic e) {
    return e is TimeoutException ? e : ApiException(message: 'Unexpected error: $e');
  }

  void dispose() {
    _dio.close();
    _logger.logInfo('ApiClient disposed');
  }
}
