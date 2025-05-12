import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart' as domain;

/// 거래소 플랫폼.
enum TradePlatform { upbit, binance }

/// API 서비스 관련 이벤트 클래스들 (객체지향 방식)
/// 심볼 목록 조회 이벤트
class SymbolsFetchedEvent extends SignalEvent {
  final int count;
  
  SymbolsFetchedEvent({required this.count})
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'count': count,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 데이터 수신 이벤트
class TradeReceivedEvent extends SignalEvent {
  final int count;
  final String symbol;
  
  TradeReceivedEvent({required this.count, required this.symbol})
      : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'count': count,
    'symbol': symbol,
    'sequentialId': sequentialId.toString(),
  };
}

/// 대량 거래 감지 이벤트
class SignificantTradeEvent extends SignalEvent {
  final String symbol;
  final double price;
  final double volume;
  final double amount;
  
  SignificantTradeEvent({
    required this.symbol,
    required this.price,
    required this.volume,
    required this.amount,
  }) : super(SignalEventType.significantTrade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'price': price,
    'volume': volume,
    'amount': amount,
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 필터링 이벤트
class TradeFilteredEvent extends SignalEvent {
  final int count;
  final String symbol;
  final String filterType;
  
  TradeFilteredEvent({required this.count, required this.symbol, required this.filterType})
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'count': count,
    'symbol': symbol,
    'filterType': filterType,
    'sequentialId': sequentialId.toString(),
  };
}

/// API 오류 이벤트
class ApiErrorEvent extends SignalEvent {
  final String code;
  final String? error;
  
  ApiErrorEvent({required this.code, this.error})
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'code': code,
    'error': error,
    'sequentialId': sequentialId.toString(),
  };
}

/// WebSocket 연결 종료 이벤트
class WebSocketClosedEvent extends SignalEvent {
  WebSocketClosedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'message': 'WebSocket closed',
    'sequentialId': sequentialId.toString(),
  };
}

/// WebSocket 연결 실패 이벤트
class WebSocketFailedEvent extends SignalEvent {
  final String markets;
  
  WebSocketFailedEvent({required this.markets})
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'markets': markets,
    'message': 'WebSocket failed to connect',
    'sequentialId': sequentialId.toString(),
  };
}

/// API 서비스 종료 이벤트
class ApiDisposedEvent extends SignalEvent {
  ApiDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'message': 'ApiService disposed',
    'sequentialId': sequentialId.toString(),
  };
}

/// Upbit/Binance API의 WebSocket 및 REST 데이터를 처리.
class ApiService {
  final TradePlatform _platform;
  final AppLogger _logger;
  final MetricLogger _metricLogger;
  final SignalBus _signalBus;
  final String _baseWsUrl;
  final String _baseRestUrl;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  final BehaviorSubject<List<domain.Trade>> _tradeStream = BehaviorSubject<List<domain.Trade>>();

  ApiService({
    required TradePlatform platform,
    required AppLogger logger,
    required MetricLogger metricLogger,
    required SignalBus signalBus,
  })  : _platform = platform,
        _logger = logger,
        _metricLogger = metricLogger,
        _signalBus = signalBus,
        _baseWsUrl = _getWsBaseUrl(platform),
        _baseRestUrl = _getRestBaseUrl(platform);

  /// WebSocket 기본 URL 반환.
  static String _getWsBaseUrl(TradePlatform platform) {
    switch (platform) {
      case TradePlatform.upbit:
        return 'wss://api.upbit.com/websocket/v1';
      case TradePlatform.binance:
        return 'wss://stream.binance.com:9443/ws';
    }
  }

  /// REST API 기본 URL 반환.
  static String _getRestBaseUrl(TradePlatform platform) {
    switch (platform) {
      case TradePlatform.upbit:
        return 'https://api.upbit.com/v1';
      case TradePlatform.binance:
        return 'https://api.binance.com/api/v3';
    }
  }

  /// TradePlatform enum을 도메인 TradePlatform enum으로 변환
  domain.TradePlatform _convertToDomainPlatform(TradePlatform platform) {
    switch (platform) {
      case TradePlatform.upbit:
        return domain.TradePlatform.upbit;
      case TradePlatform.binance:
        return domain.TradePlatform.binance;
    }
  }

  /// 사용 가능한 마켓 심볼 목록 조회.
  Future<List<String>> getAllSymbols() async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$_baseRestUrl${_platform == TradePlatform.upbit ? '/market/all' : '/exchangeInfo'}');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw ServerException(code: 'api_error', message: 'Failed to fetch symbols: ${response.statusCode}');
      }
      final json = jsonDecode(response.body);
      final symbols = _platform == TradePlatform.upbit
          ? (json as List).map((e) => e['market'] as String).toList()
          : (json['symbols'] as List).map((e) => e['symbol'] as String).toList();
      _logger.logInfo('Retrieved ${symbols.length} symbols in ${stopwatch.elapsedMilliseconds}ms');
      _metricLogger.recordLatency('get_all_symbols', stopwatch.elapsedMilliseconds, labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(SymbolsFetchedEvent(count: symbols.length));
      
      return symbols;
    } catch (e) {
      _logger.logError('Failed to fetch symbols', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'api_error', error: e.toString()));
      
      throw ServerException(code: 'api_error', message: e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  /// 심볼 유효성 검증.
  Future<bool> isValidSymbol(String symbol) async {
    try {
      final symbols = await getAllSymbols();
      final isValid = symbols.contains(symbol);
      _logger.logInfo('Validated symbol $symbol: $isValid');
      _metricLogger.incrementCounter('symbol_validations', labels: {'platform': _platform.toString(), 'valid': isValid.toString()});
      return isValid;
    } catch (e) {
      _logger.logError('Error validating symbol $symbol', error: e);
      _metricLogger.incrementCounter('symbol_validation_errors', labels: {'platform': _platform.toString()});
      return false;
    }
  }

  /// 실시간 트레이드 스트림 제공.
  Stream<List<domain.Trade>> getTradeStream(List<String> markets) {
    if (markets.isEmpty) {
      _logger.logWarning('No markets provided for WebSocket');
      _metricLogger.incrementCounter('invalid_input_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'empty_markets'));
      
      return Stream.error(InvalidInputException(message: 'Markets list cannot be empty'));
    }

    _connectWebSocket(markets);
    return _tradeStream.asBroadcastStream();
  }

  /// WebSocket 연결 및 데이터 처리.
  void _connectWebSocket(List<String> markets, {int retryCount = 0}) {
    const maxRetries = 3;
    _wsSubscription?.cancel();
    if (_wsChannel != null) {
      _wsChannel!.sink.close();
      _wsChannel = null;
    }
    _tradeStream.add([]);

    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_baseWsUrl));
      _wsChannel!.sink.add(jsonEncode([
        {'ticket': 'trade_stream_${_platform.toString()}'},
        {'type': 'trade', 'codes': markets}
      ]));

      _wsSubscription = _wsChannel!.stream.listen(
        (data) {
          final stopwatch = Stopwatch()..start();
          final trades = _parseWebSocketData(data);
          if (trades.isNotEmpty) {
            _tradeStream.add(trades);
            _logger.logInfo('Received ${trades.length} trades for ${markets.length} markets');
            _metricLogger.recordLatency('websocket_trade_processing', stopwatch.elapsedMilliseconds, labels: {'platform': _platform.toString()});
            _metricLogger.incrementCounter('websocket_trades_received', increment: trades.length, labels: {'platform': _platform.toString()});
            
            // 객체지향 방식으로 이벤트 발행
            _signalBus.fire(TradeReceivedEvent(count: trades.length, symbol: markets.join(',')));
            
            // 대량 거래 감지
            for (final trade in trades) {
              final amount = trade.price * trade.volume;
              if (amount > AppConfig.momentaryThreshold) {
                _signalBus.fire(SignificantTradeEvent(
                  symbol: trade.symbol,
                  price: trade.price,
                  volume: trade.volume,
                  amount: amount,
                ));
              }
            }
          }
          stopwatch.stop();
        },
        onError: (error, stackTrace) {
          _logger.logError('WebSocket error', error: error, stackTrace: stackTrace);
          _metricLogger.incrementCounter('websocket_errors', labels: {'platform': _platform.toString()});
          
          // 객체지향 방식으로 이벤트 발행
          _signalBus.fire(ApiErrorEvent(code: 'websocket_error', error: error.toString()));
          
          _tradeStream.addError(error, stackTrace);
          if (retryCount < maxRetries) {
            final delay = Duration(seconds: pow(2, retryCount).toInt());
            _logger.logInfo('Retrying WebSocket connection (attempt ${retryCount + 1}) after ${delay.inSeconds}s');
            Future.delayed(delay, () {
              _connectWebSocket(markets, retryCount: retryCount + 1);
            });
          } else {
            // 객체지향 방식으로 이벤트 발행
            _signalBus.fire(WebSocketFailedEvent(markets: markets.join(',')));
            
            Future.delayed(const Duration(seconds: 30), () {
              _connectWebSocket(markets, retryCount: 0);
            });
          }
        },
        onDone: () {
          _logger.logInfo('WebSocket closed');
          _metricLogger.incrementCounter('websocket_closures', labels: {'platform': _platform.toString()});
          
          // 객체지향 방식으로 이벤트 발행
          _signalBus.fire(WebSocketClosedEvent());
          
          _tradeStream.add([]);
          Future.delayed(const Duration(seconds: 30), () {
            _connectWebSocket(markets, retryCount: 0);
          });
        },
      );
    } catch (e) {
      _logger.logError('Failed to connect WebSocket', error: e);
      _metricLogger.incrementCounter('websocket_connect_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'websocket_connect_error', error: e.toString()));
      
      _tradeStream.addError(e);
      if (retryCount < maxRetries) {
        final delay = Duration(seconds: pow(2, retryCount).toInt());
        _logger.logInfo('Retrying WebSocket connection (attempt ${retryCount + 1}) after ${delay.inSeconds}s');
        Future.delayed(delay, () {
          _connectWebSocket(markets, retryCount: retryCount + 1);
        });
      } else {
        // 객체지향 방식으로 이벤트 발행
        _signalBus.fire(WebSocketFailedEvent(markets: markets.join(',')));
        
        Future.delayed(const Duration(seconds: 30), () {
          _connectWebSocket(markets, retryCount: 0);
        });
      }
    }
  }

  /// WebSocket 데이터 파싱.
  List<domain.Trade> _parseWebSocketData(dynamic data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final symbol = json['code'] as String? ?? 'unknown';
      if (symbol == 'unknown') {
        throw InvalidInputException(message: 'Invalid symbol in WebSocket data');
      }
      final price = (json['trade_price'] as num?)?.toDouble() ?? 0.0;
      final volume = (json['trade_volume'] as num?)?.toDouble() ?? 0.0;
      final timestamp = json['trade_timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final parts = symbol.split('-');
      final base = parts.isNotEmpty ? parts[0] : 'KRW';
      final target = parts.length > 1 ? parts[1] : symbol;
      final isBuy = json['ask_bid']?.toString().toLowerCase() == 'bid';

      // 도메인 플랫폼으로 변환 - 메서드 사용
      final domainPlatform = _convertToDomainPlatform(_platform);

      final trade = domain.Trade(
        symbol: symbol,
        price: price,
        volume: volume,
        timestamp: timestamp,
        platform: domainPlatform,
        baseCurrency: base,
        targetCurrency: target,
        isBuy: isBuy,
        sequentialId: '$timestamp' + '_' + symbol,
      );
      _logger.logDebug('Parsed trade: $symbol, price: $price, volume: $volume, timestamp: $timestamp');
      return [trade];
    } catch (e) {
      _logger.logError('Failed to parse WebSocket data: $data', error: e);
      _metricLogger.incrementCounter('websocket_parse_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'websocket_parse_error', error: e.toString()));
      
      throw InvalidInputException(message: 'Failed to parse WebSocket data');
    }
  }

  /// 최근 거래 내역 조회.
  Future<List<domain.Trade>> getRecentTrades(String symbol, {int limit = 50}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$_baseRestUrl${_platform == TradePlatform.upbit ? '/trades/ticks?market=$symbol&count=$limit' : '/trades?symbol=$symbol&limit=$limit'}');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw ServerException(code: 'api_error', message: 'Failed to fetch trades: ${response.statusCode}');
      }
      final rawTrades = jsonDecode(response.body) as List;
      final trades = rawTrades.map((e) {
        final marketSymbol = e['market'] as String? ?? symbol;
        final parts = marketSymbol.split('-');
        final base = parts.isNotEmpty ? parts[0] : 'KRW';
        final target = parts.length > 1 ? parts[1] : marketSymbol;
        final isBuy = e['ask_bid']?.toString().toLowerCase() == 'bid';

        // 도메인 플랫폼으로 변환 - 메서드 사용
        final domainPlatform = _convertToDomainPlatform(_platform);

        return domain.Trade(
          symbol: marketSymbol,
          price: (e['trade_price'] as num?)?.toDouble() ?? 0.0,
          volume: (e['trade_volume'] as num?)?.toDouble() ?? 0.0,
          timestamp: e['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          platform: domainPlatform,
          baseCurrency: base,
          targetCurrency: target,
          isBuy: isBuy,
          sequentialId: e['sequential_id']?.toString() ?? (marketSymbol + '_' + DateTime.now().millisecondsSinceEpoch.toString()),
        );
      }).toList();
      _logger.logInfo('Retrieved ${trades.length} recent trades for $symbol in ${stopwatch.elapsedMilliseconds}ms');
      _metricLogger.recordLatency('get_recent_trades', stopwatch.elapsedMilliseconds, labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(TradeReceivedEvent(count: trades.length, symbol: symbol));
      
      return trades;
    } catch (e) {
      _logger.logError('Failed to fetch recent trades for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'api_error', error: e.toString()));
      
      throw ServerException(code: 'api_error', message: e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  /// 거래량 기준 트레이드 조회.
  Future<List<domain.Trade>> getTradesByVolume(String symbol, double minAmount, {int limit = 50}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final trades = await getRecentTrades(symbol, limit: limit * 2);
      final filtered = trades
          .where((trade) => trade.volume >= minAmount)
          .take(limit)
          .toList();
      _logger.logInfo('Filtered ${filtered.length} trades by volume for $symbol in ${stopwatch.elapsedMilliseconds}ms');
      _metricLogger.incrementCounter('trades_filtered_by_volume', increment: filtered.length, labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(TradeFilteredEvent(
        count: filtered.length,
        symbol: symbol,
        filterType: 'volume',
      ));
      
      return filtered;
    } catch (e) {
      _logger.logError('Failed to fetch volume trades for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'api_error', error: e.toString()));
      
      throw ServerException(code: 'api_error', message: e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  /// 시간 범위 기준 트레이드 조회.
  Future<List<domain.Trade>> getTradesByTimeRange(String symbol, int startTime, int endTime, {int limit = 50}) async {
    if (startTime > endTime) {
      _logger.logWarning('Invalid time range: startTime ($startTime) > endTime ($endTime)');
      _metricLogger.incrementCounter('invalid_input_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'invalid_time_range'));
      
      throw InvalidInputException(message: 'Invalid time range');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final trades = await getRecentTrades(symbol, limit: limit * 2);
      final filtered = trades
          .where((trade) => trade.timestamp >= startTime && trade.timestamp <= endTime)
          .take(limit)
          .toList();
      _logger.logInfo('Filtered ${filtered.length} trades by time range for $symbol in ${stopwatch.elapsedMilliseconds}ms');
      _metricLogger.incrementCounter('trades_filtered_by_time', increment: filtered.length, labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(TradeFilteredEvent(
        count: filtered.length,
        symbol: symbol,
        filterType: 'time_range',
      ));
      
      return filtered;
    } catch (e) {
      _logger.logError('Failed to fetch time range trades for $symbol', error: e);
      _metricLogger.incrementCounter('api_errors', labels: {'platform': _platform.toString()});
      
      // 객체지향 방식으로 이벤트 발행
      _signalBus.fire(ApiErrorEvent(code: 'api_error', error: e.toString()));
      
      throw ServerException(code: 'api_error', message: e.toString());
    } finally {
      stopwatch.stop();
    }
  }

  /// 리소스 정리.
  void dispose() {
    _wsSubscription?.cancel();
    if (_wsChannel != null) {
      _wsChannel!.sink.close();
      _wsChannel = null;
    }
    _tradeStream.close();
    _signalBus.clearListeners(); // 호환성을 위해 유지
    _logger.logInfo('ApiService disposed: WebSocket connections closed');
    _metricLogger.incrementCounter('api_service_disposals', labels: {'platform': _platform.toString()});
    
    // 객체지향 방식으로 이벤트 발행
    _signalBus.fire(ApiDisposedEvent());
  }
}

/// 예외 클래스
class ServerException implements Exception {
  final String code;
  final String message;
  ServerException({required this.code, required this.message});
  
  @override
  String toString() => 'ServerException: [$code] $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
  
  @override
  String toString() => 'NetworkException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException({required this.message});
  
  @override
  String toString() => 'RateLimitException: $message';
}

class InvalidInputException implements Exception {
  final String message;
  InvalidInputException({required this.message});
  
  @override
  String toString() => 'InvalidInputException: $message';
}