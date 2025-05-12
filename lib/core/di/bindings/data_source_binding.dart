import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/api/api_service.dart'; // ApiService import 추가
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';
import 'package:onbit_v2_triple/data/datasources/market_data_source.dart';
import 'package:onbit_v2_triple/data/datasources/real_market_data_source.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';

/// SignalBus 이벤트 클래스 - 데이터소스 초기화
class DataSourceInitializedEvent extends SignalEvent {
  final String source;
  
  DataSourceInitializedEvent(this.source)
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'data_source_initialized',
    'source': source,
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 데이터소스 초기화
class AllDataSourcesInitializedEvent extends SignalEvent {
  AllDataSourcesInitializedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_data_sources_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 데이터소스 해제
class AllDataSourcesDisposedEvent extends SignalEvent {
  AllDataSourcesDisposedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_data_sources_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 데이터소스 오류
class DataSourceErrorEvent extends SignalEvent {
  final String source;
  final String message;
  final String error;
  
  DataSourceErrorEvent({
    required this.source,
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'data_source_error',
    'source': source,
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터 소스 의존성 주입 바인딩.
/// - [Get] 기반으로 [SocketTradeSource], [RealMarketDataSource] 등록.
/// - [InjectionContainer]에서 호출.
/// @see [InjectionContainer] for initialization.
class DataSourceBinding extends Bindings {
  bool _isInitialized = false;

  @override
  void dependencies() {
    if (_isInitialized) {
      Get.find<AppLogger>(tag: DITags.loggerTag).logInfo('DataSourceBinding already initialized, skipping');
      return;
    }

    _registerSocketTradeSource();
    _registerMarketDataSource();
    _isInitialized = true;
  }

  /// [SocketTradeSource] 등록.
  void _registerSocketTradeSource() {
    Get.putAsync<SocketTradeSource>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final socketService = await _get<SocketService>(DITags.socketServiceTag);

        final source = SocketTradeSource(
          socketService: socketService,
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('SocketTradeSource initialized');
        metricLogger.incrementCounter(
          'data_source_initializations',
          labels: {'source': 'SocketTradeSource', 'status': 'success'},
        );
        signalBus.fire(DataSourceInitializedEvent('SocketTradeSource'));
        return source;
      },
      tag: DITags.socketTradeSourceTag,
      permanent: true,
    );
  }

  /// [MarketDataSource] 등록 ([RealMarketDataSource] 구현체).
  void _registerMarketDataSource() {
    Get.putAsync<MarketDataSource>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final apiService = await _get<ApiService>(DITags.apiServiceTag); // ApiClient에서 ApiService로 변경

        final source = RealMarketDataSource(
          apiService: apiService, // apiClient에서 apiService로 변경
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('RealMarketDataSource initialized');
        metricLogger.incrementCounter(
          'data_source_initializations',
          labels: {'source': 'RealMarketDataSource', 'status': 'success'},
        );
        signalBus.fire(DataSourceInitializedEvent('RealMarketDataSource'));
        return source;
      },
      tag: DITags.marketDataSourceTag,
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
    Get.find<MetricLogger>(tag: DITags.metricLoggerTag).incrementCounter( // null 체크 불필요
      'dependency_errors',
      labels: {'service': T.toString(), 'tag': tag},
    );
    
    // 객체지향 방식으로 시그널 이벤트 발송
    Get.find<SignalBus>(tag: DITags.signalBusTag).fire(DataSourceErrorEvent(
      source: T.toString(),
      message: error.message,
      error: error.toString(),
    ));
    
    throw error;
  }

  /// 모든 데이터 소스 초기화.
  /// - 비동기 초기화 후 성공/실패 로그 및 메트릭 기록.
  /// @throws [DependencyException] 초기화 실패 시.
  static Future<void> initializeAll() async {
    try {
      final binding = DataSourceBinding();
      binding.dependencies();
      await Future.wait([
        Get.putAsync(() async => Get.find<SocketTradeSource>(tag: DITags.socketTradeSourceTag)),
        Get.putAsync(() async => Get.find<MarketDataSource>(tag: DITags.marketDataSourceTag)),
      ]);
      final logger = Get.find<AppLogger>(tag: DITags.loggerTag);
      final metricLogger = Get.find<MetricLogger>(tag: DITags.metricLoggerTag);
      final signalBus = Get.find<SignalBus>(tag: DITags.signalBusTag);
      logger.logInfo('All data sources initialized ✅');
      metricLogger.incrementCounter('all_data_source_initializations', labels: {'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(AllDataSourcesInitializedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to initialize all data sources: $e');
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
      metricLogger?.incrementCounter('all_data_source_initializations', labels: {'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(DataSourceErrorEvent(
        source: 'AllDataSources',
        message: error.message,
        error: e.toString(),
      ));
      
      throw error;
    }
  }

  /// 모든 데이터 소스 해제.
  /// - 등록된 데이터 소스 인스턴스 제거.
  static void disposeAll() {
    try {
      Get.delete<SocketTradeSource>(tag: DITags.socketTradeSourceTag);
      Get.delete<MarketDataSource>(tag: DITags.marketDataSourceTag);
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      logger?.logInfo('All data sources disposed');
      metricLogger?.incrementCounter('all_data_source_disposals');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(AllDataSourcesDisposedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to dispose all data sources: $e');
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      logger?.logError(error.message, error: e, stackTrace: stackTrace);
      Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
        'dependency_disposal_errors',
        labels: {'source': 'all'},
      );
    }
  }
}