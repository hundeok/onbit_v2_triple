import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onbit_v2_triple/core/error/failure.dart';
import 'package:onbit_v2_triple/core/logger/app_logger.dart';
import 'package:onbit_v2_triple/data/datasources/socket_trade_source.dart';
import 'package:onbit_v2_triple/data/repositories/trade_repository_impl.dart';
import 'package:onbit_v2_triple/domain/entities/trade.dart';
import 'trade_repository_test.mocks.dart';

@GenerateMocks([SocketTradeSource, AppLogger])
void main() {
  late TradeRepositoryImpl repository;
  late MockSocketTradeSource mockSocketTradeSource;
  late MockAppLogger mockLogger;

  setUp(() {
    mockSocketTradeSource = MockSocketTradeSource();
    mockLogger = MockAppLogger();
    repository = TradeRepositoryImpl(
      socketTradeSource: mockSocketTradeSource,
      logger: mockLogger,
    );
  });

  const tSymbol = 'KRW-BTC';
  final tTrades = [
    const Trade( // const 추가
      symbol: tSymbol,
      price: 50000.0,
      volume: 1.0,
      timestamp: 123456,
      isBuy: true,
      sequentialId: '1',
    ),
  ];

  test('should return filtered trades from socket source', () async {
    // Arrange
    when(mockSocketTradeSource.tradeStream).thenAnswer((_) => Stream.fromIterable(tTrades));
    // Act
    final result = await repository.getFilteredTrades(
      symbol: tSymbol,
      minPrice: 40000.0,
      maxPrice: 60000.0,
      minVolume: 0.5,
    );
    // Assert
    expect(result, Right(tTrades));
    verify(mockLogger.logInfo('Filtered ${tTrades.length} trades for $tSymbol'));
    verifyNoMoreInteractions(mockLogger);
  });

  test('should return failure on error', () async {
    // Arrange
    final tError = Exception('Stream error');
    when(mockSocketTradeSource.tradeStream).thenAnswer((_) => Stream.error(tError));
    // Act
    final result = await repository.getFilteredTrades(symbol: tSymbol);
    // Assert
    expect(result, isA<Left<Failure, List<Trade>>>());
    expect(result, Left(ServerFailure(message: 'Failed to fetch trades: $tError')));
    verify(mockLogger.logError('Failed to fetch filtered trades', error: tError, stackTrace: anyNamed('stackTrace')));
    verifyNoMoreInteractions(mockLogger);
  });
}