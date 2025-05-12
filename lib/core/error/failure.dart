import 'package:equatable/equatable.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// 실패 발생 이벤트 클래스
class FailureOccurredEvent extends SignalEvent {
  final String failureType;
  final String message;
  
  FailureOccurredEvent({
    required this.failureType,
    required this.message,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'failure_occurred',
    'failure_type': failureType,
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// 도메인 레이어의 에러를 나타내는 추상 클래스.
/// - [TradeRepositoryImpl] 및 기타 도메인 로직에서 사용.
/// - [Equatable]로 비교 최적화.
/// @see [Exception] for infrastructure layer errors.
abstract class Failure extends Equatable {
  final String message;
  final Object? error;
  final DateTime timestamp;

  const Failure({required this.message, this.error}) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [message, error, timestamp];

  @override
  String toString() => '$runtimeType(timestamp: $timestamp, message: $message, error: $error)';

  /// 실패 로깅 및 메트릭 기록.
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': runtimeType.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: runtimeType.toString(),
      message: message,
    ));
  }
}

/// 서버 에러 (API 500번대 응답).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'ServerFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'ServerFailure',
      message: message,
    ));
  }
}

/// WebSocket 연결/데이터 처리 에러.
class SocketFailure extends Failure {
  const SocketFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'SocketFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'SocketFailure',
      message: message,
    ));
  }
}

/// 네트워크 연결 에러.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'NetworkFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'NetworkFailure',
      message: message,
    ));
  }
}

/// API 요청 초과 에러 (429 응답).
class RateLimitFailure extends Failure {
  const RateLimitFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'RateLimitFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'RateLimitFailure',
      message: message,
    ));
  }
}

/// 잘못된 입력 에러.
class InvalidInputFailure extends Failure {
  const InvalidInputFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'InvalidInputFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'InvalidInputFailure',
      message: message,
    ));
  }
}

/// 의존성 주입 에러.
class DependencyFailure extends Failure {
  const DependencyFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'DependencyFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'DependencyFailure',
      message: message,
    ));
  }
}

/// 타임아웃 에러.
class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'TimeoutFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'TimeoutFailure',
      message: message,
    ));
  }
}

/// 인증 에러 (401, 403 응답).
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'AuthFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'AuthFailure',
      message: message,
    ));
  }
}

/// 리소스 미발견 에러 (404 응답).
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'NotFoundFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'NotFoundFailure',
      message: message,
    ));
  }
}

/// 데이터 파싱 에러.
class DataParsingFailure extends Failure {
  const DataParsingFailure({required super.message, super.error});

  @override
  void log({MetricLogger? metricLogger, SignalBus? signalBus}) {
    metricLogger?.incrementCounter('failures_occurred', labels: {'type': 'DataParsingFailure'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(FailureOccurredEvent(
      failureType: 'DataParsingFailure',
      message: message,
    ));
  }
}