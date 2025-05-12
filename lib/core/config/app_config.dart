import 'package:get_it/get_it.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

final getIt = GetIt.instance;

/// SignalBus 이벤트 클래스 - 설정 로드 알림
class ConfigLoadedEvent extends SignalEvent {
  final String message;
  
  ConfigLoadedEvent({required this.message})
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'config_loaded',
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 설정 오류
class ConfigErrorEvent extends SignalEvent {
  final String message;
  final String field;
  final Object? error;
  
  ConfigErrorEvent({
    required this.message,
    required this.field,
    this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'config_error',
    'message': message,
    'field': field,
    'error': error?.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래소 플랫폼 구분.
enum ExchangePlatform {
  upbit,
  binance,
  bybit,
  bithumb,
}

/// 애플리케이션 전반의 정적 설정.
/// - 거래 필터, 시간 프레임, 임계값 등을 정의.
/// - [TradeRepositoryImpl], [ApiService], [TradeProcessor], [AppLogger] 등에서 사용.
/// - [EnvConfig]와 연동해 환경별 설정 지원.
/// @see [EnvConfig] for environment-specific configurations.
class AppConfig {
  /// 기본 거래소 플랫폼.
  static const ExchangePlatform defaultPlatform = ExchangePlatform.upbit;

  /// 캐시 TTL (밀리초).
  static const int cacheTtlMs = 60000; // 1분

  /// 거래 필터 금액 목록 (KRW).
  static const List<double> tradeFilters = [
    2000000.0,
    5000000.0,
    10000000.0,
    20000000.0,
    50000000.0,
    100000000.0,
    200000000.0,
    300000000.0,
    400000000.0,
    500000000.0,
    1000000000.0,
  ];

  /// 거래 필터 이름 매핑.
  static final Map<double, String> filterNames = {
    2000000.0: '2백만',
    5000000.0: '5백만',
    10000000.0: '1천만',
    20000000.0: '2천만',
    50000000.0: '5천만',
    100000000.0: '1억',
    200000000.0: '2억',
    300000000.0: '3억',
    400000000.0: '4억',
    500000000.0: '5억',
    1000000000.0: '10억',
  };

  /// 시간 프레임 목록 (분 단위).
  static const List<int> timeFrames = [
    1, 5, 15, 30, 60, 120, 240, 480, 720, 1440,
  ];

  /// 시간 프레임 이름 매핑.
  static final Map<int, String> timeFrameNames = {
    1: '1분',
    5: '5분',
    15: '15분',
    30: '30분',
    60: '1시간',
    120: '2시간',
    240: '4시간',
    480: '8시간',
    720: '12시간',
    1440: '1일',
  };

  /// 거래 병합 윈도우 (밀리초).
  static const int mergeWindowMs = 1000;

  /// 순간 거래 최소 금액 (KRW).
  static const double momentaryMinAmount = 500000.0;

  /// 순간 거래 임계값 (KRW).
  static const double momentaryThreshold = 2000000.0;

  /// 급등 임계값 (비율, 예: 1.1 = 10% 상승).
  static const double surgeThreshold = 1.1;

  /// 급등 윈도우 기간.
  static const Duration surgeWindow = Duration(minutes: 1);

  /// 기본 최소 가격 (KRW).
  static const double defaultMinPrice = 40000.0;

  /// 기본 최대 가격 (KRW).
  static const double defaultMaxPrice = 60000.0;

  /// 기본 최소 거래량.
  static const double defaultMinVolume = 0.5;

  /// 기본 최소 거래 금액 (KRW).
  static const double defaultMinTotal = 40000.0;

  /// 기본 거래량 시간 프레임 (분).
  static const int defaultVolumeTimeFrame = 1;

  /// 디버그 모드 여부 (환경별 설정).
  static const bool isDebugMode = true;

  /// 가격 포맷 패턴.
  static const String priceFormatPattern = '#,##0.00####';

  /// 변동률 포맷 패턴.
  static const String percentageFormatPattern = '+#,##0.00;-#,##0.00';

  /// 거래량 포맷 패턴.
  static const String volumeFormatPattern = '#,##0.##';

  /// 금액 포맷 패턴.
  static const String amountFormatPattern = '#,##0.##';

  /// 기본 스로틀링 간격 (밀리초).
  static const int defaultThrottleMs = 100;

  /// 설정 초기화 및 유효성 검사.
  static void initialize({MetricLogger? metricLogger, SignalBus? signalBus}) {
    _validateSettings(metricLogger: metricLogger, signalBus: signalBus);
    metricLogger?.incrementCounter('config_initializations', labels: {'status': 'success'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(ConfigLoadedEvent(message: 'Configuration loaded'));
  }

  /// 설정 값 유효성 검사.
  static void _validateSettings({MetricLogger? metricLogger, SignalBus? signalBus}) {
    // tradeFilters 유효성: 양수, 중복 없음
    if (tradeFilters.any((value) => value <= 0)) {
      final error = InvalidInputException(message: 'tradeFilters contains invalid values');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'tradeFilters'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'tradeFilters',
        error: error,
      ));
      
      throw error;
    }
    
    if (tradeFilters.toSet().length != tradeFilters.length) {
      final error = InvalidInputException(message: 'tradeFilters contains duplicates');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'tradeFilters'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'tradeFilters',
        error: error,
      ));
      
      throw error;
    }

    // filterNames 유효성: 모든 tradeFilters에 매핑
    if (!tradeFilters.every((value) => filterNames.containsKey(value))) {
      final error = InvalidInputException(message: 'filterNames missing mappings for tradeFilters');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'filterNames'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'filterNames',
        error: error,
      ));
      
      throw error;
    }

    // timeFrames 유효성: 양수, 중복 없음
    if (timeFrames.any((value) => value <= 0)) {
      final error = InvalidInputException(message: 'timeFrames contains invalid values');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'timeFrames'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'timeFrames',
        error: error,
      ));
      
      throw error;
    }
    
    if (timeFrames.toSet().length != timeFrames.length) {
      final error = InvalidInputException(message: 'timeFrames contains duplicates');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'timeFrames'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'timeFrames',
        error: error,
      ));
      
      throw error;
    }

    // timeFrameNames 유효성: 모든 timeFrames에 매핑
    if (!timeFrames.every((value) => timeFrameNames.containsKey(value))) {
      final error = InvalidInputException(message: 'timeFrameNames missing mappings for timeFrames');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'timeFrameNames'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'timeFrameNames',
        error: error,
      ));
      
      throw error;
    }

    // 기타 설정 유효성
    if (momentaryMinAmount <= 0 ||
        momentaryThreshold <= 0 ||
        surgeThreshold <= 1.0 ||
        defaultMinPrice <= 0 ||
        defaultMaxPrice <= 0 ||
        defaultMinVolume <= 0 ||
        defaultMinTotal <= 0 ||
        defaultVolumeTimeFrame <= 0 ||
        mergeWindowMs <= 0 ||
        cacheTtlMs <= 0) {
      final error = InvalidInputException(message: 'Invalid configuration values detected');
      metricLogger?.incrementCounter('config_validation_errors', labels: {'field': 'thresholds'});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(ConfigErrorEvent(
        message: error.message,
        field: 'thresholds',
        error: error,
      ));
      
      throw error;
    }
  }

  /// 설정 값 가져오기 (안전 접근).
  static dynamic getSetting(String key, {MetricLogger? metricLogger, SignalBus? signalBus}) {
    switch (key) {
      case 'defaultPlatform':
        return defaultPlatform;
      case 'cacheTtlMs':
        return cacheTtlMs;
      case 'tradeFilters':
        return tradeFilters;
      case 'filterNames':
        return filterNames;
      case 'timeFrames':
        return timeFrames;
      case 'timeFrameNames':
        return timeFrameNames;
      case 'mergeWindowMs':
        return mergeWindowMs;
      case 'momentaryMinAmount':
        return momentaryMinAmount;
      case 'momentaryThreshold':
        return momentaryThreshold;
      case 'surgeThreshold':
        return surgeThreshold;
      case 'surgeWindow':
        return surgeWindow;
      case 'defaultMinPrice':
        return defaultMinPrice;
      case 'defaultMaxPrice':
        return defaultMaxPrice;
      case 'defaultMinVolume':
        return defaultMinVolume;
      case 'defaultMinTotal':
        return defaultMinTotal;
      case 'defaultVolumeTimeFrame':
        return defaultVolumeTimeFrame;
      case 'isDebugMode':
        return isDebugMode;
      case 'priceFormatPattern':
        return priceFormatPattern;
      case 'percentageFormatPattern':
        return percentageFormatPattern;
      case 'volumeFormatPattern':
        return volumeFormatPattern;
      case 'amountFormatPattern':
        return amountFormatPattern;
      case 'defaultThrottleMs':
        return defaultThrottleMs;
      default:
        final error = InvalidInputException(message: 'Unknown config key: $key');
        metricLogger?.incrementCounter('config_access_errors', labels: {'key': key});
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus?.fire(ConfigErrorEvent(
          message: error.message,
          field: key,
          error: error,
        ));
        
        throw error;
    }
  }
}