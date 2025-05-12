import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/di/bindings/data_source_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/processor_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/repository_binding.dart';
import 'package:onbit_v2_triple/core/di/bindings/service_binding.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// 이벤트 클래스 - 인젝션 컨테이너 초기화
class InjectionContainerInitializedEvent extends SignalEvent {
  InjectionContainerInitializedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'injection_container_initialized',
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 인젝션 컨테이너 에러
class InjectionContainerErrorEvent extends SignalEvent {
  final String message;
  final String error;
  
  InjectionContainerErrorEvent({
    required this.message,
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'injection_container_error',
    'message': message,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 인젝션 컨테이너 시작
class InjectionContainerStartedEvent extends SignalEvent {
  InjectionContainerStartedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'injection_container_started',
    'sequentialId': sequentialId.toString(),
  };
}

/// 이벤트 클래스 - 인젝션 컨테이너 완료
class InjectionContainerCompletedEvent extends SignalEvent {
  final int timeMs;
  
  InjectionContainerCompletedEvent(this.timeMs)
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'injection_container_completed',
    'timeMs': timeMs.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 애플리케이션 의존성 주입 컨테이너.
/// - [Get] 기반 DI 초기화 진입점.
/// - [ServiceBinding], [DataSourceBinding], [ProcessorBinding], [RepositoryBinding] 초기화.
/// @see [AppConfig] for environment configuration.
class InjectionContainer {
  static bool _isInitialized = false;

  /// 모든 의존성 초기화.
  /// - 서비스, 데이터 소스, 프로세서, 리포지토리 순으로 초기화.
  /// @throws [Exception] 초기화 실패 시.
  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    print('🚀 Starting dependency injection...');

    try {
      // 핵심 서비스 초기화
      await ServiceBinding.initializeAll();
      final logger = Get.find<AppLogger>(tag: DITags.loggerTag);
      final signalBus = Get.find<SignalBus>(tag: DITags.signalBusTag);
      
      // 초기화 시작 이벤트 발송
      signalBus.fire(InjectionContainerStartedEvent());
      
      logger.logInfo('Core services initialized, proceeding with data sources');

      // 데이터 소스 초기화
      await DataSourceBinding.initializeAll();
      logger.logInfo('Data sources initialized, proceeding with processors');

      // 프로세서 초기화
      await ProcessorBinding.initializeAll();
      logger.logInfo('Processors initialized, proceeding with repositories');

      // 리포지토리 초기화
      await RepositoryBinding.initializeAll();
      logger.logInfo('Repositories initialized');

      _isInitialized = true;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      logger.logInfo('Dependency injection completed in $duration ms');
      
      final metricLogger = Get.find<MetricLogger>(tag: DITags.metricLoggerTag);
      metricLogger.incrementCounter('dependency_injection_completed', 
        labels: {'status': 'success', 'duration_ms': duration.toString()});
      
      // 완료 이벤트 발송
      signalBus.fire(InjectionContainerCompletedEvent(duration));
    } catch (e, stackTrace) {
      // 오류가 발생한 경우 로거와 시그널버스가 존재하는지 확인
      final logger = Get.isRegistered<AppLogger>(tag: DITags.loggerTag)
          ? Get.find<AppLogger>(tag: DITags.loggerTag)
          : null;
      final signalBus = Get.isRegistered<SignalBus>(tag: DITags.signalBusTag)
          ? Get.find<SignalBus>(tag: DITags.signalBusTag)
          : null;
      final metricLogger = Get.isRegistered<MetricLogger>(tag: DITags.metricLoggerTag)
          ? Get.find<MetricLogger>(tag: DITags.metricLoggerTag)
          : null;
      
      final errorMsg = 'Failed to initialize dependencies: $e';
      print('❌ $errorMsg');
      print('Stack trace: $stackTrace');
      
      // 로거가 있으면 로깅
      logger?.logError(errorMsg, error: e, stackTrace: stackTrace);
      
      // 메트릭 로거가 있으면 기록
      metricLogger?.incrementCounter('dependency_injection_errors', 
        labels: {'error': e.toString().substring(0, 50)});
      
      // 시그널버스가 있으면 에러 이벤트 발송
      signalBus?.fire(InjectionContainerErrorEvent(
        message: errorMsg,
        error: e.toString(),
      ));
      
      throw Exception('Dependency injection failed: $e');
    }
  }

  /// 모든 의존성 해제.
  /// - 리포지토리, 프로세서, 데이터 소스, 서비스 순으로 해제 (초기화의 역순).
  static void dispose() {
    if (!_isInitialized) {
      return;
    }

    try {
      print('🧹 Disposing dependencies...');
      RepositoryBinding.disposeAll();
      ProcessorBinding.disposeAll();
      DataSourceBinding.disposeAll();
      ServiceBinding.disposeAll();
      _isInitialized = false;
      print('✅ Dependencies disposed');
    } catch (e, stackTrace) {
      print('❌ Failed to dispose dependencies: $e');
      print('Stack trace: $stackTrace');
      // Get이 이미 정리되었을 수 있으므로 로거나 signalBus를 찾을 수 없을 수 있음
    }
  }
}