import 'dart:async';
import 'dart:isolate';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/core/utils/lru_set.dart'; // LruSet 임포트

/// 간단한 LruMap 구현 
class LruMap<K, V> {
  final int maximumSize;
  final LinkedHashMap<K, V> _map;
  
  LruMap({required this.maximumSize}) : _map = LinkedHashMap<K, V>();
  
  V? operator [](K key) {
    final value = _map[key];
    if (value != null) {
      // LRU 동작: 접근된 항목을 가장 최근으로 이동
      _map.remove(key);
      _map[key] = value;
    }
    return value;
  }
  
  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= maximumSize) {
      _map.remove(_map.keys.first); // 가장 오래된 항목 제거
    }
    _map[key] = value;
  }
  
  bool containsKey(K key) => _map.containsKey(key);
  
  V? remove(K key) => _map.remove(key);
  
  void clear() => _map.clear();
  
  int get length => _map.length;
  
  Iterable<K> get keys => _map.keys;
  
  Iterable<V> get values => _map.values;
  
  Iterable<MapEntry<K, V>> get entries => _map.entries;
  
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (containsKey(key)) {
      return this[key]!;
    }
    
    final value = ifAbsent();
    this[key] = value;
    return value;
  }
}

/// 거래 데이터 소스 유형.
enum TradeDataSourceType {
  socket, // WebSocket 실시간 데이터
  rest,   // REST API 데이터
}

/// 거래 데이터 이벤트.
class TradeEvent {
  final TradeModel trade;
  final TradeDataSourceType sourceType;
  final DateTime timestamp;

  TradeEvent({
    required this.trade,
    required this.sourceType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSocketData => sourceType == TradeDataSourceType.socket;
  bool get isRestData => sourceType == TradeDataSourceType.rest;
}

/// TradeProcessor 커스텀 시그널 이벤트 클래스들
/// 거래 처리 이벤트
class TradeProcessedEvent extends SignalEvent {
  final String symbol;
  final String source;
  
  TradeProcessedEvent({
    required this.symbol,
    required this.source,
  }) : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_processed',
    'symbol': symbol,
    'source': source,
    'sequentialId': sequentialId.toString(),
  };
}

/// 캐시 업데이트 이벤트
class CacheUpdatedEvent extends SignalEvent {
  final String key;
  final int count;
  
  CacheUpdatedEvent({
    required this.key,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'cache_updated',
    'key': key,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 캐시 쿼리 이벤트
class CacheQueriedEvent extends SignalEvent {
  final String key;
  final int count;
  final String method;
  final Map<String, dynamic> metadata;
  
  CacheQueriedEvent({
    required this.key,
    required this.count,
    required this.method,
    this.metadata = const {},
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'cache_queried',
    'key': key,
    'count': count,
    'method': method,
    ...metadata,
    'sequentialId': sequentialId.toString(),
  };
}

/// REST 폴백 이벤트
class RestFallbackEvent extends SignalEvent {
  final String key;
  final int count;
  
  RestFallbackEvent({
    required this.key,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'rest_fallback',
    'key': key,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 필터 업데이트 이벤트
class FilterUpdatedEvent extends SignalEvent {
  final String filter;
  final double value;
  
  FilterUpdatedEvent({
    required this.filter,
    required this.value,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'filter_updated',
    'filter': filter,
    'value': value,
    'sequentialId': sequentialId.toString(),
  };
}

/// 프로세서 종료 이벤트
class ProcessorDisposedEvent extends SignalEvent {
  ProcessorDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'processor_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 입력 오류 이벤트
class InvalidInputEvent extends SignalEvent {
  final String message;
  
  InvalidInputEvent({
    required this.message,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'invalid_input',
    'message': message,
    'sequentialId': sequentialId.toString(),
  };
}

/// Isolate 내에서 실행되는 캐시 작업을 위한 메시지 클래스
class CacheIsolateMessage {
  final String action;
  final Map<String, dynamic> data;
  final SendPort responsePort;
  
  CacheIsolateMessage(this.action, this.data, this.responsePort);
}

/// Isolate 캐시 핸들러 함수
void _cacheIsolateHandler(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  final recentTradeIds = <String, LruSet<String>>{};
  final recentTradesCache = <String, List<TradeModel>>{};
  const int maxCacheSize = 1000;
  
  receivePort.listen((message) {
    if (message is CacheIsolateMessage) {
      final action = message.action;
      final data = message.data;
      final responsePort = message.responsePort;
      
      switch (action) {
        case 'checkDuplicate':
          final key = data['key'] as String;
          final id = data['id'] as String;
          
          recentTradeIds.putIfAbsent(key, () => LruSet<String>(maximumSize: maxCacheSize));
          final set = recentTradeIds[key]!;
          if (set.contains(id)) {
            responsePort.send(true);
          } else {
            set.add(id);
            responsePort.send(false);
          }
          break;
          
        case 'addToCache':
          final key = data['key'] as String;
          final trade = data['trade'] as TradeModel;
          
          recentTradesCache.putIfAbsent(key, () => []);
          final trades = recentTradesCache[key]!;
          trades.add(trade);
          if (trades.length > maxCacheSize) {
            trades.removeAt(0);
          }
          responsePort.send(true);
          break;
          
        case 'updateCache':
          final key = data['key'] as String;
          final trades = data['trades'] as List<TradeModel>;
          
          recentTradesCache.putIfAbsent(key, () => []);
          final existingTrades = recentTradesCache[key]!;
          existingTrades.addAll(trades);
          if (existingTrades.length > maxCacheSize) {
            existingTrades.removeRange(0, existingTrades.length - maxCacheSize);
          }
          responsePort.send(true);
          break;
          
        case 'getStatus':
          final buffer = StringBuffer();
          for (final entry in recentTradesCache.entries) {
            buffer.writeln('  ${entry.key}: ${entry.value.length} trades');
          }
          responsePort.send(buffer.toString());
          break;
          
        case 'clear':
          recentTradeIds.clear();
          recentTradesCache.clear();
          responsePort.send(true);
          break;
      }
    }
  });
}

/// 소켓 및 REST 거래 데이터를 통합 처리하고 캐싱.
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [signalBus]: 이벤트 브로드캐스트.
/// - [minVolume]: 최소 거래량 필터.
/// - [minTotalAmount]: 최소 거래 금액 필터.
/// @throws [InvalidInputException] 잘못된 입력.
class TradeProcessor {
  final AppLogger _logger;
  final MetricLogger _metricLogger;
  final SignalBus _signalBus;
  final BehaviorSubject<TradeEvent> _tradeEventsSubject = BehaviorSubject<TradeEvent>();

  // 로컬 캐시 (isolate 실패 시 폴백용)
  final Map<String, LruSet<String>> _recentTradeIds = {};
  final Map<String, List<TradeModel>> _recentTradesCache = {};

  // Isolate 관련 필드
  Isolate? _cacheIsolate;
  SendPort? _isolateSendPort;
  Completer<SendPort>? _isolateStartCompleter;

  double _minVolume;
  double _minTotalAmount;

  static const int _maxCacheSize = 1000;

  TradeProcessor({
    required AppLogger logger,
    required MetricLogger metricLogger,
    required SignalBus signalBus,
    double? minVolume,
    double? minTotalAmount,
    int cacheSize = _maxCacheSize,
  }) : _logger = logger,
       _metricLogger = metricLogger,
       _signalBus = signalBus,
       _minVolume = minVolume ?? AppConfig.defaultMinVolume,
       _minTotalAmount = minTotalAmount ?? AppConfig.defaultMinTotal {
    _initCacheIsolate();
  }

  /// 거래 이벤트 스트림.
  Stream<TradeEvent> get tradeEvents => _tradeEventsSubject.stream;

  /// Isolate-safe 캐시 초기화.
  Future<void> _initCacheIsolate() async {
    try {
      final receivePort = ReceivePort();
      _isolateStartCompleter = Completer<SendPort>();
      
      _cacheIsolate = await Isolate.spawn(
        _cacheIsolateHandler, 
        receivePort.sendPort
      );
      
      receivePort.listen((message) {
        if (message is SendPort && !_isolateStartCompleter!.isCompleted) {
          _isolateSendPort = message;
          _isolateStartCompleter!.complete(message);
        }
      });
      
      await _isolateStartCompleter!.future;
      await _clearCache();
    } catch (e) {
      _logger.logError('Failed to initialize cache isolate', error: e);
      // 로컬에서 계속
      _recentTradeIds.clear();
      _recentTradesCache.clear();
    }
  }

  /// 캐시 클리어 헬퍼
  Future<void> _clearCache() async {
    if (_isolateSendPort != null) {
      try {
        final responsePort = ReceivePort();
        
        _isolateSendPort!.send(CacheIsolateMessage(
          'clear',
          {},
          responsePort.sendPort
        ));
        
        await responsePort.first;
        return;
      } catch (e) {
        _logger.logError('Error clearing cache in isolate', error: e);
      }
    }
    
    // 로컬 폴백
    _recentTradeIds.clear();
    _recentTradesCache.clear();
  }

  /// 소켓 거래 데이터 처리.
  /// - [trade]: 처리할 거래 데이터.
  void processSocketTrade(TradeModel trade) {
    _processTrade(trade, TradeDataSourceType.socket);
  }

  /// REST 거래 데이터 처리.
  /// - [trade]: 처리할 거래 데이터.
  void processRestTrade(TradeModel trade) {
    _processTrade(trade, TradeDataSourceType.rest);
  }

  /// 거래 데이터 처리 및 캐싱.
  /// - [trade]: 거래 데이터.
  /// - [sourceType]: 데이터 소스 유형.
  void _processTrade(TradeModel trade, TradeDataSourceType sourceType) {
    final key = _symbolKey(trade.symbol, trade.platform);

    _checkDuplicate(key, trade.sequentialId).then((isDuplicate) {
      if (isDuplicate) {
        _logger.logInfo('Duplicate trade ignored: $key:${trade.sequentialId}');
        _metricLogger.incrementCounter('duplicate_trades', labels: {'platform': trade.platform.toString()});
        return;
      }

      if (!_passesFilter(trade)) {
        _logger.logInfo('Trade filtered out: $key (volume: ${trade.volume}, amount: ${trade.amount})');
        _metricLogger.incrementCounter('filtered_trades', labels: {'platform': trade.platform.toString()});
        return;
      }

      _addToCache(key, trade);

      final event = TradeEvent(trade: trade, sourceType: sourceType);
      if (!_tradeEventsSubject.isClosed) {
        _tradeEventsSubject.add(event);
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(TradeProcessedEvent(
          symbol: trade.symbol,
          source: sourceType.name,
        ));
      }

      _logger.logInfo('Processed trade: $key (${sourceType.name})');
      _metricLogger.incrementCounter('trades_processed', 
          labels: {'platform': trade.platform.toString(), 'source': sourceType.name});
    });
  }

  /// 심볼 키 생성.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  String _symbolKey(String symbol, TradePlatform platform) => '${platform.name}:$symbol';

  /// 중복 거래 체크.
  /// - [key]: 심볼 키.
  /// - [id]: 거래 ID.
  Future<bool> _checkDuplicate(String key, String id) async {
    if (_isolateSendPort != null) {
      try {
        final responsePort = ReceivePort();
        
        _isolateSendPort!.send(CacheIsolateMessage(
          'checkDuplicate',
          {'key': key, 'id': id},
          responsePort.sendPort
        ));
        
        return await responsePort.first as bool;
      } catch (e) {
        _logger.logError('Error in cache isolate check, falling back to local check', error: e);
      }
    }
    
    // 로컬 폴백
    _recentTradeIds.putIfAbsent(key, () => LruSet<String>(maximumSize: _maxCacheSize));
    final set = _recentTradeIds[key]!;
    if (set.contains(id)) return true;
    set.add(id);
    return false;
  }

  /// 거래 필터링.
  /// - [trade]: 거래 데이터.
  bool _passesFilter(TradeModel trade) {
    final amount = trade.price * trade.volume;
    return trade.volume >= _minVolume && amount >= _minTotalAmount;
  }

  /// 캐시에 거래 추가.
  /// - [key]: 심볼 키.
  /// - [trade]: 거래 데이터.
  void _addToCache(String key, TradeModel trade) {
    if (_isolateSendPort != null) {
      try {
        final responsePort = ReceivePort();
        
        _isolateSendPort!.send(CacheIsolateMessage(
          'addToCache',
          {'key': key, 'trade': trade},
          responsePort.sendPort
        ));
        
        responsePort.first.then((_) {
          // 객체지향 방식으로 시그널 이벤트 발송
          _signalBus.fire(CacheUpdatedEvent(
            key: key,
            count: _recentTradesCache[key]?.length ?? 0,
          ));
        });
        return;
      } catch (e) {
        _logger.logError('Error in cache isolate update, falling back to local update', error: e);
      }
    }
    
    // 로컬 폴백
    _recentTradesCache.putIfAbsent(key, () => []);
    final trades = _recentTradesCache[key]!;
    trades.add(trade);
    if (trades.length > _maxCacheSize) {
      trades.removeAt(0);
    }
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(CacheUpdatedEvent(
      key: key,
      count: trades.length,
    ));
  }

  /// 최근 거래 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  /// - [limit]: 반환할 최대 거래 수.
  /// @returns [List<TradeModel>] 최근 거래 리스트.
  List<TradeModel> getRecentTrades(String symbol, TradePlatform platform, {int limit = 50}) {
    if (limit < 0) {
      _logger.logWarning('Invalid limit: $limit, using default 50');
      limit = 50;
    }
    final key = _symbolKey(symbol, platform);
    final trades = _recentTradesCache[key] ?? [];
    final result = trades.reversed.take(limit).toList();
    _logger.logInfo('Retrieved ${result.length} recent trades for $key');
    _metricLogger.incrementCounter('cache_queries', 
        labels: {'platform': platform.toString(), 'method': 'getRecentTrades'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(CacheQueriedEvent(
      key: key,
      count: result.length,
      method: 'recent_trades',
    ));
    
    return result;
  }

  /// 시간 범위 내 거래 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  /// - [startTime]: 시작 시간 (Unix timestamp).
  /// - [endTime]: 종료 시간 (Unix timestamp).
  /// - [limit]: 반환할 최대 거래 수.
  /// @returns [List<TradeModel>] 필터링된 거래 리스트.
  List<TradeModel> getTradesByTimeRange(String symbol, TradePlatform platform, int startTime, int endTime, {int limit = 50}) {
    if (limit < 0) {
      _logger.logWarning('Invalid limit: $limit, using default 50');
      limit = 50;
    }
    if (startTime > endTime) {
      _logger.logWarning('Invalid time range: startTime ($startTime) > endTime ($endTime)');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(InvalidInputEvent(
        message: 'Invalid time range',
      ));
      
      return [];
    }
    final key = _symbolKey(symbol, platform);
    final result = (_recentTradesCache[key] ?? [])
        .where((t) => t.timestamp >= startTime && t.timestamp <= endTime)
        .take(limit)
        .toList();
    _logger.logInfo('Retrieved ${result.length} trades by time range for $key');
    _metricLogger.incrementCounter('cache_queries', 
        labels: {'platform': platform.toString(), 'method': 'getTradesByTimeRange'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(CacheQueriedEvent(
      key: key,
      count: result.length,
      method: 'time_range',
    ));
    
    return result;
  }

  /// 거래 금액 기준 거래 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  /// - [minAmount]: 최소 거래 금액.
  /// - [limit]: 반환할 최대 거래 수.
  /// @returns [List<TradeModel>] 필터링된 거래 리스트.
  List<TradeModel> getTradesByAmount(String symbol, TradePlatform platform, double minAmount, {int limit = 50}) {
    if (limit < 0) {
      _logger.logWarning('Invalid limit: $limit, using default 50');
      limit = 50;
    }
    if (minAmount < 0) {
      _logger.logWarning('Invalid minAmount: $minAmount, using 0');
      minAmount = 0;
    }
    final key = _symbolKey(symbol, platform);
    final result = (_recentTradesCache[key] ?? [])
        .where((t) => (t.price * t.volume) >= minAmount)
        .take(limit)
        .toList();
    _logger.logInfo('Retrieved ${result.length} trades by amount for $key');
    _metricLogger.incrementCounter('cache_queries', 
        labels: {'platform': platform.toString(), 'method': 'getTradesByAmount'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(CacheQueriedEvent(
      key: key,
      count: result.length,
      method: 'by_amount',
    ));
    
    return result;
  }

  /// 거래 방향 기준 거래 내역 조회.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  /// - [isBuy]: 매수(true) 또는 매도(false).
  /// - [limit]: 반환할 최대 거래 수.
  /// @returns [List<TradeModel>] 필터링된 거래 리스트.
  List<TradeModel> getTradesBySide(String symbol, TradePlatform platform, bool isBuy, {int limit = 50}) {
    if (limit < 0) {
      _logger.logWarning('Invalid limit: $limit, using default 50');
      limit = 50;
    }
    final key = _symbolKey(symbol, platform);
    final result = (_recentTradesCache[key] ?? [])
        .where((t) => t.isBuy == isBuy)
        .take(limit)
        .toList();
    _logger.logInfo('Retrieved ${result.length} trades by side for $key (isBuy: $isBuy)');
    _metricLogger.incrementCounter('cache_queries', 
        labels: {'platform': platform.toString(), 'method': 'getTradesBySide'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(CacheQueriedEvent(
      key: key,
      count: result.length,
      method: 'by_side',
      metadata: {'isBuy': isBuy},
    ));
    
    return result;
  }

  /// 소켓 데이터 없으면 REST 데이터로 폴백.
  /// - [symbol]: 마켓 심볼.
  /// - [platform]: 거래소 플랫폼.
  /// - [fallback]: REST 폴백 데이터.
  /// - [limit]: 반환할 최대 거래 수.
  /// @returns [List<TradeModel>] 거래 리스트.
  List<TradeModel> getTradesWithFallback(String symbol, TradePlatform platform, List<TradeModel> fallback, {int limit = 50}) {
    if (limit < 0) {
      _logger.logWarning('Invalid limit: $limit, using default 50');
      limit = 50;
    }
    final key = _symbolKey(symbol, platform);
    final socketTrades = _recentTradesCache[key];
    if (socketTrades == null || socketTrades.isEmpty) {
      _logger.logInfo('Using REST fallback for $key');
      _metricLogger.incrementCounter('rest_fallbacks', labels: {'platform': platform.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(RestFallbackEvent(
        key: key,
        count: fallback.length,
      ));
      
      _updateCache(key, fallback);
      return fallback.take(limit).toList();
    }
    
    final result = socketTrades.take(limit).toList();
    _logger.logInfo('Retrieved ${result.length} socket trades for $key');
    _metricLogger.incrementCounter('cache_queries', 
        labels: {'platform': platform.toString(), 'method': 'getTradesWithFallback'});
    return result;
  }

  /// 캐시 업데이트 헬퍼
  void _updateCache(String key, List<TradeModel> trades) {
    if (_isolateSendPort != null) {
      try {
        final responsePort = ReceivePort();
        
        _isolateSendPort!.send(CacheIsolateMessage(
          'updateCache',
          {'key': key, 'trades': trades},
          responsePort.sendPort
        ));
        
        responsePort.first;
        return;
      } catch (e) {
        _logger.logError('Error updating cache in isolate, falling back to local update', error: e);
      }
    }
    
    // 로컬 폴백
    _recentTradesCache.putIfAbsent(key, () => []);
    final existingTrades = _recentTradesCache[key]!;
    existingTrades.addAll(trades);
    if (existingTrades.length > _maxCacheSize) {
      existingTrades.removeRange(0, existingTrades.length - _maxCacheSize);
    }
  }

  /// 최소 거래량 필터 업데이트.
  /// - [minVolume]: 최소 거래량.
  void updateVolumeFilter(double minVolume) {
    if (minVolume < 0) {
      _logger.logWarning('Invalid minVolume: $minVolume, ignoring');
      return;
    }
    _minVolume = minVolume;
    _logger.logInfo('Updated min volume filter: $_minVolume');
    _metricLogger.incrementCounter('filter_updates', labels: {'type': 'volume'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(FilterUpdatedEvent(
      filter: 'volume',
      value: minVolume,
    ));
  }

/// 최소 거래 금액 필터 업데이트.
 /// - [minTotalAmount]: 최소 거래 금액.
 void updateTotalAmountFilter(double minTotalAmount) {
   if (minTotalAmount < 0) {
     _logger.logWarning('Invalid minTotalAmount: $minTotalAmount, ignoring');
     return;
   }
   _minTotalAmount = minTotalAmount;
   _logger.logInfo('Updated min total amount filter: $_minTotalAmount');
   _metricLogger.incrementCounter('filter_updates', labels: {'type': 'total_amount'});
   
   // 객체지향 방식으로 시그널 이벤트 발송
   _signalBus.fire(FilterUpdatedEvent(
     filter: 'total_amount',
     value: minTotalAmount,
   ));
 }

 /// 캐시 상태 로깅.
 Future<void> logCacheStatus() async {
   final buffer = StringBuffer('Trade cache status:\n');
   
   if (_isolateSendPort != null) {
     try {
       final responsePort = ReceivePort();
       
       _isolateSendPort!.send(CacheIsolateMessage(
         'getStatus',
         {},
         responsePort.sendPort
       ));
       
       final status = await responsePort.first as String;
       buffer.write(status);
       
       _logger.logInfo(buffer.toString());
       _metricLogger.incrementCounter('cache_status_logs');
       return;
     } catch (e) {
       _logger.logError('Error logging cache status in isolate', error: e);
     }
   }
   
   // 로컬 폴백
   for (final entry in _recentTradesCache.entries) {
     buffer.writeln('  ${entry.key}: ${entry.value.length} trades');
   }
   _logger.logInfo('${buffer.toString()} (local fallback)');
   _metricLogger.incrementCounter('cache_status_logs', labels: {'mode': 'local_fallback'});
 }

 /// 리소스 정리.
 Future<void> dispose() async {
   _tradeEventsSubject.close();
   
   if (_isolateSendPort != null && _cacheIsolate != null) {
     try {
       final responsePort = ReceivePort();
       
       _isolateSendPort!.send(CacheIsolateMessage(
         'clear',
         {},
         responsePort.sendPort
       ));
       
       await responsePort.first;
       _cacheIsolate!.kill(priority: Isolate.immediate);
     } catch (e) {
       _logger.logError('Error disposing cache isolate', error: e);
     }
   }
   
   // 로컬 폴백
   _recentTradeIds.clear();
   _recentTradesCache.clear();
   
   _logger.logInfo('TradeProcessor disposed: streams closed, cache cleared');
   _metricLogger.incrementCounter('processor_disposals');
   
   // 객체지향 방식으로 시그널 이벤트 발송
   _signalBus.fire(ProcessorDisposedEvent());
 }
}