import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/network/connectivity_manager.dart';
import 'package:onbit_v2_triple/data/datasources/market_data_source.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/data/processors/trade_processor.dart';
import 'package:onbit_v2_triple/data/repositories/trade_repository_impl.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';

/// SignalBus 이벤트 클래스 - 레포지토리 초기화
class RepositoryInitializedEvent extends SignalEvent {
  final String repository;
  
  RepositoryInitializedEvent(this.repository)
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'repository_initialized',
    'repository': repository,
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 레포지토리 초기화
class AllRepositoriesInitializedEvent extends SignalEvent {
  AllRepositoriesInitializedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_repositories_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 모든 레포지토리 해제
class AllRepositoriesDisposedEvent extends SignalEvent {
  AllRepositoriesDisposedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_repositories_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 레포지토리 오류
class RepositoryErrorEvent extends SignalEvent {
  final String repository;
  final String message;
  final String error;
  
  RepositoryErrorEvent({
    required this.repository,
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'repository_error',
    'repository': repository,
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 리포지토리 의존성 주입 바인딩.
/// - [Get] 기반으로 [TradeRepository] ([TradeRepositoryImpl]) 등록.
/// - [InjectionContainer]에서 호출.
/// @see [InjectionContainer] for initialization.
class RepositoryBinding extends Bindings {
  bool _isInitialized = false;

  @override
  void dependencies() {
    if (_isInitialized) {
      Get.find<AppLogger>(tag: DITags.loggerTag).logInfo('RepositoryBinding already initialized, skipping');
      return;
    }

    _registerTradeRepository();
    _isInitialized = true;
  }

  /// [TradeRepository] 등록 ([TradeRepositoryImpl] 구현체).
  void _registerTradeRepository() {
    Get.putAsync<TradeRepository>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final socketTradeSource = await _get<SocketTradeSource>(DITags.socketTradeSourceTag);
        final marketDataSource = await _get<MarketDataSource>(DITags.marketDataSourceTag);
        final tradeProcessor = await _get<TradeProcessor>(DITags.tradeProcessorTag);
        final connectivityManager = await _get<ConnectivityManager>(DITags.connectivityTag);

        final repository = TradeRepositoryImpl(
          socketTradeSource: socketTradeSource,
          marketDataSource: marketDataSource,
          tradeProcessor: tradeProcessor,
          connectivityManager: connectivityManager,
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('TradeRepository initialized');
        metricLogger.incrementCounter(
          'repository_initializations',
          labels: {'repository': 'TradeRepository', 'status': 'success'},
        );
        signalBus.fire(RepositoryInitializedEvent('TradeRepository'));
        return repository;
      },
      tag: DITags.tradeRepositoryTag,
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
    Get.find<SignalBus>(tag: DITags.signalBusTag).fire(RepositoryErrorEvent(
      repository: T.toString(),
      message: error.message,
      error: error.toString(),
    ));
    
    throw error;
  }

  /// 모든 리포지토리 초기화.
  /// - 비동기 초기화 후 성공/실패 로그 및 메트릭 기록.
  /// @throws [DependencyException] 초기화 실패 시.
  static Future<void> initializeAll() async {
    try {
      final binding = RepositoryBinding();
      binding.dependencies();
      await Get.putAsync(() async => Get.find<TradeRepository>(tag: DITags.tradeRepositoryTag));
      final logger = Get.find<AppLogger>(tag: DITags.loggerTag);
      final metricLogger = Get.find<MetricLogger>(tag: DITags.metricLoggerTag);
      final signalBus = Get.find<SignalBus>(tag: DITags.signalBusTag);
      logger.logInfo('All repositories initialized ✅');
      metricLogger.incrementCounter('all_repository_initializations', labels: {'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(AllRepositoriesInitializedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to initialize all repositories: $e');
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
      metricLogger?.incrementCounter('all_repository_initializations', labels: {'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(RepositoryErrorEvent(
        repository: 'AllRepositories',
        message: error.message,
        error: e.toString(),
      ));
      
      throw error;
    }
  }

  /// 모든 리포지토리 해제.
  /// - 등록된 리포지토리 인스턴스 제거.
  static void disposeAll() {
    try {
      Get.delete<TradeRepository>(tag: DITags.tradeRepositoryTag);
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      logger?.logInfo('All repositories disposed');
      metricLogger?.incrementCounter('all_repository_disposals');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(AllRepositoriesDisposedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to dispose all repositories: $e');
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      logger?.logError(error.message, error: e, stackTrace: stackTrace);
      Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
        'dependency_disposal_errors',
        labels: {'repository': 'all'},
      );
    }
  }
}