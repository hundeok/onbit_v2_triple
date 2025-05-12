import 'dart:async';
import 'dart:isolate';
import 'dart:collection'; // LinkedHashMap 임포트 추가
import 'package:collection/collection.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/socket/socket_service.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:rxdart/rxdart.dart';

/// 간단한 IsolateRunner 구현
class IsolateRunner {
  final Isolate? isolate;
  SendPort? sendPort;
  final ReceivePort receivePort;
  final Completer<SendPort> _portCompleter = Completer<SendPort>();
  
  IsolateRunner() 
      : isolate = null,
        sendPort = null,
        receivePort = ReceivePort() {
    _init();
  }
  
  Future<void> _init() async {
    final isolateInstance = await Isolate.spawn(_isolateMain, receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is SendPort && !_portCompleter.isCompleted) {
        sendPort = message;
        _portCompleter.complete(message);
      }
    });
    
    await _portCompleter.future;
  }
  
  static void _isolateMain(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is _IsolateMessage) {
        try {
          final result = message.function();
          message.responsePort.send(_IsolateResponse(data: result));
        } catch (e) {
          message.responsePort.send(_IsolateResponse(error: e));
        }
      }
    });
  }
  
  Future<T> run<T>(T Function() function) async {
    await _portCompleter.future; // 초기화 완료 대기
    
    final responsePort = ReceivePort();
    final message = _IsolateMessage(
      function: function as dynamic Function(),
      responsePort: responsePort.sendPort,
    );
    
    sendPort!.send(message);
    
    final response = await responsePort.first as _IsolateResponse;
    if (response.error != null) {
      throw response.error!;
    }
    return response.data as T;
  }
  
  Future<void> close() async {
    await _portCompleter.future; // 초기화 완료 대기
    receivePort.close();
    isolate?.kill(priority: Isolate.immediate);
  }
}

class _IsolateMessage {
  final dynamic Function() function;
  final SendPort responsePort;
  
  _IsolateMessage({
    required this.function,
    required this.responsePort,
  });
}

class _IsolateResponse {
  final dynamic data;
  final Object? error;
  
  _IsolateResponse({this.data, this.error});
}

/// LRU 캐시 구현
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
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }
  
  void clear() => _map.clear();
  
  bool containsKey(K key) => _map.containsKey(key);
}

/// 소켓 트레이드 관련 SignalBus 이벤트 클래스들
/// 거래 스트림 시작 이벤트
class TradeStreamStartedEvent extends SignalEvent {
  final int marketCount;
  
  TradeStreamStartedEvent({
    required this.marketCount,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_stream_started',
    'marketCount': marketCount,
    'sequentialId': sequentialId.toString(),
  };
}

/// 스트림 종료 이벤트
class StreamClosedEvent extends SignalEvent {
  StreamClosedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'stream_closed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 스트림 연결 해제 이벤트
class StreamDisconnectedEvent extends SignalEvent {
  StreamDisconnectedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'stream_disconnected',
    'sequentialId': sequentialId.toString(),
  };
}

/// 필터 업데이트 이벤트
class FilterUpdatedEvent extends SignalEvent {
  final String filterType;
  final double value;
  
  FilterUpdatedEvent({
    required this.filterType,
    required this.value,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'filter_updated',
    'filter': filterType,
    'value': value,
    'sequentialId': sequentialId.toString(),
  };
}

/// 플랫폼 업데이트 이벤트
class PlatformUpdatedEvent extends SignalEvent {
  final TradePlatform platform;
  
  PlatformUpdatedEvent({
    required this.platform,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'platform_updated',
    'platform': platform.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 트레이드 소스 종료 이벤트
class SocketTradeSourceDisposedEvent extends SignalEvent {
  SocketTradeSourceDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_trade_source_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 트레이드 이벤트
class SocketTradeDataEvent extends SignalEvent {
  final String market;
  final double price;
  final double volume;
  final int tradeTimestamp; // 이름 변경
  final String side;
  final String tradeSequentialId; // 이름 변경
  
  SocketTradeDataEvent({
    required this.market,
    required this.price,
    required this.volume,
    required this.tradeTimestamp, // 이름 변경
    required this.side,
    required this.tradeSequentialId, // 이름 변경
  }) : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'market': market,
    'price': price,
    'volume': volume,
    'timestamp': tradeTimestamp,
    'side': side,
    'tradeSequentialId': tradeSequentialId,
    'sequentialId': sequentialId.toString(),
  };
}

/// 에러 이벤트
class TradeErrorEvent extends SignalEvent {
  final String message;
  final Object? error;
  
  TradeErrorEvent({
    required this.message,
    this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trade_error',
    'message': message,
    'error': error?.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// WebSocket 거래 데이터를 처리하는 데이터 소스.
/// - [socketService]: WebSocket 연결 서비스.
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [signalBus]: 이벤트 브로드캐스트.
/// @throws [SocketException] WebSocket 에러.
/// @throws [DataParsingException] 데이터 파싱 에러.
class SocketTradeSource {
  final SocketService socketService;
  final AppLogger logger;
  final MetricLogger metricLogger;
  final SignalBus signalBus;

  final IsolateRunner _cacheIsolate;
  final LruMap<String, String> _lastSequentialIds;
  final BehaviorSubject<TradeModel> _tradeController;
  double _minVolume;
  double _minTotal;
  TradePlatform _platform;
  StreamSubscription? _socketSubscription;
  bool _isListening = false;

  static const int _maxCacheSize = 1000;

  SocketTradeSource({
    required this.socketService,
    required this.logger,
    required this.metricLogger,
    required this.signalBus,
  }) : _cacheIsolate = IsolateRunner(),
       _lastSequentialIds = LruMap(maximumSize: _maxCacheSize),
       _tradeController = BehaviorSubject<TradeModel>(),
       _minVolume = AppConfig.defaultMinVolume,
       _minTotal = AppConfig.defaultMinTotal,
       _platform = _mapExchangePlatform(AppConfig.defaultPlatform) {
    _initCacheIsolate();
  }

  /// 캐시 초기화.
  Future<void> _initCacheIsolate() async {
    await _cacheIsolate.run(() {
      _lastSequentialIds.clear();
      return null;
    });
  }

  /// 거래 스트림 반환.
  /// - [markets]: 구독할 마켓 심볼 리스트.
  /// @returns [Stream<TradeModel>] 거래 데이터 스트림.
  /// @throws [InvalidInputException] 빈 마켓 리스트 제공 시.
  Stream<TradeModel> getTradeStream(List<String> markets) {
    if (markets.isEmpty) {
      logger.logWarning('Empty markets list provided');
      metricLogger.incrementCounter('invalid_inputs', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(TradeErrorEvent(
        message: 'Empty markets list',
      ));
      
      throw InvalidInputException(message: 'Markets list cannot be empty');
    }

    if (_isListening) {
      logger.logInfo('Already listening to trade stream');
      return _tradeController.stream;
    }

    logger.logInfo('Starting trade stream for ${markets.length} markets');
    metricLogger.incrementCounter('stream_starts', labels: {'platform': _platform.toString()});
    socketService.updateMarkets(markets);
    socketService.connect();

    _socketSubscription = socketService.stream.listen(
      (data) {
        try {
          data['platform'] = _platform.toString().split('.').last;
          final trade = TradeModel.fromExchangeJson(data);
          if (_checkDuplicate(trade)) return;
          if (!_passesFilter(trade)) return;

          _tradeController.add(trade);
          
          // 객체지향 방식으로 시그널 이벤트 발송
          signalBus.fire(SocketTradeDataEvent(
            market: trade.symbol,
            price: trade.price,
            volume: trade.volume,
            tradeTimestamp: trade.timestamp,
            side: trade.isBuy ? 'BID' : 'ASK',
            tradeSequentialId: trade.sequentialId,
          ));
          
          metricLogger.incrementCounter('trades_processed', labels: {'platform': _platform.toString()});
        } catch (e, stackTrace) {
          _handleError('Failed to parse trade data', e, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        _handleError('WebSocket error', error, stackTrace);
      },
      onDone: () {
        logger.logInfo('Socket stream closed');
        metricLogger.incrementCounter('stream_closures', labels: {'platform': _platform.toString()});
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus.fire(StreamClosedEvent());
      },
    );

    _isListening = true;
    logger.logInfo('Started listening to trade stream');
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(TradeStreamStartedEvent(
      marketCount: markets.length,
    ));
    
    return _tradeController.stream;
  }

  /// 중복 거래 체크.
  /// - [trade]: 거래 데이터.
  Future<bool> _checkDuplicate(TradeModel trade) async {
    final key = '${trade.platform}_${trade.symbol}';
    return await _cacheIsolate.run(() {
      if (_lastSequentialIds[key] == trade.sequentialId) {
        logger.logInfo('Duplicate trade ignored: $key:${trade.sequentialId}');
        metricLogger.incrementCounter('duplicate_trades', labels: {'platform': _platform.toString()});
        return true;
      }
      _lastSequentialIds[key] = trade.sequentialId;
      return false;
    });
  }

  /// 필터 조건 확인.
  /// - [trade]: 거래 데이터.
  bool _passesFilter(TradeModel trade) {
    final amount = trade.price * trade.volume;
    final passes = trade.volume >= _minVolume && amount >= _minTotal;
    if (!passes) {
      logger.logInfo('Trade filtered out: $trade (volume: ${trade.volume}, amount: $amount)');
      metricLogger.incrementCounter('filtered_trades', labels: {'platform': _platform.toString()});
    }
    return passes;
  }

  /// 에러 처리.
  /// - [context]: 에러 컨텍스트.
  /// - [error]: 에러 객체.
  /// - [stackTrace]: 스택 트레이스.
  void _handleError(String context, Object error, [StackTrace? stackTrace]) {
    logger.logError(context, error: error, stackTrace: stackTrace);
    metricLogger.incrementCounter('stream_errors', labels: {'platform': _platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(TradeErrorEvent(
      message: context,
      error: error,
    ));

    final exception = error is SocketException || error is DataParsingException
        ? error
        : SocketException(message: context, error: error);
    if (!_tradeController.isClosed) {
      _tradeController.addError(exception, stackTrace);
    }
  }

  /// 최소 거래량 필터 업데이트.
  /// - [volume]: 최소 거래량.
  void setMinVolume(double volume) {
    if (volume < 0) {
      logger.logWarning('Invalid minVolume: $volume, ignoring');
      metricLogger.incrementCounter('invalid_inputs', labels: {'platform': _platform.toString()});
      return;
    }
    _minVolume = volume;
    logger.logInfo('Updated minimum volume filter: $_minVolume');
    metricLogger.incrementCounter('filter_updates', labels: {'platform': _platform.toString(), 'type': 'volume'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(FilterUpdatedEvent(
      filterType: 'volume',
      value: volume,
    ));
  }

  /// 최소 거래 금액 필터 업데이트.
  /// - [total]: 최소 거래 금액.
  void setMinTotal(double total) {
    if (total < 0) {
      logger.logWarning('Invalid minTotal: $total, ignoring');
      metricLogger.incrementCounter('invalid_inputs', labels: {'platform': _platform.toString()});
      return;
    }
    _minTotal = total;
    logger.logInfo('Updated minimum total filter: $_minTotal');
    metricLogger.incrementCounter('filter_updates', labels: {'platform': _platform.toString(), 'type': 'total'});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(FilterUpdatedEvent(
      filterType: 'total',
      value: total,
    ));
  }

  /// 거래소 플랫폼 업데이트.
  /// - [platform]: 거래소 플랫폼.
  void setPlatform(TradePlatform platform) {
    _platform = platform;
    logger.logInfo('Updated platform to: $_platform');
    metricLogger.incrementCounter('platform_updates', labels: {'platform': _platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(PlatformUpdatedEvent(
      platform: platform,
    ));
  }

  /// WebSocket 연결 종료.
  void disconnect() {
    _socketSubscription?.cancel();
    socketService.disconnect();
    _isListening = false;
    logger.logInfo('Disconnected from trade stream');
    metricLogger.incrementCounter('stream_disconnects', labels: {'platform': _platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(StreamDisconnectedEvent());
  }

  /// 리소스 정리.
  void dispose() async {
    disconnect();
    if (!_tradeController.isClosed) {
      _tradeController.close();
    }
    await _cacheIsolate.run(() {
      _lastSequentialIds.clear();
      return null;
    });
    await _cacheIsolate.close();
    logger.logInfo('SocketTradeSource disposed: streams closed, cache cleared');
    metricLogger.incrementCounter('socket_trade_source_disposals', labels: {'platform': _platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(SocketTradeSourceDisposedEvent());
  }

  /// ExchangePlatform을 TradePlatform으로 변환.
  static TradePlatform _mapExchangePlatform(ExchangePlatform platform) {
    switch (platform) {
      case ExchangePlatform.upbit:
        return TradePlatform.upbit;
      case ExchangePlatform.binance:
        return TradePlatform.binance;
      case ExchangePlatform.bybit:
        return TradePlatform.bybit;
      case ExchangePlatform.bithumb:
        return TradePlatform.bithumb;
    }
  }
}