import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/data/processors/trade_processor.dart';

/// SignalBus 이벤트 클래스 - 프로세서 초기화
class ProcessorInitializedEvent extends SignalEvent {
  final String processor;
  
  ProcessorInitializedEvent(this.processor)
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'processor_initialized',
    'processor': processor,
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 프로세서 초기화
class AllProcessorsInitializedEvent extends SignalEvent {
  AllProcessorsInitializedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_processors_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 프로세서 해제
class AllProcessorsDisposedEvent extends SignalEvent {
  AllProcessorsDisposedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_processors_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 프로세서 오류
class ProcessorErrorEvent extends SignalEvent {
  final String processor;
  final String message;
  final String error;
  
  ProcessorErrorEvent({
    required this.processor,
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'processor_error',
    'processor': processor,
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 프로세서 의존성 주입 바인딩.
/// - [Get] 기반으로 [TradeProcessor] 등록.
/// - [InjectionContainer]에서 호출.
/// @see [InjectionContainer] for initialization.
class ProcessorBinding extends Bindings {
  bool _isInitialized = false;

  @override
  void dependencies() {
    if (_isInitialized) {
      Get.find<AppLogger>(tag: DITags.loggerTag).logInfo('ProcessorBinding already initialized, skipping');
      return;
    }

    _registerTradeProcessor();
    _isInitialized = true;
  }

  /// [TradeProcessor] 등록.
  void _registerTradeProcessor() {
    Get.putAsync<TradeProcessor>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);

        final processor = TradeProcessor(
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('TradeProcessor initialized');
        metricLogger.incrementCounter(
          'processor_initializations',
          labels: {'processor': 'TradeProcessor', 'status': 'success'},
        );
        signalBus.fire(ProcessorInitializedEvent('TradeProcessor'));
        return processor;
      },
      tag: DITags.tradeProcessorTag,
      permanent: true,
    );
  }

  /// 의존성 가져오기.
  /// - [tag]: 서비스 태그.
  /// @throws [DependencyException] 서비스 미등록 시.
  Future<T> _get<T>(String tag) async {
    if (Get.isRegistered<T>(tag: tag)) {
      return Get.find<T>(tag: tag);
    }
    final error = DependencyException(message: 'Service $T with tag $tag not registered');
    Get.find<AppLogger>(tag: DITags.loggerTag).logError(error.message, error: error);
    Get.find<MetricLogger>(tag: DITags.metricLoggerTag).incrementCounter(
      'dependency_errors',
      labels: {'service': T.toString(), 'tag': tag},
    );
    
    // 객체지향 방식으로 시그널 이벤트 발송
    Get.find<SignalBus>(tag: DITags.signalBusTag).fire(ProcessorErrorEvent(
      processor: T.toString(),
      message: error.message,
      error: error.toString(),
    ));
    
    throw error;
  }

  /// 모든 프로세서 초기화.
  /// - 비동기 초기화 후 성공/실패 로그 및 메트릭 기록.
  /// @throws [DependencyException] 초기화 실패 시.
  static Future<void> initializeAll() async {
    try {
      final binding = ProcessorBinding();
      binding.dependencies();
      await Get.putAsync(() async => Get.find<TradeProcessor>(tag: DITags.tradeProcessorTag));
      final logger = Get.find<AppLogger>(tag: DITags.loggerTag);
      final metricLogger = Get.find<MetricLogger>(tag: DITags.metricLoggerTag);
      final signalBus = Get.find<SignalBus>(tag: DITags.signalBusTag);
      logger.logInfo('All processors initialized ✅');
      metricLogger.incrementCounter('all_processor_initializations', labels: {'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(AllProcessorsInitializedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to initialize all processors: $e');
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      logger?.logError(error.message, error: e, stackTrace: stackTrace);
      metricLogger?.incrementCounter('all_processor_initializations', labels: {'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ProcessorErrorEvent(
        processor: 'AllProcessors',
        message: error.message,
        error: e.toString(),
      ));
      
      throw error;
    }
  }

  /// 모든 프로세서 해제.
  /// - 등록된 프로세서 인스턴스 제거.
  static void disposeAll() {
    try {
      Get.delete<TradeProcessor>(tag: DITags.tradeProcessorTag);
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      logger?.logInfo('All processors disposed');
      metricLogger?.incrementCounter('all_processor_disposals');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(AllProcessorsDisposedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to dispose all processors: $e');
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      logger?.logError(error.message, error: e, stackTrace: stackTrace);
      Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
        'dependency_disposal_errors',
        labels: {'processor': 'all'},
      );
    }
  }
}