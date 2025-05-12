import 'package:get_it/get_it.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';

final getIt = GetIt.instance;

/// 이벤트 클래스 - 메트릭 로거 초기화
class MetricLoggerInitializedEvent extends SignalEvent {
  MetricLoggerInitializedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'metric_logger_initialized',
    'message': 'MetricLogger initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 카운터 메트릭
class CounterMetricEvent extends SignalEvent {
  final String metric;
  final int increment;
  final String labels;
  
  CounterMetricEvent({
    required this.metric,
    required this.increment,
    required this.labels,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'counter_metric',
    'message': 'Metric: $metric incremented by $increment, labels: $labels',
    'metric': metric,
    'increment': increment,
    'labels': labels,
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 지연 시간 메트릭
class LatencyMetricEvent extends SignalEvent {
  final String metric;
  final int milliseconds;
  final String labels;
  
  LatencyMetricEvent({
    required this.metric,
    required this.milliseconds,
    required this.labels,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'latency_metric',
    'message': 'Metric: $metric latency $milliseconds ms, labels: $labels',
    'metric': metric,
    'milliseconds': milliseconds,
    'labels': labels,
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 메트릭 오류
class MetricErrorEvent extends SignalEvent {
  final String message;
  final Object? error;
  
  MetricErrorEvent({
    required this.message,
    this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'metric_error',
    'message': message,
    'error': error?.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 애플리케이션 메트릭 로깅 유틸리티.
/// - 성능, 에러, 이벤트 메트릭을 기록하고 [AppLogger]로 출력.
/// - [ApiService], [TradeProcessor], [SignalBus], [SocketService] 등에서 사용.
/// - 외부 모니터링 툴(Prometheus, StatsD) 연동 준비.
/// @see [AppLogger] for logging integration.
class MetricLogger {
  final AppLogger _logger;
  
  MetricLogger({required AppLogger logger}) : _logger = logger;
  
  /// 카운터 메트릭 증가.
  void incrementCounter(
    String name, {
    int increment = 1,
    Map<String, String>? labels,
    SignalBus? signalBus,
  }) {
    if (name.isEmpty) {
      final error = InvalidInputException(message: 'Metric name cannot be empty');
      _logger.logError(error.message, error: error);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MetricErrorEvent(
        message: error.message,
        error: error,
      ));
      
      throw error;
    }
    
    if (increment < 0) {
      final error = InvalidInputException(message: 'Increment cannot be negative: $increment');
      _logger.logError(error.message, error: error);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MetricErrorEvent(
        message: error.message,
        error: error,
      ));
      
      throw error;
    }
    
    final labelStr = labels != null && labels.isNotEmpty ? labels.toString() : 'none';
    final message = 'Metric: $name incremented by $increment, labels: $labelStr';
    _logger.logInfo(message);
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(CounterMetricEvent(
      metric: name,
      increment: increment,
      labels: labelStr,
    ));
  }
  
  /// 지연 시간 메트릭 기록.
  void recordLatency(
    String name,
    int milliseconds, {
    Map<String, String>? labels,
    SignalBus? signalBus,
  }) {
    if (name.isEmpty) {
      final error = InvalidInputException(message: 'Metric name cannot be empty');
      _logger.logError(error.message, error: error);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MetricErrorEvent(
        message: error.message,
        error: error,
      ));
      
      throw error;
    }
    
    if (milliseconds < 0) {
      final error = InvalidInputException(message: 'Milliseconds cannot be negative: $milliseconds');
      _logger.logError(error.message, error: error);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(MetricErrorEvent(
        message: error.message,
        error: error,
      ));
      
      throw error;
    }
    
    final labelStr = labels != null && labels.isNotEmpty ? labels.toString() : 'none';
    final message = 'Metric: $name latency $milliseconds ms, labels: $labelStr';
    _logger.logInfo(message);
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(LatencyMetricEvent(
      metric: name,
      milliseconds: milliseconds,
      labels: labelStr,
    ));
  }
  
  /// 메트릭 초기화.
  void initialize({SignalBus? signalBus}) {
    final message = 'MetricLogger initialized';
    _logger.logInfo(message);
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(MetricLoggerInitializedEvent());
  }
}

/// 메트릭 관련 예외.
class MetricException implements Exception {
  final String message;
  final Object? error;
  
  MetricException({required this.message, this.error});
}