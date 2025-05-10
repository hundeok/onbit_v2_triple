import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:onbit_v2_triple/core/config/app_config.dart';
import 'package:onbit_v2_triple/core/config/env_config.dart';
import 'package:onbit_v2_triple/core/error/exception.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/core/bridge/signal_bus.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class SocketService {
  final ExchangePlatform platform;
  final AppLogger logger;
  final SignalBus signalBus;
  final List<String> _markets;

  // ignore: prefer_const_constructors
  final BehaviorSubject<Map<String, dynamic>> _controller = BehaviorSubject();

  // ignore: prefer_const_constructors
  final BehaviorSubject<ConnectionState> _stateController = BehaviorSubject.seeded(ConnectionState.disconnected);

  WebSocketChannel? _channel;
  Timer? _pingTimer, _reconnectTimer, _connectionWatchdog;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _streamSubscription;

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final Duration _reconnectDelay = const Duration(seconds: 5);
  final Duration _pingInterval = const Duration(seconds: 30);
  final Duration _connectionTimeout = const Duration(seconds: 10);

  String get _wsUrl => ExchangeConfig.getConfig(platform).wsUrl;
  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<ConnectionState> get connectionStateStream => _stateController.stream;
  ConnectionState get connectionState => _stateController.value;

  SocketService({
    required this.logger,
    required this.signalBus,
    this.platform = ExchangePlatform.upbit,
    List<String> initialMarkets = const ['KRW-BTC', 'KRW-ETH'],
  }) : _markets = List.from(initialMarkets) {
    _monitorConnectivity();
    _setupStreamErrorHandler();
  }

  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        if (connectionState == ConnectionState.connected) {
          _handleError('Network lost');
        }
      } else {
        if (connectionState == ConnectionState.disconnected || connectionState == ConnectionState.error) {
          connect();
        }
      }
    });
  }

  void _setupStreamErrorHandler() {
    _streamSubscription = stream.listen((_) {}, onError: (e) {
      logger.logError('Stream error handled externally', error: e);
    });
  }

  void connect() {
    if (connectionState == ConnectionState.connected || connectionState == ConnectionState.connecting) return;

    _setState(ConnectionState.connecting);
    logger.logInfo('[SocketService] Connecting to $_wsUrl');

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

          try {
            final decoded = _decode(data);
            if (_isTrade(decoded)) {
              final trade = _process(decoded);
              _controller.add(trade);
              signalBus.fireTrade(trade);
            }
          } catch (e) {
            logger.logError('Data parsing failed', error: e);
            _controller.addError(DataParsingException(message: 'Parse error: $e'));
          }
        },
        onError: (err) => _handleError('WebSocket error: $err'),
        onDone: () => _handleError('WebSocket closed'),
      );

      _startPing();
    } catch (e) {
      _handleError('Connect fail: $e');
    }
  }

  String _subscribeMessage() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    switch (platform) {
      case ExchangePlatform.upbit:
        return jsonEncode([
          {"ticket": "onbit-v2-$ts"},
          {"type": "trade", "codes": _markets},
          {"format": "DEFAULT"}
        ]);
      case ExchangePlatform.binance:
        final params = _markets.map((m) => "${m.toLowerCase()}@trade").toList();
        return jsonEncode({"method": "SUBSCRIBE", "params": params, "id": ts});
      case ExchangePlatform.bybit:
        return jsonEncode({"op": "subscribe", "args": _markets.map((m) => "trade.$m").toList()});
      case ExchangePlatform.bithumb:
        return jsonEncode({"type": "ticker", "symbols": _markets, "tickTypes": ["30M"]});
    }
  }

  dynamic _decode(dynamic data) {
    if (data is String) {
      return jsonDecode(data);
    } else if (data is List<int>) {
      return jsonDecode(utf8.decode(data));
    } else {
      throw DataParsingException(message: 'Unknown data format: ${data.runtimeType}');
    }
  }

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

  Map<String, dynamic> _process(dynamic data) {
    switch (platform) {
      case ExchangePlatform.upbit:
        return {
          'market': data['code'],
          'price': data['trade_price'],
          'volume': data['trade_volume'],
          'timestamp': data['trade_timestamp'],
          'side': data['ask_bid'],
          'sequentialId': data['sequential_id'],
        };
      case ExchangePlatform.binance:
        return {
          'market': data['s'],
          'price': double.tryParse(data['p']) ?? 0.0,
          'volume': double.tryParse(data['q']) ?? 0.0,
          'timestamp': data['T'],
          'side': data['m'] ? 'ASK' : 'BID',
          'sequentialId': data['t'].toString(),
        };
      case ExchangePlatform.bybit:
        final d = data['data'];
        if (d == null) return {};
        return {
          'market': d['symbol'],
          'price': double.tryParse(d['price']) ?? 0.0,
          'volume': double.tryParse(d['size']) ?? 0.0,
          'timestamp': d['timestamp'],
          'side': d['side'].toUpperCase(),
          'sequentialId': d['id'].toString(),
        };
      case ExchangePlatform.bithumb:
        final content = data['content'];
        if (content == null) return {};
        return {
          'market': content['symbol'],
          'price': double.tryParse(content['closePrice']) ?? 0.0,
          'volume': double.tryParse(content['volume']) ?? 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'side': 'UNKNOWN',
          'sequentialId': DateTime.now().microsecondsSinceEpoch.toString(),
        };
    }
  }

  void _handleError(String msg, [Object? e]) {
    logger.logError(msg, error: e);
    _stopPing();
    _channel?.sink.close();
    _channel = null;
    _setState(ConnectionState.error);
    _controller.addError(SocketException(message: msg, error: e));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts++ >= _maxReconnectAttempts) {
      _setState(ConnectionState.disconnected);
      logger.logError('Max reconnect attempts reached');
      return;
    }
    _setState(ConnectionState.reconnecting);
    final delay = Duration(milliseconds: (_reconnectDelay.inMilliseconds * (1.5 * _reconnectAttempts)).toInt());
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect());
  }

  void updateMarkets(List<String> markets) {
    if (!_areSame(_markets, markets)) {
      _markets
        ..clear()
        ..addAll(markets);
      disconnect();
      connect();
    }
  }

  bool _areSame(List<String> a, List<String> b) {
    final x = List.of(a)..sort();
    final y = List.of(b)..sort();
    return x.length == y.length && x.every((e) => y.contains(e));
  }

  void _setState(ConnectionState s) {
    if (_stateController.value != s) {
      _stateController.add(s);
      logger.logInfo('Socket state: $s');
    }
  }

  void disconnect() {
    _stopPing();
    _reconnectTimer?.cancel();
    _connectionWatchdog?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(ConnectionState.disconnected);
    _reconnectAttempts = 0;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_channel != null && connectionState == ConnectionState.connected) {
        try {
          _channel!.sink.add(_pingMessage());
        } catch (e) {
          _handleError('Ping failed', e);
        }
      }
    });
  }

  String _pingMessage() {
    switch (platform) {
      case ExchangePlatform.upbit:
        return 'PING';
      case ExchangePlatform.binance:
        return jsonEncode({"method": "ping"});
      case ExchangePlatform.bybit:
        return jsonEncode({"op": "ping"});
      case ExchangePlatform.bithumb:
        return 'ping';
    }
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void dispose() {
    disconnect();
    _connectivitySubscription?.cancel();
    _streamSubscription?.cancel();
    _controller.close();
    _stateController.close();
  }
}
