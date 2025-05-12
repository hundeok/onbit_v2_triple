import 'package:get/get.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';

/// DataService 관련 SignalBus 이벤트 클래스들
/// 마켓 업데이트 이벤트
class MarketsUpdatedEvent extends SignalEvent {
  final int count;
  
  MarketsUpdatedEvent(this.count) 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'markets_updated',
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터 서비스 에러 이벤트
class DataServiceErrorEvent extends SignalEvent {
  final String message;
  
  DataServiceErrorEvent(this.message) 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'data_service_error',
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터 서비스 종료 이벤트
class DataServiceDisposedEvent extends SignalEvent {
  DataServiceDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'data_service_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 마켓 및 WebSocket 연결 관리 서비스.
/// - [SocketService]와 [SignalBus]를 통해 마켓 데이터 동기화.
/// - [ServiceBinding]에서 DI 주입.
/// @see [SocketService] for WebSocket connectivity.
class DataService {
  final SocketService socketService;
  final AppLogger logger;
  final MetricLogger metricLogger;
  final SignalBus signalBus;
  final RxList<String> markets = ['KRW-BTC', 'KRW-ETH'].obs;
  
  DataService({
    required this.socketService,
    required this.logger,
    required this.metricLogger,
    required this.signalBus,
  });

  /// 마켓 목록 가져오기 및 WebSocket 연결.
  /// - [newMarkets]: 새로운 마켓 심볼 목록.
  /// - @throws [InvalidInputException] 마켓 목록이 비어있거나 유효하지 않을 경우.
  void fetchSymbols(List<String> newMarkets) {
    if (newMarkets.isEmpty) {
      final error = InvalidInputException(message: 'Market list cannot be empty');
      logger.logError(error.message, error: error, metricLogger: metricLogger);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(DataServiceErrorEvent('Market list cannot be empty'));
      
      throw error;
    }
    
    final uniqueMarkets = newMarkets.toSet().toList();
    if (uniqueMarkets.length != newMarkets.length) {
      logger.logWarning('Duplicate markets removed: $newMarkets -> $uniqueMarkets', metricLogger: metricLogger);
    }
    
    markets.assignAll(uniqueMarkets);
    logger.logInfo('Updated markets: $uniqueMarkets', metricLogger: metricLogger);
    metricLogger.incrementCounter('market_updates', labels: {'count': uniqueMarkets.length.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(MarketsUpdatedEvent(uniqueMarkets.length));
    
    connectWebSocket();
  }

  /// WebSocket 연결 시작.
  void connectWebSocket() {
    if (markets.isEmpty) {
      final error = InvalidInputException(message: 'Cannot connect WebSocket: no markets defined');
      logger.logError(error.message, error: error, metricLogger: metricLogger);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(DataServiceErrorEvent('Cannot connect WebSocket: no markets defined'));
      
      throw error;
    }
    
    try {
      socketService.updateMarkets(markets);
      socketService.connect();
      logger.logInfo('WebSocket connection initiated for markets: $markets', metricLogger: metricLogger);
      metricLogger.incrementCounter('websocket_connections', labels: {'status': 'initiated'});
    } catch (e, stackTrace) {
      logger.logError('Failed to connect WebSocket', error: e, stackTrace: stackTrace, metricLogger: metricLogger);
      metricLogger.incrementCounter('websocket_connection_errors');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(DataServiceErrorEvent('Failed to connect WebSocket: $e'));
      
      rethrow;
    }
  }

  /// 리소스 정리.
  void dispose() {
    markets.close();
    socketService.disconnect();
    logger.logInfo('DataService disposed', metricLogger: metricLogger);
    metricLogger.incrementCounter('data_service_disposals');
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(DataServiceDisposedEvent());
  }
}