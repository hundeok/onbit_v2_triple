import 'dart:io';
/// 의존성 주입 태그 정의.
/// - `Get` 기반 DI에서 서비스, 데이터 소스, 프로세서, 리포지토리 인스턴스를 구분.
/// - [InjectionContainer]에서 사용.
/// @see [InjectionContainer] for dependency initialization.
class DITags {
  // Prefixes for tag categorization
  static const servicePrefix = 'service.';
  static const dataSourcePrefix = 'datasource.';
  static const processorPrefix = 'processor.';
  static const repositoryPrefix = 'repository.';
  
  // Service tags
  /// Logger service tag.
  static const loggerTag = '${servicePrefix}logger';
  /// SignalBus service tag.
  static const signalBusTag = '${servicePrefix}signal_bus';
  /// SocketService tag.
  static const socketServiceTag = '${servicePrefix}socket';
  /// Data service tag (e.g., storage, analytics).
  static const dataServiceTag = '${servicePrefix}data';
  /// ConnectivityManager tag.
  static const connectivityTag = '${servicePrefix}connectivity';
  /// ApiService tag. (이전 ApiClient에서 변경됨)
  static const apiServiceTag = '${servicePrefix}api_service'; // ApiClient에서 ApiService로 변경
  /// MetricLogger tag.
  static const metricLoggerTag = '${servicePrefix}metric_logger';
  /// FCM Service tag.
  static const fcmServiceTag = '${servicePrefix}fcm'; // 추가
  
  // DataSource tags
  /// SocketTradeSource tag.
  static const socketTradeSourceTag = '${dataSourcePrefix}socket_trade';
  /// MarketDataSource tag.
  static const marketDataSourceTag = '${dataSourcePrefix}market_data';
  
  // Processor tags
  /// TradeProcessor tag.
  static const tradeProcessorTag = '${processorPrefix}trade';
  
  // Repository tags
  /// TradeRepository tag.
  static const tradeRepositoryTag = '${repositoryPrefix}trade';
  
  /// 모든 유효한 태그 목록.
  static const List<String> allTags = [
    loggerTag,
    signalBusTag,
    socketServiceTag,
    dataServiceTag,
    connectivityTag,
    apiServiceTag, // apiClientTag에서 변경
    fcmServiceTag, // 추가
    metricLoggerTag,
    socketTradeSourceTag,
    marketDataSourceTag,
    tradeProcessorTag,
    tradeRepositoryTag,
  ];
  
  /// 태그 유효성 검증.
  /// - [tag]: 검증할 태그.
  /// @returns [bool] 태그가 유효하면 true.
  static bool isValidTag(String tag) {
    final isValid = allTags.contains(tag);
    if (!isValid) {
      // Logger 주입 전이므로 stderr 사용
      stderr.writeln('Invalid DI tag: $tag');
    }
    return isValid;
  }
  
  /// 동적 태그 생성.
  /// - [prefix]: 태그 접두사 (service, datasource 등).
  /// - [name]: 태그 이름.
  /// @returns 생성된 태그 문자열.
  static String createTag(String prefix, String name) {
    if (![servicePrefix, dataSourcePrefix, processorPrefix, repositoryPrefix].contains(prefix)) {
      throw ArgumentError('Invalid prefix: $prefix');
    }
    return '$prefix$name';
  }
}