import 'package:logger/logger.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// AppLogger 관련 SignalBus 이벤트 클래스들
/// 일반 로그 이벤트
class LogEvent extends SignalEvent {
  final String level;
  final String message;
  
  LogEvent({
    required this.level,
    required this.message,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'level': level,
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// 에러 로그 이벤트
class ErrorLogEvent extends SignalEvent {
  final String message;
  
  ErrorLogEvent(this.message) 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'level': 'error',
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// JSON 로그 이벤트
class JsonLogEvent extends SignalEvent {
  final String event;
  final Map<String, dynamic> data;
  
  JsonLogEvent({
    required this.event,
    required this.data,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'level': 'json',
    'event': event,
    'data': data,
    'sequentialId': sequentialId.toString(),
  };
}

/// 애플리케이션 로깅 유틸리티.
/// - [Logger] 패키지 기반으로 정보, 경고, 에러 로그 처리.
/// - [TradeRepositoryImpl], [ApiService], [TradeProcessor] 등에서 사용.
/// - [AppConfig]로 환경별 로깅 설정 참조.
/// @see [Logger] for underlying logging mechanism.
class AppLogger {
  final Logger _logger;
  final bool _isDebugMode;

  AppLogger({
    Logger? logger,
    bool isDebugMode = AppConfig.isDebugMode,
  })  : _logger = logger ?? Logger(
          printer: PrettyPrinter(
            methodCount: isDebugMode ? 2 : 0,
            errorMethodCount: isDebugMode ? 8 : 2,
            printTime: true,
          ),
        ),
        _isDebugMode = isDebugMode;

  /// 정보 로그 출력.
  void logInfo(String message, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (message.isEmpty) {
      _logError('Log message cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    _logger.i(message);
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'info'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(LogEvent(
      level: 'info',
      message: message,
    ));
  }

  /// 경고 로그 출력.
  void logWarning(String message, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (message.isEmpty) {
      _logError('Log message cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    _logger.w(message);
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'warning'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(LogEvent(
      level: 'warning',
      message: message,
    ));
  }

  /// 디버그 로그 출력 (디버그 모드에서만).
  void logDebug(String message, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (!_isDebugMode) return;
    if (message.isEmpty) {
      _logError('Log message cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    _logger.d(message);
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'debug'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(LogEvent(
      level: 'debug',
      message: message,
    ));
  }

  /// 상세 로그 출력 (디버그 모드에서만).
  void logVerbose(String message, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    if (!_isDebugMode) return;
    if (message.isEmpty) {
      _logError('Log message cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    _logger.v(message);
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'verbose'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(LogEvent(
      level: 'verbose',
      message: message,
    ));
  }

  /// 에러 로그 출력.
  void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    if (message.isEmpty) {
      _logError('Log message cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    final errorMsg = error != null ? '$message, Error: $error' : message;
    final stackMsg = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    _logger.e('$errorMsg$stackMsg');
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'error'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(ErrorLogEvent(errorMsg));
  }

  /// JSON 형식 로그 출력.
  void logJson(
    String event,
    Map<String, dynamic> data, {
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    if (event.isEmpty) {
      _logError('Event name cannot be empty', metricLogger: metricLogger, signalBus: signalBus);
      return;
    }
    final message = '[JSON] $event: ${data.toString()}';
    _logger.i(message);
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'json'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(JsonLogEvent(
      event: event,
      data: data,
    ));
  }

  /// 내부 에러 로그 출력.
  void _logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    final errorMsg = error != null ? '$message, Error: $error' : message;
    final stackMsg = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    _logger.e('$errorMsg$stackMsg');
    metricLogger?.incrementCounter('log_calls', labels: {'level': 'error'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(ErrorLogEvent(errorMsg));
  }

  /// 리소스 정리.
  void dispose() {
    _logger.close();
  }
}