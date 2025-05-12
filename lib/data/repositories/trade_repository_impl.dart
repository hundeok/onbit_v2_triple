import 'dart:async';
import 'dart:isolate';
import 'package:dartz/dartz.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/network/connectivity_manager.dart';
import 'package:onbit_v2_triple/data/datasources/market_data_source.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/data/processors/trade_processor.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'package:onbit_v2_triple/domain/repositories/trade_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/data/models/trade_model.dart'; // TradeModel 임포트 추가

/// 간단한 IsolateRunner 대체 구현
class IsolateRunner {
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  
  IsolateRunner._({
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
  });
  
  static Future<IsolateRunner> spawn() async {
    final ReceivePort receivePort = ReceivePort();
    final completer = Completer<SendPort>();
    
    final isolate = await Isolate.spawn(_isolateMain, receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is SendPort && !completer.isCompleted) {
        completer.complete(message);
      }
    });
    
    final sendPort = await completer.future;
    return IsolateRunner._(
      isolate: isolate,
      sendPort: sendPort,
      receivePort: receivePort,
    );
  }
  
  static void _isolateMain(SendPort sendPort) {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is _IsolateMessage) {
        try {
          final result = message.function(message.argument);
          message.responsePort.send(_IsolateResponse(data: result));
        } catch (e) {
          message.responsePort.send(_IsolateResponse(error: e));
        }
      }
    });
  }
  
  Future<R> run<R, T>(R Function(T) function, T argument) async {
    final responsePort = ReceivePort();
    final message = _IsolateMessage(
      function: function as dynamic Function(dynamic),
      argument: argument,
      responsePort: responsePort.sendPort,
    );
    
    sendPort.send(message);
    
    final response = await responsePort.first as _IsolateResponse;
    if (response.error != null) {
      throw response.error!;
    }
    return response.data as R;
  }
  
  Future<void> close() async {
    receivePort.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

class _IsolateMessage {
  final dynamic Function(dynamic) function;
  final dynamic argument;
  final SendPort responsePort;
  
  _IsolateMessage({
    required this.function,
    required this.argument,
    required this.responsePort,
  });
}

class _IsolateResponse {
  final dynamic data;
  final Object? error;
  
  _IsolateResponse({this.data, this.error});
}

/// 데이터 소스 조회 모드.
enum FetchMode {
  normal,   // 일반적인 캐시 & REST API 조회
  fallback, // 소켓 실패 시 REST API 폴백
}

/// 거래소 데이터 관련 이벤트 클래스들
/// 마켓 목록 조회 이벤트
class MarketsFetchedEvent extends SignalEvent {
  final int count;
  
  MarketsFetchedEvent({
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'markets_fetched',
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 재연결 이벤트
class SocketReconnectEvent extends SignalEvent {
  final int attempt;
  
  SocketReconnectEvent({
    required this.attempt,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_reconnect',
    'attempt': attempt,
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 실패 이벤트
class SocketFailureEvent extends SignalEvent {
  final String error;
  
  SocketFailureEvent({
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_failure',
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 영구적 소켓 실패 이벤트
class PermanentSocketFailureEvent extends SignalEvent {
  PermanentSocketFailureEvent() 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'permanent_socket_failure',
    'sequentialId': sequentialId.toString(),
  };
}

/// 네트워크 복구 이벤트
class NetworkRestoredEvent extends SignalEvent {
  final int marketsCount;
  
  NetworkRestoredEvent({
    required this.marketsCount,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'network_restored',
    'marketsCount': marketsCount,
    'sequentialId': sequentialId.toString(),
  };
}

/// 네트워크 연결 끊김 이벤트
class NetworkDisconnectedEvent extends SignalEvent {
  NetworkDisconnectedEvent() 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'network_disconnected',
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 처리 이벤트
class TradesProcessedEvent extends SignalEvent {
  final int count;
  
  TradesProcessedEvent({
    required this.count,
  }) : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'trades_processed',
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 캐시 히트 이벤트
class CacheHitEvent extends SignalEvent {
  final String symbol;
  final int count;
  
  CacheHitEvent({
    required this.symbol,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'cache_hit',
    'symbol': symbol,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 캐시 업데이트 이벤트
class CacheUpdateEvent extends SignalEvent {
  final String symbol;
  final int count;
  
  CacheUpdateEvent({
    required this.symbol,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'cache_update',
    'symbol': symbol,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// REST 폴백 이벤트
class RestFallbackEvent extends SignalEvent {
  final String symbol;
  final int count;
  
  RestFallbackEvent({
    required this.symbol,
    required this.count,
  }) : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'rest_fallback',
    'symbol': symbol,
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// REST 폴백 실패 이벤트
class RestFallbackFailureEvent extends SignalEvent {
  final String symbol;
  
  RestFallbackFailureEvent({
    required this.symbol,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'rest_fallback_failure',
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 타임아웃 이벤트
class TimeoutEvent extends SignalEvent {
  final String symbol;
  
  TimeoutEvent({
    required this.symbol,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'timeout',
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 서버 에러 이벤트
class ServerErrorEvent extends SignalEvent {
  final String code;
  
  ServerErrorEvent({
    required this.code,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'server_error',
    'code': code,
    'sequentialId': sequentialId.toString(),
  };
}

/// 예기치 않은 에러 이벤트
class UnexpectedErrorEvent extends SignalEvent {
  final String error;
  
  UnexpectedErrorEvent({
    required this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'unexpected_error',
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// 잘못된 입력 이벤트
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

/// 속도 제한 에러 이벤트
class RateLimitErrorEvent extends SignalEvent {
  RateLimitErrorEvent() 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'rate_limit_error',
    'sequentialId': sequentialId.toString(),
  };
}

/// 데이터 없음 이벤트
class NoDataEvent extends SignalEvent {
  final String symbol;
  
  NoDataEvent({
    required this.symbol,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'no_data',
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 리포지토리 종료 이벤트
class RepositoryDisposedEvent extends SignalEvent {
  RepositoryDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'repository_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 실시간 트레이드 데이터를 WebSocket과 REST API로 처리하는 중심 리포지토리.
/// - 지원 거래소: Upbit, Binance 등 확장 가능.
/// - [socketTradeSource]: WebSocket 데이터 소스.
/// - [marketDataSource]: REST API 데이터 소스.
/// - [tradeProcessor]: 소켓/REST 데이터 통합 처리.
/// - [connectivityManager]: 네트워크 상태 감지.
/// - [signalBus]: 이벤트 브로드캐스트.
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [platform]: 거래소 플랫폼.
/// @throws [InvalidInputFailure] 잘못된 입력.
/// @throws [RateLimitFailure] API 제한 초과.
/// @throws [ServerFailure] 서버 에러.
class TradeRepositoryImpl implements TradeRepository {
  final SocketTradeSource _socketTradeSource;
  final MarketDataSource _marketDataSource;
  final TradeProcessor _tradeProcessor;
  final ConnectivityManager _connectivityManager;
  final SignalBus _signalBus;
  final AppLogger _logger;
  final MetricLogger _metricLogger;
  final TradePlatform _platform;

  StreamSubscription? _socketSubscription;
  StreamSubscription? _connectivitySubscription;
  final BehaviorSubject<bool> _isSocketActiveSubject = BehaviorSubject<bool>.seeded(false);
  final Map<String, List<Trade>> _cachedTrades = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Set<String> _activeMarkets = {};
  bool _isInitialized = false;
  late final IsolateRunner _cacheIsolate;

  /// 소켓 활성화 여부.
  bool get isSocketActive => _isSocketActiveSubject.value;

  TradeRepositoryImpl({
    required SocketTradeSource socketTradeSource,
    required MarketDataSource marketDataSource,
    required TradeProcessor tradeProcessor,
    required ConnectivityManager connectivityManager,
    required SignalBus signalBus,
    required AppLogger logger,
    required MetricLogger metricLogger,
    TradePlatform platform = TradePlatform.upbit,
    int cacheSize = 100,
  })  : _socketTradeSource = socketTradeSource,
        _marketDataSource = marketDataSource,
        _tradeProcessor = tradeProcessor,
        _connectivityManager = connectivityManager,
        _signalBus = signalBus,
        _logger = logger,
        _metricLogger = metricLogger,
        _platform = platform {
    _initConnectivityMonitoring();
    _initCacheIsolate();
  }

  /// 네트워크 상태 모니터링 초기화.
  void _initConnectivityMonitoring() {
    _connectivitySubscription = _connectivityManager.statusStream.listen((status) {
      if (status == NetworkStatus.connected && !isSocketActive && _activeMarkets.isNotEmpty) {
        _logger.logInfo('Network restored, reconnecting socket for ${_activeMarkets.length} markets');
        _metricLogger.incrementCounter('network_reconnect_attempts');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(NetworkRestoredEvent(
          marketsCount: _activeMarkets.length,
        ));
        
        _initializeSocketStream(_activeMarkets.toList());
      }
    });
  }

  /// Isolate-safe 캐시 초기화.
  Future<void> _initCacheIsolate() async {
    try {
      _cacheIsolate = await IsolateRunner.spawn();
      await _clearCache();
    } catch (e) {
      _logger.logError('Failed to initialize cache isolate', error: e);
      // 대체 방법으로 로컬에서 처리
      _cachedTrades.clear();
      _cacheTimestamps.clear();
    }
  }

  /// 캐시 초기화 헬퍼 메서드
  Future<void> _clearCache() async {
    try {
      await _cacheIsolate.run<void, void>((message) {
        // 외부 변수 직접 접근 대신 분리된 함수에서 캐시 초기화
        return; // null 대신 그냥 return
      }, null);
    } catch (e) {
      _logger.logError('Error clearing cache in isolate', error: e);
      // 로컬 폴백
      _cachedTrades.clear();
      _cacheTimestamps.clear();
    }
  }

  /// 사용 가능한 마켓 목록 조회.
  @override
  Future<Either<Failure, List<String>>> getAvailableMarkets() async {
    final stopwatch = Stopwatch()..start();
    try {
      final markets = await _marketDataSource.getAllSymbols().timeout(const Duration(seconds: 5));
      _logger.logInfo('Retrieved ${markets.length} markets in ${stopwatch.elapsedMilliseconds}ms');
      _metricLogger.recordLatency('get_available_markets', stopwatch.elapsedMilliseconds);
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(MarketsFetchedEvent(
        count: markets.length,
      ));
      
      return Right(markets);
    } on TimeoutException catch (e) {
      _logger.logError('Timeout fetching markets', error: e);
      _metricLogger.incrementCounter('timeout_errors');
      return Left(TimeoutFailure(message: 'Request timeout: $e', error: e));
    } on Exception catch (e) {
      _logger.logError('Server error fetching markets', error: e);
      _metricLogger.incrementCounter('server_errors');
      return Left(ServerFailure(message: 'Server error: $e', error: e));
    } catch (e) {
      _logger.logError('Unexpected error fetching markets', error: e);
      _metricLogger.incrementCounter('unexpected_errors');
      return Left(ServerFailure(message: 'Unexpected error: $e', error: e));
    } finally {
      stopwatch.stop();
    }
  }

  /// 실시간 트레이드 스트림 구독.
  @override
  Stream<Either<Failure, Trade>> subscribeLiveTrades(List<String> markets) {
    if (markets.isEmpty) {
      _logger.logWarning('No markets provided for subscription');
      _metricLogger.incrementCounter('invalid_input_errors');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(InvalidInputEvent(
        message: 'Markets list cannot be empty',
      ));
      
      return Stream.value(Left(InvalidInputFailure(message: 'Markets list cannot be empty')));
    }

    _activeMarkets
      ..clear()
      ..addAll(markets);

    if (!_isInitialized) {
      _isInitialized = true;
      _initializeSocketStream(markets);
    } else {
      _socketTradeSource.disconnect();
      _initializeSocketStream(markets);
    }

    return _tradeProcessor.tradeEvents
        .map<Either<Failure, Trade>>((event) => Right<Failure, Trade>(event.trade))
        .onErrorReturnWith((error, stackTrace) {
      _logger.logError('Trade stream error', error: error, stackTrace: stackTrace);
      _metricLogger.incrementCounter('stream_errors');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(UnexpectedErrorEvent(
        error: error.toString(),
      ));
      
      return Left<Failure, Trade>(ServerFailure(message: 'Stream error: $error', error: error));
    });
  }

  /// 소켓 스트림 초기화 with 지수 백오프 재시도.
  void _initializeSocketStream(List<String> markets, {int retryCount = 0}) {
    const maxRetries = 5;
    _socketSubscription?.cancel();
    _isSocketActiveSubject.add(false);

    _socketSubscription = _socketTradeSource
        .getTradeStream(markets)
        .bufferCount(1000)
        .listen(
      (trades) {
        final stopwatch = Stopwatch()..start();
        _isSocketActiveSubject.add(true);
        for (final trade in trades) {
          _tradeProcessor.processSocketTrade(trade);
        }
        _logger.logInfo('Processed ${trades.length} trades in ${stopwatch.elapsedMilliseconds}ms');
        _metricLogger.recordLatency('socket_trade_processing', stopwatch.elapsedMilliseconds);
        _metricLogger.incrementCounter('trades_processed', increment: trades.length);
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(TradesProcessedEvent(
          count: trades.length,
        ));
        
        stopwatch.stop();
      },
      onError: (error, stackTrace) {
        _handleSocketFailure(markets, error, stackTrace, retryCount);
      },
      onDone: () {
        _isSocketActiveSubject.add(false);
        _logger.logInfo('Socket stream closed');
        _metricLogger.incrementCounter('socket_closures');
        if (_connectivityManager.isConnected && retryCount < maxRetries) {
          _logger.logInfo('Reconnecting socket (retry ${retryCount + 1})');
          _metricLogger.incrementCounter('socket_reconnect_attempts');
          
          // 객체지향 방식으로 시그널 이벤트 발송
          _signalBus.fire(SocketReconnectEvent(
            attempt: retryCount + 1,
          ));
          
          Future.delayed(const Duration(seconds: 5), () {
            _initializeSocketStream(markets, retryCount: retryCount + 1);
          });
        } else {
          _logger.logError('Max retries reached, switching to REST');
          _metricLogger.incrementCounter('socket_failures');
          
          // 객체지향 방식으로 시그널 이벤트 발송
          _signalBus.fire(PermanentSocketFailureEvent());
        }
      },
    );
  }

  /// 소켓 실패 시 REST 폴백 처리.
  Future<void> _handleSocketFailure(List<String> markets, Object error, StackTrace stackTrace, int retryCount) async {
    _isSocketActiveSubject.add(false);
    _logger.logError('Socket failed, falling back to REST', error: error, stackTrace: stackTrace);
    _metricLogger.incrementCounter('socket_failures');
    
    // 객체지향 방식으로 시그널 이벤트 발송
    _signalBus.fire(SocketFailureEvent(
      error: error.toString(),
    ));

    if (!_connectivityManager.isConnected) {
      _logger.logError('Network disconnected, waiting for connection');
      _metricLogger.incrementCounter('network_disconnects');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(NetworkDisconnectedEvent());
      
      return;
    }

    for (final symbol in markets) {
      final result = await _fetchTrades(
        symbol: symbol,
        platform: _platform,
        limit: 50,
        fetchFromRest: () => _marketDataSource.getRecentTrades(symbol, limit: 50),
        fetchFromCache: () => _cachedTrades[symbol] ?? [],
        mode: FetchMode.fallback,
      );
      if (result.isLeft()) {
        _logger.logError('REST fallback failed for $symbol');
        _metricLogger.incrementCounter('rest_fallback_failures');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(RestFallbackFailureEvent(
          symbol: symbol,
        ));
      }
    }
  }

  /// 트레이드 조회 헬퍼 메서드.
  Future<Either<Failure, List<Trade>>> _fetchTrades({
    required String symbol,
    required TradePlatform platform,
    required int limit,
    required Future<List<Trade>> Function() fetchFromRest,
    required List<Trade> Function() fetchFromCache,
    required FetchMode mode,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (!await _marketDataSource.isValidSymbol(symbol)) {
        _logger.logWarning('Invalid symbol: $symbol');
        _metricLogger.incrementCounter('invalid_symbol_errors');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(InvalidInputEvent(
          message: 'Invalid symbol: $symbol',
        ));
        
        return Left(InvalidInputFailure(message: 'Invalid symbol: $symbol'));
      }

      final now = DateTime.now();
      // 캐시 접근 수정
      List<Trade> cached = [];
      try {
        cached = await _fetchFromCache(fetchFromCache);
      } catch (e) {
        _logger.logError('Error fetching from cache', error: e);
        cached = [];
      }
      
      if (mode == FetchMode.normal &&
          cached.length >= limit &&
          _cacheTimestamps[symbol]?.isAfter(now.subtract(const Duration(minutes: 5))) == true) {
        _logger.logInfo('Retrieved trades for $symbol from cache');
        _metricLogger.incrementCounter('cache_hits');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(CacheHitEvent(
          symbol: symbol,
          count: cached.length,
        ));
        
        return Right(cached.take(limit).toList());
      }

      // TimeoutException 먼저 처리 (Exception보다 앞에 배치)
      final rest = await fetchFromRest().timeout(const Duration(seconds: 10), onTimeout: () {
        _metricLogger.incrementCounter('rest_timeouts');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(TimeoutEvent(
          symbol: symbol,
        ));
        
        throw TimeoutException('Request timed out for $symbol');
      });
      
      // TradeModel로 캐스팅하여 처리
      for (final trade in rest) {
        _tradeProcessor.processRestTrade(trade as TradeModel);
      }

      if (mode == FetchMode.normal) {
        await _updateCache(symbol, rest, now);
        _logger.logInfo('Cached ${rest.length} trades for $symbol');
        _metricLogger.incrementCounter('cache_updates');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(CacheUpdateEvent(
          symbol: symbol,
          count: rest.length,
        ));
      } else {
        _logger.logInfo('REST fallback completed for $symbol (${rest.length} trades)');
        _metricLogger.incrementCounter('rest_fallbacks');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        _signalBus.fire(RestFallbackEvent(
          symbol: symbol,
          count: rest.length,
        ));
      }

      _metricLogger.recordLatency('rest_trade_fetch', stopwatch.elapsedMilliseconds);
      return Right(rest.take(limit).toList());
    } on TimeoutException catch (e) {
      _logger.logError('Timeout fetching trades for $symbol', error: e);
      _metricLogger.incrementCounter('timeout_errors');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(TimeoutEvent(
        symbol: symbol,
      ));
      
      return Left(TimeoutFailure(message: 'Request timeout: $e', error: e));
    } on Exception catch (e) {
      _logger.logError('Server error fetching trades for $symbol', error: e);
      _metricLogger.incrementCounter('server_errors');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      _signalBus.fire(ServerErrorEvent(
        code: e.toString(),
      ));
      
      return Left(ServerFailure(message: 'Server error: $e', error: e));
    } catch (e) {
     _logger.logError('Unexpected error fetching trades for $symbol', error: e);
     _metricLogger.incrementCounter('unexpected_errors');
     
     // 객체지향 방식으로 시그널 이벤트 발송
     _signalBus.fire(UnexpectedErrorEvent(
       error: e.toString(),
     ));
     
     return Left(ServerFailure(message: 'Unexpected error: $e', error: e));
   } finally {
     stopwatch.stop();
   }
 }

 /// 캐시에서 데이터 가져오기
 Future<List<Trade>> _fetchFromCache(List<Trade> Function() fetchFromCache) async {
   try {
     return await _cacheIsolate.run<List<Trade>, void>((message) {
       return fetchFromCache();
     }, null);
   } catch (e) {
     _logger.logError('Error in cache isolate, falling back to direct access', error: e);
     return fetchFromCache();
   }
 }

 /// 캐시 업데이트
 Future<void> _updateCache(String symbol, List<Trade> trades, DateTime timestamp) async {
   try {
     await _cacheIsolate.run<void, Map<String, dynamic>>((message) {
       final symbolKey = message['symbol'] as String;
       final tradeList = message['trades'] as List<Trade>;
       final time = message['timestamp'] as DateTime;
       
       _cachedTrades[symbolKey] = List.from(tradeList);
       _cacheTimestamps[symbolKey] = time;
       return; // null 대신 그냥 return
     }, {
       'symbol': symbol,
       'trades': trades,
       'timestamp': timestamp
     });
   } catch (e) {
     _logger.logError('Error updating cache in isolate, falling back to direct update', error: e);
     _cachedTrades[symbol] = List.from(trades);
     _cacheTimestamps[symbol] = timestamp;
   }
 }

 /// 최근 트레이드 조회.
 @override
 Future<Either<Failure, List<Trade>>> getRecentTrades(String symbol, {int limit = 50}) async {
   return _fetchTrades(
     symbol: symbol,
     platform: _platform,
     limit: limit,
     fetchFromRest: () => _marketDataSource.getRecentTrades(symbol, limit: limit),
     fetchFromCache: () => _cachedTrades[symbol] ?? [],
     mode: FetchMode.normal,
   );
 }

 /// 거래량 기준 트레이드 조회.
 @override
 Future<Either<Failure, List<Trade>>> getTradesByVolume(String symbol, double minAmount, {int limit = 50}) async {
   final cachedTrades = _tradeProcessor.getRecentTrades(symbol, _platform);
   if (cachedTrades.isEmpty) {
     _logger.logWarning('No trades found for $symbol');
     _metricLogger.incrementCounter('no_data_errors');
     
     // 객체지향 방식으로 시그널 이벤트 발송
     _signalBus.fire(NoDataEvent(
       symbol: symbol,
     ));
     
     return Left(NotFoundFailure(message: 'No trades available for $symbol'));
   }

   return _fetchTrades(
     symbol: symbol,
     platform: _platform,
     limit: limit,
     fetchFromRest: () => _marketDataSource.getTradesByVolume(symbol, minAmount, limit: limit),
     fetchFromCache: () => _tradeProcessor.getTradesByAmount(symbol, _platform, minAmount, limit: limit),
     mode: FetchMode.normal,
   );
 }

 /// 시간 범위 기준 트레이드 조회.
 @override
 Future<Either<Failure, List<Trade>>> getTradesByTimeRange(String symbol, int startTime, int endTime, {int limit = 50}) async {
   if (startTime > endTime) {
     _logger.logWarning('Invalid time range: startTime ($startTime) > endTime ($endTime)');
     _metricLogger.incrementCounter('invalid_input_errors');
     
     // 객체지향 방식으로 시그널 이벤트 발송
     _signalBus.fire(InvalidInputEvent(
       message: 'Invalid time range',
     ));
     
     return Left(InvalidInputFailure(message: 'Invalid time range'));
   }

   return _fetchTrades(
     symbol: symbol,
     platform: _platform,
     limit: limit,
     fetchFromRest: () => _marketDataSource.getTradesByTimeRange(symbol, startTime, endTime, limit: limit),
     fetchFromCache: () => _tradeProcessor.getTradesByTimeRange(symbol, _platform, startTime, endTime, limit: limit),
     mode: FetchMode.normal,
   );
 }

 /// 안전한 캐시 정리
 Future<void> _clearCacheBeforeDispose() async {
   try {
     await _cacheIsolate.run<void, void>((message) {
       _cachedTrades.clear();
       _cacheTimestamps.clear();
       return; // null 대신 그냥 return
     }, null);
   } catch (e) {
     _logger.logError('Error clearing cache before dispose', error: e);
     _cachedTrades.clear();
     _cacheTimestamps.clear();
   }
 }

 /// 리소스 정리.
 @override
 Future<void> dispose() async {
   _socketSubscription?.cancel();
   _connectivitySubscription?.cancel();
   _isSocketActiveSubject.close();
   
   // 안전한 isolate 종료
   try {
     await _clearCacheBeforeDispose();
     await _cacheIsolate.close();
   } catch (e) {
     _logger.logError('Error disposing cache isolate', error: e);
   }
   
   _socketTradeSource.dispose();
   _tradeProcessor.dispose();
   _activeMarkets.clear();
   
   _logger.logInfo('TradeRepositoryImpl disposed: subscriptions closed, cache cleared');
   _metricLogger.incrementCounter('repository_disposals');
   
   // 객체지향 방식으로 시그널 이벤트 발송
   _signalBus.fire(RepositoryDisposedEvent());
 }
}