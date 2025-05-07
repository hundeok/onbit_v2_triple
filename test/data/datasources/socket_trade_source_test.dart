import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'socket_trade_source_test.mocks.dart';

@GenerateMocks([WebSocketChannel, WebSocketSink])
void main() {
  late SocketTradeSource socketTradeSource;
  late MockWebSocketChannel mockChannel;
  late MockWebSocketSink mockSink;

  setUp(() {
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();
    when(mockChannel.sink).thenReturn(mockSink);
    socketTradeSource = SocketTradeSource();
  });

  test('should emit trade data from WebSocket stream', () async {
    final tradeData = {
      'code': 'KRW-BTC',
      'trade_price': 50000.0,
      'trade_time': '2025-05-07T12:00:00',
    };
    when(mockChannel.stream).thenAnswer((_) => Stream.value(utf8.encode(jsonEncode(tradeData))));

    socketTradeSource.connect();

    final trade = await socketTradeSource.tradeStream.first;
    expect(trade.symbol, 'KRW-BTC');
    expect(trade.price, 50000.0);
  });

  tearDown(() {
    socketTradeSource.dispose();
  });
}