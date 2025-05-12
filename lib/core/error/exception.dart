import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// WebSocket 연결/데이터 처리 관련 예외.
class SocketException implements Exception {
  final String message;
  final Object? error;
  final DateTime timestamp;

  SocketException({required this.message, this.error}) : timestamp = DateTime.now();

  @override
  String toString() => 'SocketException(timestamp: $timestamp, message: $message, error: $error)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'SocketException'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'SocketException', message: message));
  }
}

/// JSON 파싱 관련 예외.
class DataParsingException implements Exception {
  final String message;
  final Object? error;
  final DateTime timestamp;

  DataParsingException({required this.message, this.error}) : timestamp = DateTime.now();

  @override
  String toString() => 'DataParsingException(timestamp: $timestamp, message: $message, error: $error)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'DataParsingException'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'DataParsingException', message: message));
  }
}

/// REST API 호출 관련 공통 예외.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final DateTime timestamp;

  const ApiException({required this.message, this.statusCode}) : timestamp = DateTime.now();

  @override
  String toString() => 'ApiException(timestamp: $timestamp, statusCode: $statusCode, message: $message)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'ApiException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'ApiException', message: message));
  }
}

/// 서버 에러 (500번대 응답).
class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'ServerException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'ServerException', message: message));
  }
}

/// 인증 에러 (401, 403 응답).
class AuthException extends ApiException {
  const AuthException({required super.message, super.statusCode});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'AuthException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'AuthException', message: message));
  }
}

/// 리소스 미발견 에러 (404 응답).
class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.statusCode});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'NotFoundException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'NotFoundException', message: message));
  }
}

/// 네트워크 연결 에러.
class NetworkException extends ApiException {
  const NetworkException({required super.message, super.statusCode});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'NetworkException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'NetworkException', message: message));
  }
}

/// API 요청 초과 에러 (429 응답).
class RateLimitException extends ApiException {
  const RateLimitException({required super.message, super.statusCode});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'RateLimitException', 'statusCode': statusCode?.toString() ?? 'none'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'RateLimitException', message: message));
  }
}

/// 잘못된 입력 에러.
class InvalidInputException implements Exception {
  final String message;
  final DateTime timestamp;

  const InvalidInputException({required this.message}) : timestamp = DateTime.now();

  @override
  String toString() => 'InvalidInputException(timestamp: $timestamp, message: $message)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'InvalidInputException'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'InvalidInputException', message: message));
  }
}

/// 의존성 주입 관련 에러.
class DependencyException implements Exception {
  final String message;
  final Object? error;
  final DateTime timestamp;

  DependencyException({required this.message, this.error}) : timestamp = DateTime.now();

  @override
  String toString() => 'DependencyException(timestamp: $timestamp, message: $message, error: $error)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'DependencyException'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'DependencyException', message: message));
  }
}

/// 타임아웃 에러.
class TimeoutException implements Exception {
  final String message;
  final DateTime timestamp;

  TimeoutException({required this.message}) : timestamp = DateTime.now();

  @override
  String toString() => 'TimeoutException(timestamp: $timestamp, message: $message)';

  /// 예외 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('exceptions_thrown', labels: {'type': 'TimeoutException'});
    signalBus?.fire(ExceptionThrownEvent(exceptionType: 'TimeoutException', message: message));
  }
}

/// SignalBus 이벤트 클래스.
class ExceptionThrownEvent extends SignalEvent {
  final String exceptionType; // 'type'에서 'exceptionType'으로 변경
  final String message;
  
  ExceptionThrownEvent({required this.exceptionType, required this.message})
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'exception_thrown', // 이벤트 타입
    'exceptionType': exceptionType, // 예외 타입
    'message': message,
    'errorType': 'exception',
    'sequentialId': sequentialId.toString(),
  };
}