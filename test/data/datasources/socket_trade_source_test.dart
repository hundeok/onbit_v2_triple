import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';

class MockSocketTradeSource extends Mock implements SocketTradeSource {}

void main() {
  late MockSocketTradeSource mockSource;

  setUp(() {
    mockSource = MockSocketTradeSource();
  });

  test('should return trade stream', () async {
    when(mockSource.getTrades()).thenAnswer((_) => Stream.value([]));
    final result = mockSource.getTrades();
    expect(result, isA<Stream<List>>());
  });
}