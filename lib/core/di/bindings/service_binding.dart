import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/network/connectivity_manager.dart';
import 'package:onbit_v2_triple/core/services/data_service.dart';
import 'package:onbit_v2_triple/core/services/fcm_service.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';

/// ServiceBinding 관련 SignalBus 이벤트 클래스들
/// 서비스 초기화 이벤트
class ServiceInitializedEvent extends SignalEvent {
  final String service;
  
  ServiceInitializedEvent(this.service) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'service_initialized',
    'service': service,
    'sequentialId': sequentialId.toString(),
  };
}

/// 모든 서비스 초기화 이벤트
class AllServicesInitializedEvent extends SignalEvent {
  AllServicesInitializedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_services_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// 모든 서비스 해제 이벤트
class AllServicesDisposedEvent extends SignalEvent {
  AllServicesDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'all_services_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 서비스 초기화 에러 이벤트
class ServiceInitializationErrorEvent extends SignalEvent {
  final String service;
  final String message;
  final String error;
  
  ServiceInitializationErrorEvent({
    required this.service,
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'service_initialization_error',
    'service': service,
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 의존성 에러 이벤트
class DependencyErrorEvent extends SignalEvent {
  final String message;
  final String service;
  final String tag;
  
  DependencyErrorEvent({
    required this.message,
    required this.service,
    required this.tag,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'dependency_error',
    'message': message,
    'service': service,
    'tag': tag,
    'sequentialId': sequentialId.toString(),
  };
}

/// 핵심 서비스 의존성 주입 바인딩.
/// - [Get] 기반으로 [AppLogger], [MetricLogger], [SignalBus], [ConnectivityManager], [ApiService], [SocketService], [DataService], [FcmService] 등록.
/// - [InjectionContainer]에서 호출.
/// @see [InjectionContainer] for initialization.
class ServiceBinding extends Bindings {
  bool _isInitialized = false;

  @override
  void dependencies() {
    if (_isInitialized) {
      Get.find<AppLogger>(tag: DITags.loggerTag).logInfo('ServiceBinding already initialized, skipping');
      return;
    }

    _registerLogger();
    _registerMetricLogger();
    _registerSignalBus();
    _registerConnectivity();
    _registerApiService();
    _registerSocketService();
    _registerDataService();
    _registerFcmService();
    _isInitialized = true;
  }

  /// [AppLogger] 등록.
  void _registerLogger() {
    Get.putAsync<AppLogger>(
      () async {
        final logger = AppLogger();
        logger.logInfo('AppLogger initialized');
        Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
          'service_initializations',
          labels: {'service': 'AppLogger', 'status': 'success'},
        );
        Get.find<SignalBus>(tag: DITags.signalBusTag).fire(ServiceInitializedEvent('AppLogger'));
        return logger;
      },
      tag: DITags.loggerTag,
      permanent: true,
    );
  }

  /// [MetricLogger] 등록.
  void _registerMetricLogger() {
    Get.putAsync<MetricLogger>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = MetricLogger(logger: logger);
        logger.logInfo('MetricLogger initialized');
        Get.find<SignalBus>(tag: DITags.signalBusTag).fire(ServiceInitializedEvent('MetricLogger'));
        return metricLogger;
      },
      tag: DITags.metricLoggerTag,
      permanent: true,
    );
  }

  /// [SignalBus] 등록.
  void _registerSignalBus() {
    Get.putAsync<SignalBus>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final bus = SignalBus(logger: logger, metricLogger: metricLogger);
        logger.logInfo('SignalBus initialized');
        metricLogger.incrementCounter(
          'service_initializations',
          labels: {'service': 'SignalBus', 'status': 'success'},
        );
        bus.fire(ServiceInitializedEvent('SignalBus'));
        return bus;
      },
      tag: DITags.signalBusTag,
      permanent: true,
    );
  }

  /// [ConnectivityManager] 등록.
  void _registerConnectivity() {
    Get.putAsync<ConnectivityManager>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final connectivity = ConnectivityManager(
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        await connectivity.initialize();
        logger.logInfo('ConnectivityManager initialized');
        metricLogger.incrementCounter(
          'service_initializations',
          labels: {'service': 'ConnectivityManager', 'status': 'success'},
        );
        signalBus.fire(ServiceInitializedEvent('ConnectivityManager'));
        return connectivity;
      },
      tag: DITags.connectivityTag,
      permanent: true,
    );
  }

  /// [ApiService] 등록. (이전 ApiClient에서 변경됨)
  void _registerApiService() {
    Get.putAsync<ApiService>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final apiService = ApiService(
          platform: AppConfig.defaultPlatform,
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('ApiService initialized for ${AppConfig.defaultPlatform}');
        metricLogger.incrementCounter(
          'service_initializations',
          labels: {'service': 'ApiService', 'status': 'success'},
        );
        signalBus.fire(ServiceInitializedEvent('ApiService'));
        return apiService;
      },
      tag: DITags.apiServiceTag,
      permanent: true,
    );
  }

  /// [SocketService] 등록.
  void _registerSocketService() {
    Get.putAsync<SocketService>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final socket = SocketService(
          platform: AppConfig.defaultPlatform,
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('SocketService initialized for ${AppConfig.defaultPlatform}');
        metricLogger.incrementCounter(
          'service_initializations',
          labels: {'service': 'SocketService', 'status': 'success'},
        );
        signalBus.fire(ServiceInitializedEvent('SocketService'));
        return socket;
      },
      tag: DITags.socketServiceTag,
      permanent: true,
    );
  }

  /// [DataService] 등록.
  void _registerDataService() {
    Get.putAsync<DataService>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final socketService = await _get<SocketService>(DITags.socketServiceTag);
        final dataService = DataService(
          socketService: socketService,
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        logger.logInfo('DataService initialized');
        metricLogger.incrementCounter(
          'service_initializations',
          labels: {'service': 'DataService', 'status': 'success'},
        );
        signalBus.fire(ServiceInitializedEvent('DataService'));
        return dataService;
      },
      tag: DITags.dataServiceTag,
      permanent: true,
    );
  }

  /// [FcmService] 등록.
  void _registerFcmService() {
    Get.putAsync<FcmService>(
      () async {
        final logger = await _get<AppLogger>(DITags.loggerTag);
        final metricLogger = await _get<MetricLogger>(DITags.metricLoggerTag);
        final signalBus = await _get<SignalBus>(DITags.signalBusTag);
        final fcmService = FcmService(
          logger: logger,
          metricLogger: metricLogger,
          signalBus: signalBus,
        );
        try {
          await fcmService.setupFCM();
          logger.logInfo('FcmService initialized', metricLogger: metricLogger, signalBus: signalBus);
          metricLogger.incrementCounter(
            'service_initializations',
            labels: {'service': 'FcmService', 'status': 'success'},
          );
          signalBus.fire(ServiceInitializedEvent('FcmService'));
        } catch (e, stackTrace) {
          logger.logError('FcmService initialization failed', error: e, stackTrace: stackTrace, metricLogger: metricLogger, signalBus: signalBus);
          metricLogger.incrementCounter(
            'service_initializations',
            labels: {'service': 'FcmService', 'status': 'failure'},
          );
          
          // 객체지향 방식으로 시그널 이벤트 발송
          signalBus.fire(ServiceInitializationErrorEvent(
            service: 'FcmService',
            message: 'FcmService initialization failed',
            error: e.toString(),
          ));
        }
        return fcmService;
      },
      tag: DITags.fcmServiceTag,
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
    Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
      'dependency_errors',
      labels: {'service': T.toString(), 'tag': tag},
    );
    
    // 객체지향 방식으로 시그널 이벤트 발송
    Get.find<SignalBus>(tag: DITags.signalBusTag).fire(DependencyErrorEvent(
      message: error.message,
      service: T.toString(),
      tag: tag,
    ));
    
    throw error;
  }

  /// 모든 서비스 초기화.
  /// - 비동기 초기화 후 성공/실패 로그 및 메트릭 기록.
  /// @throws [DependencyException] 초기화 실패 시.
  static Future<void> initializeAll() async {
    try {
      final binding = ServiceBinding();
      binding.dependencies();
      await Future.wait([
        Get.putAsync(() async => Get.find<AppLogger>(tag: DITags.loggerTag)),
        Get.putAsync(() async => Get.find<MetricLogger>(tag: DITags.metricLoggerTag)),
        Get.putAsync(() async => Get.find<SignalBus>(tag: DITags.signalBusTag)),
        Get.putAsync(() async => Get.find<ConnectivityManager>(tag: DITags.connectivityTag)),
        Get.putAsync(() async => Get.find<ApiService>(tag: DITags.apiServiceTag)),
        Get.putAsync(() async => Get.find<SocketService>(tag: DITags.socketServiceTag)),
        Get.putAsync(() async => Get.find<DataService>(tag: DITags.dataServiceTag)),
        Get.putAsync(() async => Get.find<FcmService>(tag: DITags.fcmServiceTag)),
      ]);
      final logger = Get.find<AppLogger>(tag: DITags.loggerTag);
      final metricLogger = Get.find<MetricLogger>(tag: DITags.metricLoggerTag);
      final signalBus = Get.find<SignalBus>(tag: DITags.signalBusTag);
      logger.logInfo('All core services initialized ✅');
      metricLogger.incrementCounter('all_service_initializations', labels: {'status': 'success'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(AllServicesInitializedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to initialize all services: $e');
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
      metricLogger?.incrementCounter('all_service_initializations', labels: {'status': 'failure'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ServiceInitializationErrorEvent(
        service: 'AllServices',
        message: error.message,
        error: e.toString(),
      ));
      
      throw error;
    }
  }

  /// 모든 서비스 해제.
  /// - 등록된 서비스 인스턴스 제거.
  static void disposeAll() {
    try {
      Get.delete<SocketService>(tag: DITags.socketServiceTag);
      Get.delete<ApiService>(tag: DITags.apiServiceTag);
      Get.delete<ConnectivityManager>(tag: DITags.connectivityTag);
      Get.delete<DataService>(tag: DITags.dataServiceTag);
      Get.delete<FcmService>(tag: DITags.fcmServiceTag);
      Get.delete<SignalBus>(tag: DITags.signalBusTag);
      Get.delete<MetricLogger>(tag: DITags.metricLoggerTag);
      Get.delete<AppLogger>(tag: DITags.loggerTag);
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      logger?.logInfo('All core services disposed');
      metricLogger?.incrementCounter('all_service_disposals');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(AllServicesDisposedEvent());
    } catch (e, stackTrace) {
      final error = DependencyException(message: 'Failed to dispose all services: $e');
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      logger?.logError(error.message, error: e, stackTrace: stackTrace);
      Get.find<MetricLogger>(tag: DITags.metricLoggerTag)?.incrementCounter(
        'dependency_disposal_errors',
        labels: {'service': 'all'},
      );
    }
  }
}