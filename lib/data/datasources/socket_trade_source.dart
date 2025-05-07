import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';

class SocketTradeSource {
  final _controller = StreamController<Trade>.broadcast();
  WebSocketChannel? _channel;
  final String _wsUrl = 'wss://api.upbit.com/websocket/v1';
  final List<String> _markets = ['KRW-BTC', 'KRW-ETH'];

  Stream<Trade> get tradeStream => _controller.stream;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      final subscription = [
        {"ticket": "onbit-v2-triple"},
        {"type": "trade", "codes": _markets},
        {"format": "DEFAULT"}
      ];
      _channel!.sink.add(jsonEncode(subscription));

      _channel!.stream.listen(
        (data) {
          final tradeData = jsonDecode(utf8.decode(data));
          final trade = Trade(
            symbol: tradeData['code'] as String,
            price: tradeData['trade_price'].toDouble(),
            volume: tradeData['trade_volume']?.toDouble() ?? 0.0,
            timestamp: DateTime.parse(tradeData['trade_time']).millisecondsSinceEpoch,
            isBuy: tradeData['ask_bid'] == 'BID',
            sequentialId: tradeData['sequential_id']?.toString() ?? '',
          );
          _controller.sink.add(trade);
          AppLogger().logInfo('Trade received: ${trade.symbol}, ${trade.price}');
        },
        onError: (error) {
          AppLogger().logError('WebSocket error', error: error);
          reconnect();
        },
        onDone: () {
          AppLogger().logInfo('WebSocket closed');
          reconnect();
        },
      );
    } catch (e) {
      AppLogger().logError('WebSocket connection failed', error: e);
      reconnect();
    }
  }

  void reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_channel == null || _channel!.closeCode != null) connect();
    });
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}