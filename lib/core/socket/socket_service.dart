import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/config/env_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/monitoring/metric_logger.dart';

/// WebSocket 연결 상태.
enum ConnectionState {
  disconnected,  // 연결 끊김
  connecting,    // 연결 중
  connected,     // 연결됨
  reconnecting,  // 재연결 중
  error,         // 에러
}

/// SignalBus 이벤트 클래스들
/// 소켓 연결 이벤트
class SocketConnectedEvent extends SignalEvent {
  SocketConnectedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_connected',
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 연결 해제 이벤트
class SocketDisconnectedEvent extends SignalEvent {
  SocketDisconnectedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_disconnected',
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 실패 이벤트
class SocketFailedEvent extends SignalEvent {
  SocketFailedEvent() 
      : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_failed',
    'sequentialId': sequentialId.toString(),
  };
}

/// 소켓 서비스 종료 이벤트
class SocketServiceDisposedEvent extends SignalEvent {
  SocketServiceDisposedEvent() 
      : super(SignalEventType.alert, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_service_disposed',
    'sequentialId': sequentialId.toString(),
  };
}

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

/// 소켓 에러 이벤트
class SocketErrorEvent extends SignalEvent {
  final String message;
  final Object? error;
  
  SocketErrorEvent({
    required this.message,
    this.error,
  }) : super(SignalEventType.error, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_error',
    'message': message,
    'error': error?.toString(),
    'sequentialId': sequentialId.toString(),
  };
}

/// 거래 이벤트
class SocketTradeEvent extends SignalEvent {
  final Map<String, dynamic> trade;
  
  SocketTradeEvent(this.trade) 
      : super(SignalEventType.trade, DateTime.now().millisecondsSinceEpoch);
  
  @override
  Map<String, dynamic> toMap() => {
    'type': 'socket_trade',
    ...trade,
    'sequentialId': sequentialId.toString(),
  };
}

/// WebSocket 연결 및 거래 데이터 스트림 제공.
/// - [platform]: 거래소 플랫폼 (Upbit, Binance 등).
/// - [logger]: 로깅.
/// - [metricLogger]: 성능 메트릭.
/// - [signalBus]: 이벤트 브로드캐스트.
/// - [initialMarkets]: 초기 구독 마켓 심볼.
/// @throws [SocketException] WebSocket 연결/데이터 처리 에러.
class SocketService {
  final ExchangePlatform platform;
  final AppLogger logger;
  final MetricLogger metricLogger;
  final SignalBus signalBus;
  final Set<String> _markets;

  final BehaviorSubject<Map<String, dynamic>> _controller;
  final BehaviorSubject<ConnectionState> _stateController;
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _connectionWatchdog;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _streamSubscription;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectBaseDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);

  String get _wsUrl => ExchangeConfig.getConfig(platform).wsUrl;

  /// 거래 데이터 스트림.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// 연결 상태 스트림.
  Stream<ConnectionState> get connectionStateStream => _stateController.stream;

  /// 현재 연결 상태.
  ConnectionState get connectionState => _stateController.value;

  SocketService({
    required this.platform,
    required this.logger,
    required this.metricLogger,
    required this.signalBus,
    List<String> initialMarkets = const ['KRW-BTC', 'KRW-ETH'],
  }) : _markets = initialMarkets.toSet(),
       _controller = BehaviorSubject<Map<String, dynamic>>(),
       _stateController = BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected) {
    _monitorConnectivity();
    _setupStreamErrorHandler();
  }

  /// 네트워크 상태 모니터링.
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      logger.logInfo('Network state changed: $result');
      metricLogger.incrementCounter('network_state_changes', labels: {'platform': platform.toString(), 'connected': isConnected.toString()});

      if (!isConnected && connectionState == ConnectionState.connected) {
        _handleError('Network lost');
        
        // 객체지향 방식으로 시그널 이벤트 발송
        signalBus.fire(SocketErrorEvent(
          message: 'Network disconnected',
        ));
      } else if (isConnected && (connectionState == ConnectionState.disconnected || connectionState == ConnectionState.error)) {
        connect();
      }
    });
  }

  /// 스트림 에러 핸들러 설정.
  void _setupStreamErrorHandler() {
    _streamSubscription = stream.listen(
      (_) {},
      onError: (e, stackTrace) {
        logger.logError('Stream error handled externally', error: e, stackTrace: stackTrace);
        metricLogger.incrementCounter('stream_errors', labels: {'platform': platform.toString()});
      },
    );
  }

  /// WebSocket 연결.
  void connect() {
    if (connectionState == ConnectionState.connected || connectionState == ConnectionState.connecting) {
      logger.logInfo('Already connected or connecting, ignoring connect request');
      return;
    }

    _setState(ConnectionState.connecting);
    logger.logInfo('Connecting to WebSocket: $_wsUrl');
    metricLogger.incrementCounter('socket_connect_attempts', labels: {'platform': platform.toString()});

    _connectionWatchdog?.cancel();
    _connectionWatchdog = Timer(_connectionTimeout, () {
      if (connectionState == ConnectionState.connecting) {
        _handleError('Connection timeout');
      }
    });

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.add(_subscribeMessage());

      _channel!.stream.listen(
        (data) {
          _connectionWatchdog?.cancel();
          _setState(ConnectionState.connected);
          _reconnectAttempts = 0;
          
          // 객체지향 방식으로 시그널 이벤트 발송
          signalBus.fire(SocketConnectedEvent());
          
          metricLogger.incrementCounter('socket_connections', labels: {'platform': platform.toString()});

          try {
            final decoded = _decode(data);
            if (_isTrade(decoded)) {
              final trade = _process(decoded);
              _controller.add(trade);
              
              // 객체지향 방식으로 시그널 이벤트 발송
              signalBus.fire(SocketTradeEvent(trade));
              
              metricLogger.incrementCounter('trades_received', labels: {'platform': platform.toString()});
            }
          } catch (e, stackTrace) {
            logger.logError('Data parsing failed', error: e, stackTrace: stackTrace);
            _controller.addError(DataParsingException(message: 'Parse error: $e'), stackTrace);
            metricLogger.incrementCounter('parse_errors', labels: {'platform': platform.toString()});
          }
        },
        onError: (error, stackTrace) {
          _handleError('WebSocket error: $error', error, stackTrace);
        },
        onDone: () {
          _handleError('WebSocket closed');
        },
      );

      _startPing();
    } catch (e, stackTrace) {
      _handleError('Connect failed: $e', e, stackTrace);
    }
  }

  /// 구독 메시지 생성.
  String _subscribeMessage() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    switch (platform) {
      case ExchangePlatform.upbit:
        return jsonEncode([
          {'ticket': 'onbit-v3-$ts'},
          {'type': 'trade', 'codes': _markets.toList()},
          {'format': 'DEFAULT'},
        ]);
      case ExchangePlatform.binance:
        final params = _markets.map((m) => '${m.toLowerCase()}@trade').toList();
        return jsonEncode({'method': 'SUBSCRIBE', 'params': params, 'id': ts});
      case ExchangePlatform.bybit:
        return jsonEncode({'op': 'subscribe', 'args': _markets.map((m) => 'trade.$m').toList()});
      case ExchangePlatform.bithumb:
        return jsonEncode({'type': 'ticker', 'symbols': _markets.toList(), 'tickTypes': ['30M']});
    }
  }

  /// WebSocket 데이터 디코딩.
  /// - [data]: 수신 데이터.
  /// @returns 디코딩된 JSON.
  dynamic _decode(dynamic data) {
    try {
      if (data is String) {
        return jsonDecode(data);
      } else if (data is List<int>) {
        return jsonDecode(utf8.decode(data));
      }
      throw DataParsingException(message: 'Unknown data format: ${data.runtimeType}');
    } catch (e) {
      throw DataParsingException(message: 'Decode error: $e');
    }
  }

  /// 거래 데이터 여부 확인.
  /// - [msg]: 디코딩된 메시지.
  bool _isTrade(dynamic msg) {
    switch (platform) {
      case ExchangePlatform.upbit:
        return msg['ty'] == 'trade';
      case ExchangePlatform.binance:
        return msg['e'] == 'trade';
      case ExchangePlatform.bybit:
        return msg['topic']?.toString().startsWith('trade.') ?? false;
      case ExchangePlatform.bithumb:
        return msg['type'] == 'ticker';
    }
  }

  /// 거래 데이터 처리.
  /// - [data]: 디코딩된 메시지.
  /// @returns 거래 데이터 맵.
  Map<String, dynamic> _process(dynamic data) {
    switch (platform) {
      case ExchangePlatform.upbit:
        return {
          'market': data['code'] as String? ?? 'unknown',
          'price': (data['trade_price'] as num?)?.toDouble() ?? 0.0,
          'volume': (data['trade_volume'] as num?)?.toDouble() ?? 0.0,
          'timestamp': data['trade_timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          'side': data['ask_bid'] as String? ?? 'UNKNOWN',
          'sequentialId': data['sequential_id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        };
      case ExchangePlatform.binance:
        return {
          'market': data['s'] as String? ?? 'unknown',
          'price': double.tryParse(data['p']?.toString() ?? '0') ?? 0.0,
          'volume': double.tryParse(data['q']?.toString() ?? '0') ?? 0.0,
          'timestamp': data['T'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          'side': (data['m'] as bool?) == true ? 'ASK' : 'BID',
          'sequentialId': data['t']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        };
      case ExchangePlatform.bybit:
        final d = data['data'] as Map<String, dynamic>? ?? {};
        return {
          'market': d['symbol'] as String? ?? 'unknown',
          'price': double.tryParse(d['price']?.toString() ?? '0') ?? 0.0,
          'volume': double.tryParse(d['size']?.toString() ?? '0') ?? 0.0,
          'timestamp': d['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          'side': d['side']?.toString().toUpperCase() ?? 'UNKNOWN',
          'sequentialId': d['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        };
      case ExchangePlatform.bithumb:
        final content = data['content'] as Map<String, dynamic>? ?? {};
        return {
          'market': content['symbol'] as String? ?? 'unknown',
          'price': double.tryParse(content['closePrice']?.toString() ?? '0') ?? 0.0,
          'volume': double.tryParse(content['volume']?.toString() ?? '0') ?? 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'side': 'UNKNOWN',
          'sequentialId': DateTime.now().microsecondsSinceEpoch.toString(),
        };
    }
  }

  /// 에러 처리.
  /// - [msg]: 에러 메시지.
  /// - [error]: 에러 객체.
  /// - [stackTrace]: 스택 트레이스.
  void _handleError(String msg, [Object? error, StackTrace? stackTrace]) {
    logger.logError(msg, error: error, stackTrace: stackTrace);
    _stopPing();
    _channel?.sink.close();
    _channel = null;
    _setState(ConnectionState.error);
    _controller.addError(SocketException(message: msg, error: error), stackTrace);
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(SocketErrorEvent(
      message: msg,
      error: error,
    ));
    
    metricLogger.incrementCounter('socket_errors', labels: {'platform': platform.toString()});
    _scheduleReconnect();
  }

  /// 재연결 스케줄링.
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setState(ConnectionState.disconnected);
      logger.logError('Max reconnect attempts reached');
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(SocketFailedEvent());
      
      metricLogger.incrementCounter('socket_failed', labels: {'platform': platform.toString()});
      return;
    }
    _reconnectAttempts++;
    _setState(ConnectionState.reconnecting);
    final delay = Duration(milliseconds: (_reconnectBaseDelay.inMilliseconds * pow(1.5, _reconnectAttempts)).toInt());
    logger.logInfo('Scheduling reconnect attempt $_reconnectAttempts after ${delay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
      metricLogger.incrementCounter('socket_reconnect_attempts', labels: {'platform': platform.toString()});
    });
  }

  /// 마켓 리스트 업데이트.
  /// - [markets]: 새 마켓 심볼 리스트.
  void updateMarkets(List<String> markets) {
    final newMarkets = markets.toSet();
    if (!_areSame(_markets, newMarkets)) {
      logger.logInfo('Updating markets: ${newMarkets.length} markets');
      _markets
        ..clear()
        ..addAll(newMarkets);
      disconnect();
      connect();
      metricLogger.incrementCounter('market_updates', labels: {'platform': platform.toString()});
      
      // 객체지향 방식으로 시그널 이벤트 발송
      signalBus.fire(MarketsUpdatedEvent(newMarkets.length));
    }
  }

  /// 마켓 리스트 비교.
  bool _areSame(Set<String> a, Set<String> b) {
    return a.length == b.length && a.every((e) => b.contains(e));
  }

  /// 연결 상태 설정.
  void _setState(ConnectionState state) {
    if (_stateController.value != state) {
      _stateController.add(state);
      logger.logInfo('Socket state changed: $state');
      metricLogger.incrementCounter('state_changes', labels: {'platform': platform.toString(), 'state': state.name});
    }
  }

  /// WebSocket 연결 해제.
  void disconnect() {
    _stopPing();
    _reconnectTimer?.cancel();
    _connectionWatchdog?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(ConnectionState.disconnected);
    _reconnectAttempts = 0;
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(SocketDisconnectedEvent());
    
    metricLogger.incrementCounter('socket_disconnects', labels: {'platform': platform.toString()});
  }

  /// 주기적 핑 전송.
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_channel != null && connectionState == ConnectionState.connected) {
        try {
          _channel!.sink.add(_pingMessage());
          metricLogger.incrementCounter('socket_pings', labels: {'platform': platform.toString()});
        } catch (e, stackTrace) {
          _handleError('Ping failed', e, stackTrace);
        }
      }
    });
  }

  /// 핑 메시지 생성.
  String _pingMessage() {
    switch (platform) {
      case ExchangePlatform.upbit:
        return 'PING';
      case ExchangePlatform.binance:
        return jsonEncode({'method': 'ping'});
      case ExchangePlatform.bybit:
        return jsonEncode({'op': 'ping'});
      case ExchangePlatform.bithumb:
        return 'ping';
    }
  }

  /// 핑 중지.
  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// 리소스 정리.
  void dispose() {
    disconnect();
    _connectivitySubscription?.cancel();
    _streamSubscription?.cancel();
    _controller.close();
    _stateController.close();
    logger.logInfo('SocketService disposed: all resources cleared');
    metricLogger.incrementCounter('socket_service_disposals', labels: {'platform': platform.toString()});
    
    // 객체지향 방식으로 시그널 이벤트 발송
    signalBus.fire(SocketServiceDisposedEvent());
  }
}