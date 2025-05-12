import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/di/tags.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// SignalBus 이벤트 클래스 - 환경 설정 로드 완료
class EnvConfigLoadedEvent extends SignalEvent {
  EnvConfigLoadedEvent()
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'env_config_loaded',
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 환경 설정 접근
class EnvConfigAccessedEvent extends SignalEvent {
  final ExchangePlatform platform;
  
  EnvConfigAccessedEvent(this.platform)
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'env_config_accessed',
    'platform': platform.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// SignalBus 이벤트 클래스 - 환경 설정 오류
class EnvConfigErrorEvent extends SignalEvent {
  final String message;
  final ExchangePlatform? platform;
  final Object? error;
  
  EnvConfigErrorEvent({
    required this.message,
    this.platform,
    this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'env_config_error',
    'message': message,
    'platform': platform?.toString() ?? 'none',
    'error': error?.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래소별 환경 설정 관리.
/// - API 및 WebSocket 엔드포인트 정의.
/// - [ApiService], [SocketService], [RealMarketDataSource]에서 사용.
/// - [AppConfig]와 연동해 기본 설정 참조.
/// @see [AppConfig] for application-wide configurations.
class ExchangeConfig {
  final String baseUrl;
  final String symbolsEndpoint;
  final String symbolKey;
  final String marketPrefix;
  final String wsUrl;
  final String priceEndpoint;
  final String tradesEndpoint;
  final String candlesEndpoint;

  const ExchangeConfig({
    required this.baseUrl,
    required this.symbolsEndpoint,
    required this.symbolKey,
    required this.marketPrefix,
    required this.wsUrl,
    required this.priceEndpoint,
    required this.tradesEndpoint,
    required this.candlesEndpoint,
  });

  /// 거래소별 설정 맵.
  static final Map<ExchangePlatform, ExchangeConfig> _configs = {
    ExchangePlatform.upbit: const ExchangeConfig(
      baseUrl: 'https://api.upbit.com/v1',
      symbolsEndpoint: '/market/all',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
      wsUrl: 'wss://api.upbit.com/websocket/v1',
      priceEndpoint: '/ticker?markets={symbol}',
      tradesEndpoint: '/trades/ticks?market={symbol}',
      candlesEndpoint: '/candles/minutes/{interval}?market={symbol}',
    ),
    ExchangePlatform.binance: const ExchangeConfig(
      baseUrl: 'https://api.binance.com',
      symbolsEndpoint: '/api/v3/exchangeInfo',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
      wsUrl: 'wss://stream.binance.com:9443/ws',
      priceEndpoint: '/api/v3/ticker/price?symbol={symbol}',
      tradesEndpoint: '/api/v3/trades?symbol={symbol}',
      candlesEndpoint: '/api/v3/klines?symbol={symbol}&interval={interval}',
    ),
    ExchangePlatform.bybit: const ExchangeConfig(
      baseUrl: 'https://api.bybit.com',
      symbolsEndpoint: '/v5/market/instruments-info?category=spot',
      symbolKey: 'symbol',
      marketPrefix: 'USDT',
      wsUrl: 'wss://stream.bybit.com/v5/public/spot',
      priceEndpoint: '/v5/market/tickers?symbol={symbol}',
      tradesEndpoint: '/v5/market/recent-trade?symbol={symbol}',
      candlesEndpoint: '/v5/market/kline?symbol={symbol}&interval={interval}',
    ),
    ExchangePlatform.bithumb: const ExchangeConfig(
      baseUrl: 'https://api.bithumb.com',
      symbolsEndpoint: '/public/ticker/ALL',
      symbolKey: 'market',
      marketPrefix: 'KRW-',
      wsUrl: 'wss://pubwss.bithumb.com/pub/ws',
      priceEndpoint: '/public/ticker/{symbol}_KRW',
      tradesEndpoint: '/public/transaction_history/{symbol}_KRW',
      candlesEndpoint: '/public/candlestick/{symbol}_KRW/{interval}',
    ),
  };

  /// 거래소 설정 가져오기.
  /// - [platform]: 거래소 플랫폼.
  /// - [metricLogger]: 메트릭 로거 (선택).
  /// - [signalBus]: 이벤트 버스 (선택).
  /// @returns [ExchangeConfig] 설정 객체.
  /// @throws [InvalidInputException] 플랫폼이 지원되지 않을 경우.
  static ExchangeConfig getConfig(
    ExchangePlatform platform, {
    MetricLogger? metricLogger,
    SignalBus? signalBus,
  }) {
    if (!_configs.containsKey(platform)) {
      final error = InvalidInputException(message: 'Unsupported platform: $platform');
      metricLogger?.incrementCounter('config_access_errors', labels: {'platform': platform.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus?.fire(EnvConfigErrorEvent(
        message: error.message,
        platform: platform,
        error: error,
      ));
      
      throw error;
    }
    
    final config = _configs[platform]!;
    metricLogger?.incrementCounter('config_accesses', labels: {'platform': platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(EnvConfigAccessedEvent(platform));
    
    return config;
  }

  /// 설정 초기화 및 유효성 검사.
  /// - [metricLogger]: 메트릭 로거 (선택).
  /// - [signalBus]: 이벤트 버스 (선택).
  /// @throws [InvalidInputException] 설정 값이 유효하지 않을 경우.
  static void initialize({MetricLogger? metricLogger, SignalBus? signalBus}) {
    _validateConfigs(metricLogger: metricLogger, signalBus: signalBus);
    metricLogger?.incrementCounter('env_config_initializations', labels: {'status': 'success'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus?.fire(EnvConfigLoadedEvent());
  }

  /// 설정 값 유효성 검사.
  static void _validateConfigs({MetricLogger? metricLogger, SignalBus? signalBus}) {
    for (final entry in _configs.entries) {
      final platform = entry.key;
      final config = entry.value;

      // 필수 필드 비어있지 않은지 확인
      if (config.baseUrl.isEmpty ||
          config.symbolsEndpoint.isEmpty ||
          config.symbolKey.isEmpty ||
          config.marketPrefix.isEmpty ||
          config.wsUrl.isEmpty ||
          config.priceEndpoint.isEmpty ||
          config.tradesEndpoint.isEmpty ||
          config.candlesEndpoint.isEmpty) {
        final error = InvalidInputException(message: 'Invalid configuration for $platform: empty fields detected');
        metricLogger?.incrementCounter('env_config_validation_errors', labels: {'platform': platform.toString()});
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus?.fire(EnvConfigErrorEvent(
          message: error.message,
          platform: platform,
          error: error,
        ));
        
        throw error;
      }

      // URL 형식 유효성 (간단한 체크)
      if (!config.baseUrl.startsWith('http') || !config.wsUrl.startsWith('ws')) {
        final error = InvalidInputException(message: 'Invalid URL format for $platform');
        metricLogger?.incrementCounter('env_config_validation_errors', labels: {'platform': platform.toString()});
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus?.fire(EnvConfigErrorEvent(
          message: error.message,
          platform: platform,
          error: error,
        ));
        
        throw error;
      }
    }
  }
}